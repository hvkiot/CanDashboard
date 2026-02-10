import 'package:steering/dashboard_home.dart';
import 'package:steering/themes/app_themes.dart';
import 'package:steering/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  try {
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const Dashboard(),
      ),
    );
  } catch (e) {
    Logger().e("Main App Error: $e");
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const DashboardHome(),
        );
      },
    );
  }
}
