import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'router.dart';

class TchakaApp extends StatelessWidget {
  const TchakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TCHAKA',
      debugShowCheckedModeBanner: false,
      theme: TchakaTheme.dark(),
      routerConfig: tchakaRouter,
    );
  }
}
