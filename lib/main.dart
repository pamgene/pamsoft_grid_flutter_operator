import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pamsoft_grid_flutter_operator/core/theme/app_theme.dart';
import 'package:pamsoft_grid_flutter_operator/di/service_locator.dart';
import 'package:pamsoft_grid_flutter_operator/providers/grid_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/image_selection_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/settings_provider.dart';
import 'package:pamsoft_grid_flutter_operator/providers/theme_provider.dart';
import 'package:pamsoft_grid_flutter_operator/screens/home_screen.dart';
import 'package:pamsoft_grid_flutter_operator/utils/constants.dart';
import 'package:pamsoft_grid_flutter_operator/utils/tercen_url_parser.dart';
import 'package:sci_tercen_client/sci_service_factory_web.dart';
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse URL to determine deployment mode
  final urlParser = TercenUrlParser();

  // Try to initialize Tercen ServiceFactory
  tercen.ServiceFactory? tercenFactory;
  bool useMocks = false;

  try {
    print('🔍 Attempting to initialize Tercen ServiceFactory...');
    tercenFactory = await createServiceFactoryForWebApp();
    getIt.registerSingleton<tercen.ServiceFactory>(tercenFactory);
    getIt.registerSingleton<TercenUrlParser>(urlParser);
    print('✓ Tercen ServiceFactory initialized successfully');
  } catch (e) {
    print('⚠️ Could not connect to Tercen: $e');
    print('   Falling back to mock data');
    useMocks = true;
  }

  setupServiceLocator(useMocks: useMocks);
  runApp(const PamsoftGridCheckerApp());
}

class PamsoftGridCheckerApp extends StatelessWidget {
  const PamsoftGridCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ImageSelectionProvider()),
        ChangeNotifierProvider(create: (_) => GridProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
