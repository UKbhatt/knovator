import 'package:equatable/equatable.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPostsEvent extends PostsEvent {
  const LoadPostsEvent();
}

class SyncPostsEvent extends PostsEvent {
  const SyncPostsEvent();
}

class MarkAsReadEvent extends PostsEvent {
  final int postId;

  const MarkAsReadEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

