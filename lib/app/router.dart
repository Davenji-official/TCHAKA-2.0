import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter tchakaRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const _FoundationScreen();
      },
    ),
  ],
);

class _FoundationScreen extends StatelessWidget {
  const _FoundationScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TCHAKA',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'TCHAKA 2.0 Foundation',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
