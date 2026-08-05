import 'package:flutter/material.dart';

import '../../../../core/animations/tchaka_entrance.dart';
import '../data/project_discovery_service.dart';
import '../data/project_engagement_service.dart';
import '../domain/project_discovery_filter.dart';
import 'widgets/tchaka_project_card.dart';

class ProjectDiscoveryScreen extends StatefulWidget {
  const ProjectDiscoveryScreen({super.key});

  @override
  State<ProjectDiscoveryScreen> createState() =>
      _ProjectDiscoveryScreenState();
}

class _ProjectDiscoveryScreenState
    extends State<ProjectDiscoveryScreen> {
  final List<String> _categories = const [
    'Pour toi',
    '🔥 Tendance',
    '🚀 Rising',
    '❤️ Populaires',
    '👥 Plus suivis',
    '🌍 Impact',
    '📍 Près de toi',
  ];

  final List<ProjectDiscoveryFilter> _filters =
      ProjectDiscoveryFilter.values;

  List<Map<String, dynamic>> _projects = [];

  final Map<String, bool> _likedProjects = {};
  final Map<String, bool> _bookmarkedProjects = {};
  final Map<String, bool> _followedCreators = {};

  bool _loading = true;
  String? _error;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects({
    ProjectDiscoveryFilter? filter,
  }) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final projects = filter == null
          ? await ProjectDiscoveryService.getProjectFeed()
          : await ProjectDiscoveryService.getProjectsForFilter(
              filter: filter,
            );

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _loading = false;
      });

      await _loadEngagementStates(projects);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les projets.';
      });
    }
  }

  Future<void> _loadEngagementStates(
    List<Map<String, dynamic>> projects,
  ) async {
    for (final project in projects) {
      final projectId = _stringValue(
        project,
        'id',
      );

      if (projectId.isEmpty) {
        continue;
      }

      try {
        final liked =
            await ProjectEngagementService.isProjectLiked(
          projectId,
        );

        final bookmarked =
            await ProjectEngagementService.isProjectBookmarked(
          projectId,
        );

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
        // Une erreur d'engagement ne bloque pas le feed.
      }
    }
  }

  Future<void> _toggleLike(
    Map<String, dynamic> project,
  ) async {
    final projectId = _stringValue(
      project,
      'id',
    );

    if (projectId.isEmpty) {
      return;
    }

    final previous =
        _likedProjects[projectId] ?? false;

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

      _showError(
        'Impossible de modifier le like.',
      );
    }
  }
    Future<void> _toggleBookmark(
    Map<String, dynamic> project,
  ) async {
    final projectId = _stringValue(
      project,
      'id',
    );

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
        onRefresh: () => _loadProjects(
          filter: _filters[_selectedCategory],
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildCategories(),
            ),
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  32,
                ),
                sliver: SliverList.builder(
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return TchakaEntrance(
                      delay: Duration(
                        milliseconds: 70 * index,
                      ),
                      child: const _ProjectSkeleton(),
                    );
                  },
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildError(),
              )
            else if (_projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  32,
                ),
                sliver: SliverList.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];

                    final projectId =
                        _stringValue(
                      project,
                      'id',
                    );

                    final creatorId =
                        _stringValue(
                      project,
                      'creator_id',
                    );

                    return TchakaEntrance(
                      delay: Duration(
                        milliseconds: 70 * index,
                      ),
                      child: TchakaProjectCard(
                        project: project,
                        liked:
                            _likedProjects[projectId] ??
                                false,
                        bookmarked:
                            _bookmarkedProjects[
                                    projectId] ??
                                false,
                        followed:
                            _followedCreators[
                                    creatorId] ??
                                false,
                        onLike: () =>
                            _toggleLike(project),
                        onBookmark: () =>
                            _toggleBookmark(project),
                        onFollow: () =>
                            _toggleFollow(project),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader() {
    final selectedLabel =
        _categories[_selectedCategory];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Découvre des projets',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Des idées, des initiatives et des projets qui méritent ton attention.',
          style: Theme.of(context)
              .textTheme
              .bodyLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          readOnly: true,
          onTap: () {},
          decoration: InputDecoration(
            hintText: 'Rechercher un projet...',
            prefixIcon: const Icon(
              Icons.search_rounded,
            ),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.tune_rounded,
              ),
            ),
            filled: true,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(width: 6),
            Text(
              selectedLabel,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected =
              index == _selectedCategory;

          return ChoiceChip(
            label: Text(
              _categories[index],
            ),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = index;
              });

              if (index < _filters.length) {
                _loadProjects(
                  filter: _filters[index],
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding:
          const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: Theme.of(context)
                .colorScheme
                .error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () =>
                _loadProjects(
              filter: _filters[
                  _selectedCategory],
            ),
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
                const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding:
          const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Aucun projet pour le moment',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Les nouveaux projets apparaîtront ici au fur et à mesure.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () =>
                _loadProjects(
              filter: _filters[
                  _selectedCategory],
            ),
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
                const Text('Actualiser'),
          ),
        ],
      ),
    );
  }
}
class _ProjectSkeleton
    extends StatelessWidget {
  const _ProjectSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest;

    Widget box({
      required double height,
      double? width,
      double radius = 14,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              BorderRadius.circular(radius),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          box(
            height: 190,
            width: double.infinity,
            radius: 0,
          ),
          Padding(
            padding:
                const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                box(
                  height: 18,
                  width: 90,
                ),
                const SizedBox(
                  height: 14,
                ),
                box(
                  height: 24,
                  width: 220,
                ),
                const SizedBox(
                  height: 10,
                ),
                box(
                  height: 16,
                  width: double.infinity,
                ),
                const SizedBox(
                  height: 8,
                ),
                box(
                  height: 16,
                  width: 250,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    box(
                      height: 34,
                      width: 90,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    box(
                      height: 34,
                      width: 110,
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
}
