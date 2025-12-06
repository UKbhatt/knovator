import 'package:flutter/material.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/get_post_detail.dart';

class PostDetailPage extends StatefulWidget {
  final int postId;
  final GetPostDetail getPostDetail;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.getPostDetail,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Post? post;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPostDetail();
  }

  Future<void> _loadPostDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final postDetail = await widget.getPostDetail(widget.postId);
      setState(() {
        post = postDetail;
        isLoading = false;
      });
    } catch (e) {
      String errorMsg = e.toString();
      if (e is NoInternetException || errorMsg.contains('Post not found locally')) {
        errorMsg = 'You are offline. Cannot load new details.';
      }
      setState(() {
        errorMessage = errorMsg.replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPostDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (post == null) {
      return const Center(child: Text('Post not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Post ID: ${post!.id}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'User ID: ${post!.userId}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Description:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(post!.body, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}
