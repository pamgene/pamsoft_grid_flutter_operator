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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator(useMocks: true);
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
