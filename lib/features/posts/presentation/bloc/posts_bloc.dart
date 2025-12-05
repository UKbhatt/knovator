import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  Future<void> _onLoadPostsEvent(
    LoadPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    emit(const PostsLoading());

    try {
      final posts = await getPosts();
      final readStatuses = repository.getReadStatus();
      emit(PostsLoaded(posts, readStatuses));

      add(const SyncPostsEvent());
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> _onSyncPostsEvent(
    SyncPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final posts = await getPosts();
      final readStatuses = repository.getReadStatus();
      emit(PostsSyncing(posts, readStatuses));
    } catch (e) {
      print('Syncronization error: $e');
      emit(PostsError(e.toString()));
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
}
