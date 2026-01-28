import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:steering/themes/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final double iconSize;
  final Color? backgroundColor;

  const ThemeToggleButton({
    super.key,
    this.iconSize = 24,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Tooltip(
          message: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
          child: IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: iconSize,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },

            color: backgroundColor,
          ),
        );
      },
    );
  }
}
