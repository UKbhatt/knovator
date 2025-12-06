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
  final bool isOffline;

  const PostsLoaded(this.posts, this.readStatuses, {this.isOffline = false});

  @override
  List<Object?> get props => [posts, readStatuses, isOffline];
}

class PostsSyncing extends PostsState {
  final List<Post> updatedPosts;
  final Map<int, bool> readStatuses;
  final bool isOffline;

  const PostsSyncing(this.updatedPosts, this.readStatuses, {this.isOffline = false});

  @override
  List<Object?> get props => [updatedPosts, readStatuses, isOffline];
}

class PostsError extends PostsState {
  final String message;

  const PostsError(this.message);

  @override
  List<Object?> get props => [message];
}

