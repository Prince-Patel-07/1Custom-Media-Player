import 'package:custom_media_player/app/theme.dart';
import 'package:custom_media_player/features/home/home_screen.dart';
import 'package:flutter/material.dart';

class CustomMediaPlayerApp extends StatelessWidget {
  const CustomMediaPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Media Player',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
