import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';
import '../datasources/post_local_datasource.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final PostLocalDataSource localDataSource;

  PostRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Post _modelToEntity(PostModel model) {
    return Post(
      id: model.id,
      userId: model.userId,
      title: model.title,
      body: model.body,
    );
  }

  @override
  Future<List<Post>> getPosts() async {
    try {
      final localPosts = localDataSource.getCachedPosts();
      
      if (localPosts.isNotEmpty) {
        _syncWithApiInBackground();
        return localPosts.map((model) => _modelToEntity(model)).toList();
      }

      final remotePosts = await remoteDataSource.getPosts();
      await localDataSource.cachePosts(remotePosts);
      return remotePosts.map((model) => _modelToEntity(model)).toList();
    } catch (e) {
      final localPosts = localDataSource.getCachedPosts();
      if (localPosts.isNotEmpty) {
        return localPosts.map((model) => _modelToEntity(model)).toList();
      }
      rethrow;
    }
  }

  Future<void> _syncWithApiInBackground() async {
    try {
      final remotePosts = await remoteDataSource.getPosts();
      final localPosts = localDataSource.getCachedPosts();
      
      if (remotePosts.length != localPosts.length) {
        await localDataSource.cachePosts(remotePosts);
        return;
      }

      for (var remotePost in remotePosts) {
        final localPost = localPosts.firstWhere(
          (p) => p.id == remotePost.id,
          orElse: () => remotePost,
        );
        
        if (localPost.title != remotePost.title ||
            localPost.body != remotePost.body ||
            localPost.userId != remotePost.userId) {
          await localDataSource.cachePosts(remotePosts);
          return;
        }
      }
    } catch (e) {
    }
  }

  @override
  Future<Post> getPostDetail(int id) async {
    try {
      final model = await remoteDataSource.getPostDetail(id);
      return _modelToEntity(model);
    } catch (e) {
      final localPosts = localDataSource.getCachedPosts();
      final localPost = localPosts.firstWhere(
        (post) => post.id == id,
        orElse: () => throw Exception('Post not found locally'),
      );
      return _modelToEntity(localPost);
    }
  }

  @override
  Future<void> markAsRead(int id) async {
    await localDataSource.markAsRead(id);
  }

  @override
  Map<int, bool> getReadStatus() {
    return localDataSource.getReadStatus();
  }

  @override
  bool isRead(int id) {
    return localDataSource.isRead(id);
  }
}

