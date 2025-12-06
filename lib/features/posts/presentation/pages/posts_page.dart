import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_post_detail.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import 'post_detail_page.dart';

class PostsPage extends StatelessWidget {
  final GetPostDetail getPostDetail;

  const PostsPage({super.key, required this.getPostDetail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          if (state is PostsInitial) {
            context.read<PostsBloc>().add(const LoadPostsEvent());
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PostsBloc>().add(const LoadPostsEvent());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PostsLoaded || state is PostsSyncing) {
            final posts = state is PostsLoaded
                ? state.posts
                : (state as PostsSyncing).updatedPosts;
            final readStatuses = state is PostsLoaded
                ? state.readStatuses
                : (state as PostsSyncing).readStatuses;
            final isOffline = state is PostsLoaded
                ? state.isOffline
                : (state as PostsSyncing).isOffline;

            return BlocListener<PostsBloc, PostsState>(
              listenWhen: (previous, current) {
                return previous != current && 
                       (current is PostsLoaded && current.isOffline);
              },
              listener: (context, state) {
                if (state is PostsLoaded && state.isOffline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No internet connection'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<PostsBloc>().add(const RefreshPostsEvent());
                  await Future.delayed(const Duration(seconds: 1));
                },
              child: Column(
                children: [
                  if (isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade900),
                          const SizedBox(width: 8),
                          Text(
                            'You\'re offline — showing saved content',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final isRead = readStatuses[post.id] ?? false;

                        return InkWell(
                          onTap: () {
                            context.read<PostsBloc>().add(MarkAsReadEvent(post.id));
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailPage(
                                  postId: post.id,
                                  getPostDetail: getPostDetail,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            color: isRead ? Colors.white : Colors.yellow.shade100,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  post.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                ),
              ),
            );
          }

          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}
