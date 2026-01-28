import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:steering/themes/theme_provider.dart';

class DeviceNotConnected extends StatelessWidget {
  const DeviceNotConnected({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        final errorColor = isDark ? Colors.redAccent : Color(0xFFD32F2F);
        final subTextColor = isDark ? Colors.white54 : Color(0xFF757575);
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.portable_wifi_off, size: 80, color: errorColor),
              const SizedBox(height: 16),
              Text(
                "DEVICE NOT CONNECTED",
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: errorColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Waiting for data from Raspberry Pi…",
                style: TextStyle(color: subTextColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
