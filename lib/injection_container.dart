import 'package:get_it/get_it.dart';
import 'package:photo_editor/features/data/image_repository_impl.dart';
import 'package:photo_editor/features/domain/repository/image_repository.dart';

final sl = GetIt.instance;

class InjectionContainer {
Future<void> init() async {
  // Repository
  sl.registerLazySingleton<ImageRepository>(
    () => ImageRepositoryImpl(),
  );
}
}