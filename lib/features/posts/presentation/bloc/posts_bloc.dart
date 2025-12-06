import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/usecases/get_posts.dart';
import '../../domain/repositories/post_repository.dart';
import 'posts_event.dart';
import 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPosts getPosts;
  final PostRepository repository;

  PostsBloc({required this.getPosts, required this.repository})
    : super(const PostsInitial()) {
    on<LoadPostsEvent>(_onLoadPostsEvent);
    on<SyncPostsEvent>(_onSyncPostsEvent);
    on<MarkAsReadEvent>(_onMarkAsReadEvent);
    on<RefreshPostsEvent>(_onRefreshPostsEvent);
  }

  Future<void> _onLoadPostsEvent(
    LoadPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    final localPosts = repository.getReadStatus();
    final hasLocalData = localPosts.isNotEmpty;

    if (!hasLocalData) {
      emit(const PostsLoading());
    }

    try {
      final posts = await getPosts();
      final readStatuses = repository.getReadStatus();
      emit(PostsLoaded(posts, readStatuses, isOffline: false));

      add(const SyncPostsEvent());
    } on NoInternetException {
      final posts = await getPosts();
      final readStatuses = repository.getReadStatus();
      emit(PostsLoaded(posts, readStatuses, isOffline: true));
    } catch (e) {
      final localPosts = repository.getReadStatus();
      if (localPosts.isNotEmpty) {
        final posts = await getPosts();
        final readStatuses = repository.getReadStatus();
        emit(PostsLoaded(posts, readStatuses, isOffline: true));
      } else {
        emit(PostsError(e.toString()));
      }
    }
  }

  Future<void> _onSyncPostsEvent(
    SyncPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final posts = await getPosts();
      final readStatuses = repository.getReadStatus();
      emit(PostsSyncing(posts, readStatuses, isOffline: false));
    } on NoInternetException {
    } catch (e) {
    }
  }

  Future<void> _onMarkAsReadEvent(
    MarkAsReadEvent event,
    Emitter<PostsState> emit,
  ) async {
    await repository.markAsRead(event.postId);

    if (state is PostsLoaded) {
      final currentState = state as PostsLoaded;
      final updatedReadStatuses = Map<int, bool>.from(
        currentState.readStatuses,
      );
      updatedReadStatuses[event.postId] = true;
      emit(PostsLoaded(currentState.posts, updatedReadStatuses));
    } else if (state is PostsSyncing) {
      final currentState = state as PostsSyncing;
      final updatedReadStatuses = Map<int, bool>.from(
        currentState.readStatuses,
      );
      updatedReadStatuses[event.postId] = true;
      emit(PostsSyncing(currentState.updatedPosts, updatedReadStatuses));
    }
  }

  Future<void> _onRefreshPostsEvent(
    RefreshPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final posts = await getPosts();
      final readStatuses = repository.getReadStatus();
      if (state is PostsLoaded) {
        emit(PostsLoaded(posts, readStatuses, isOffline: false));
      } else if (state is PostsSyncing) {
        emit(PostsSyncing(posts, readStatuses, isOffline: false));
      }
      add(const SyncPostsEvent());
    } on NoInternetException {
      if (state is PostsLoaded) {
        final currentState = state as PostsLoaded;
        emit(PostsLoaded(currentState.posts, currentState.readStatuses, isOffline: true));
      } else if (state is PostsSyncing) {
        final currentState = state as PostsSyncing;
        emit(PostsSyncing(currentState.updatedPosts, currentState.readStatuses, isOffline: true));
      }
    } catch (e) {
    }
  }
}
