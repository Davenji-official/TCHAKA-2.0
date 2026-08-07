import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/collaboration/presentation/collaboration_screen.dart';
import '../features/explore/presentation/explore_screen.dart';
import '../features/funding/presentation/funding_screen.dart';
import '../features/messaging/presentation/chat_screen.dart';
import '../features/messaging/presentation/messages_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/projects/presentation/create_project_screen.dart';
import '../features/projects/presentation/project_applications_screen.dart';
import '../features/projects/presentation/project_detail_screen.dart';
import '../features/projects/presentation/project_discovery_screen.dart';

final GoRouter tchakaRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesScreen(),
    ),
    GoRoute(
      path: '/messages/:conversationId',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId'];
        if (conversationId == null || conversationId.isEmpty) {
          return const MessagesScreen();
        }
        return ChatScreen(conversationId: conversationId);
      },
    ),
    GoRoute(
      path: '/explore',
      builder: (context, state) => const ExploreScreen(),
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) => const ProjectDiscoveryScreen(),
    ),
    GoRoute(
      path: '/projects/create',
      builder: (context, state) => const CreateProjectScreen(),
    ),
    GoRoute(
      path: '/projects/:projectId/funding',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'];
        if (projectId == null || projectId.isEmpty) {
          return const ProjectDiscoveryScreen();
        }
        return FundingScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: '/projects/:projectId/applications',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'];
        if (projectId == null || projectId.isEmpty) {
          return const ProjectDiscoveryScreen();
        }
        return ProjectApplicationsScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: '/projects/:projectId/collaboration',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'];
        if (projectId == null || projectId.isEmpty) {
          return const ProjectDiscoveryScreen();
        }
        return CollaborationScreen(projectId: projectId);
      },
    ),
    GoRoute(
      path: '/projects/:projectId',
      builder: (context, state) {
        final projectId = state.pathParameters['projectId'];
        if (projectId == null || projectId.isEmpty) {
          return const ProjectDiscoveryScreen();
        }
        return ProjectDetailScreen(projectId: projectId);
      },
    ),
  ],
);
