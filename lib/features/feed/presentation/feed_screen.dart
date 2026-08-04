import 'package:flutter/material.dart';

import '../../../core/animations/tchaka_entrance.dart';
import '../../projects/data/project_engagement_service.dart';
import '../../projects/presentation/widgets/tchaka_project_card.dart';
import '../data/feed_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<Map<String, dynamic>> _projects = [];

  final Map<String, bool> _likedProjects = {};
  final Map<String, bool> _bookmarkedProjects = {};
  final Map<String, bool> _followedCreators = {};

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  String? _error;

  int _offset = 0;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
        _hasMore = true;
      });
    }

    try {
      final projects = await FeedService.getProjectFeed(
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted) return;

      setState(() {
        _projects
          ..clear()
          ..addAll(projects);

        _offset = projects.length;
        _hasMore = projects.length >= _pageSize;
        _loading = false;
      });

      await _loadEngagementStates(projects);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger le fil TCHAKA.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });

    try {
      final projects = await FeedService.getProjectFeed(
        limit: _pageSize,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        _projects.addAll(projects);
        _offset += projects.length;
        _hasMore = projects.length >= _pageSize;
        _loadingMore = false;
      });

      await _loadEngagementStates(projects);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadEngagementStates(
    List<Map<String, dynamic>> projects,
  ) async {
    for (final project in projects) {
      final projectId = _stringValue(project, 'id');

      if (projectId.isEmpty) {
        continue;
      }

      try {
        final liked =
            await ProjectEngagementService.isProjectLiked(projectId);

        final bookmarked =
            await ProjectEngagementService.isProjectBookmarked(projectId);

        final creatorId = _stringValue(
          project,
          'creator_id',
        );

        bool followed = false;

        if (creatorId.isNotEmpty) {
          followed =
              await ProjectEngagementService.isFollowingCreator(
            creatorId,
          );
        }

        if (!mounted) return;

        setState(() {
          _likedProjects[projectId] = liked;
          _bookmarkedProjects[projectId] = bookmarked;

          if (creatorId.isNotEmpty) {
            _followedCreators[creatorId] = followed;
          }
        });
      } catch (_) {
        // Une erreur d'engagement ne doit pas bloquer le Feed.
      }
    }
  }

  Future<void> _toggleLike(
    Map<String, dynamic> project,
  ) async {
    final projectId = _stringValue(project, 'id');

    if (projectId.isEmpty) {
      return;
    }

    final previous = _likedProjects[projectId] ?? false;

    setState(() {
      _likedProjects[projectId] = !previous;
    });

    try {
      final liked =
          await ProjectEngagementService.toggleProjectLike(
        projectId: projectId,
      );

      if (!mounted) return;

      setState(() {
        _likedProjects[projectId] = liked;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _likedProjects[projectId] = previous;
      });

      _showError('Impossible de modifier le like.');
    }
  }
  Future<void> _toggleBookmark(
    Map<String, dynamic> project,
  ) async {
    final projectId = _stringValue(project, 'id');

    if (projectId.isEmpty) {
      return;
    }

    final previous =
        _bookmarkedProjects[projectId] ?? false;

    setState(() {
      _bookmarkedProjects[projectId] = !previous;
    });

    try {
      final bookmarked =
          await ProjectEngagementService.toggleProjectBookmark(
        projectId: projectId,
      );

      if (!mounted) return;

      setState(() {
        _bookmarkedProjects[projectId] = bookmarked;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _bookmarkedProjects[projectId] = previous;
      });

      _showError(
        'Impossible d’enregistrer ce projet.',
      );
    }
  }

  Future<void> _toggleFollow(
    Map<String, dynamic> project,
  ) async {
    final creatorId = _stringValue(
      project,
      'creator_id',
    );

    if (creatorId.isEmpty) {
      return;
    }

    final previous =
        _followedCreators[creatorId] ?? false;

    setState(() {
      _followedCreators[creatorId] = !previous;
    });

    try {
      final followed =
          await ProjectEngagementService.toggleCreatorFollow(
        creatorId: creatorId,
      );

      if (!mounted) return;

      setState(() {
        _followedCreators[creatorId] = followed;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _followedCreators[creatorId] = previous;
      });

      _showError(
        'Impossible de modifier le suivi.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _stringValue(
    Map<String, dynamic> map,
    String key, [
    String fallback = '',
  ]) {
    final value = map[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCHAKA'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    if (_projects.isEmpty) {
      return _buildEmpty();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 500) {
          _loadMore();
        }

        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32,
        ),
        itemCount:
            _projects.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _projects.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final project = _projects[index];

          final projectId =
              _stringValue(project, 'id');

          final creatorId =
              _stringValue(project, 'creator_id');

          return TchakaEntrance(
            delay: Duration(
              milliseconds: 60 * (index % 6),
            ),
            child: TchakaProjectCard(
              project: project,
              liked:
                  _likedProjects[projectId] ?? false,
              bookmarked:
                  _bookmarkedProjects[projectId] ??
                      false,
              followed:
                  _followedCreators[creatorId] ??
                      false,
              onLike: () => _toggleLike(project),
              onBookmark: () =>
                  _toggleBookmark(project),
              onFollow: () =>
                  _toggleFollow(project),
            ),
          );
        },
      ),
    );
  }
  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32,
      ),
      children: [
        _loadingCard(),
        const SizedBox(height: 18),
        _loadingCard(),
        const SizedBox(height: 18),
        _loadingCard(),
      ],
    );
  }

  Widget _loadingCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _loadingBox(
            height: 190,
            radius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _loadingLine(
                  width: 100,
                  height: 18,
                ),
                const SizedBox(height: 14),
                _loadingLine(
                  width: 230,
                  height: 24,
                ),
                const SizedBox(height: 12),
                _loadingLine(
                  width: double.infinity,
                  height: 14,
                ),
                const SizedBox(height: 8),
                _loadingLine(
                  width: 250,
                  height: 14,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _loadingLine(
                      width: 90,
                      height: 34,
                      radius: 12,
                    ),
                    const SizedBox(width: 10),
                    _loadingLine(
                      width: 105,
                      height: 34,
                      radius: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingLine({
    required double width,
    required double height,
    double radius = 20,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(radius),
      ),
    );
  }

  Widget _loadingBox({
    required double height,
    double radius = 20,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.cloud_off_rounded,
          size: 58,
          color:
              Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 18),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style:
              Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 22),
        Center(
          child: FilledButton.icon(
            onPressed: _loadFeed,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Réessayer',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.10),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 42,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Ton Feed est encore calme.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Les nouveaux projets apparaîtront ici.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        Center(
          child: OutlinedButton.icon(
            onPressed: _loadFeed,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Actualiser',
            ),
          ),
        ),
      ],
    );
  }
}
