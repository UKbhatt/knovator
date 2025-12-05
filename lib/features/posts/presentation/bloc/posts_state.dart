import 'package:equatable/equatable.dart';
import '../../domain/entities/post.dart';

abstract class PostsState extends Equatable {
  const PostsState();

  @override
  List<Object?> get props => [];
}

class PostsInitial extends PostsState {
  const PostsInitial();
}

class PostsLoading extends PostsState {
  const PostsLoading();
}

class PostsLoaded extends PostsState {
  final List<Post> posts;
  final Map<int, bool> readStatuses;

  const PostsLoaded(this.posts, this.readStatuses);

  @override
  List<Object?> get props => [posts, readStatuses];
}

class PostsSyncing extends PostsState {
  final List<Post> updatedPosts;
  final Map<int, bool> readStatuses;

  const PostsSyncing(this.updatedPosts, this.readStatuses);

  @override
  List<Object?> get props => [updatedPosts, readStatuses];
}

class PostsError extends PostsState {
  final String message;

  const PostsError(this.message);

  @override
  List<Object?> get props => [message];
}

