import '../entities/post.dart';

abstract class PostRepository {
  Future<List<Post>> getPosts();
  Future<Post> getPostDetail(int id);
  Future<void> markAsRead(int id);
  Map<int, bool> getReadStatus();
  bool isRead(int id);
}

