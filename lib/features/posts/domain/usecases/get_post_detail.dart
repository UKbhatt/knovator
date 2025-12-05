import '../entities/post.dart';
import '../repositories/post_repository.dart';

class GetPostDetail {
  final PostRepository repository;

  GetPostDetail(this.repository);

  Future<Post> call(int id) {
    return repository.getPostDetail(id);
  }
}

