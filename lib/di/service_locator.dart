import 'package:get_it/get_it.dart';
import 'package:pamsoft_grid_flutter_operator/implementations/services/mock_image_service.dart';
import 'package:pamsoft_grid_flutter_operator/implementations/services/mock_grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/implementations/services/mock_storage_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/image_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/grid_service.dart';
import 'package:pamsoft_grid_flutter_operator/services/storage_service.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Alias for backwards compatibility
final GetIt locator = getIt;

/// Sets up the service locator with dependency registrations.
///
/// Call this function before running the app to register all services.
///
/// Parameters:
///   - [useMocks]: If true, registers mock implementations. If false, registers
///     real implementations (when available). Defaults to true.
void setupServiceLocator({bool useMocks = true}) {
  if (useMocks) {
    // Register mock services
    locator.registerSingleton<ImageService>(MockImageService());
    locator.registerSingleton<GridService>(MockGridService());
    locator.registerSingleton<StorageService>(MockStorageService());
  } else {
    // TODO: Register real services when implemented
    throw UnimplementedError('Real services not yet implemented');
  }
}

/// Resets the service locator.
///
/// Useful for testing to ensure a clean state between tests.
Future<void> resetServiceLocator() async {
  await locator.reset();
}
