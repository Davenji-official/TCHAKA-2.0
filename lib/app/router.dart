import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/projects/presentation/create_project_screen.dart';
import '../features/projects/presentation/project_applications_screen.dart';
import '../features/projects/presentation/project_detail_screen.dart';
import '../features/projects/presentation/project_discovery_screen.dart';

final GoRouter tchakaRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const AuthGate();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegisterScreen();
      },
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) {
        return const ProjectDiscoveryScreen();
      },
    ),
    GoRoute(
      path: '/projects/create',
      builder: (context, state) {
        return const CreateProjectScreen();
      },
    ),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'];

        if (projectId == null || projectId.isEmpty) {
          return const ProjectDiscoveryScreen();
        }

        return ProjectDetailScreen(
          projectId: projectId,
        );
      },
    ),
    GoRoute(
      path: '/projects/:projectId/applications',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'];

        if (projectId == null || projectId.isEmpty) {
          return const ProjectDiscoveryScreen();
        }

        return ProjectApplicationsScreen(
          projectId: projectId,
        );
      },
    ),
  ],
);
