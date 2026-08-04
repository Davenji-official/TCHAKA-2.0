import 'package:flutter/material.dart';

import '../../../../core/animations/tchaka_entrance.dart';
import '../../../../core/widgets/tchaka_badge.dart';
import '../data/project_discovery_service.dart';
import '../data/project_engagement_service.dart';
import '../domain/project_discovery_filter.dart';

class ProjectDiscoveryScreen extends StatefulWidget {
  const ProjectDiscoveryScreen({super.key});

  @override
  State<ProjectDiscoveryScreen> createState() =>
      _ProjectDiscoveryScreenState();
}

class _ProjectDiscoveryScreenState extends State<ProjectDiscoveryScreen> {
  final List<ProjectDiscoveryFilter> _filters =
      ProjectDiscoveryFilter.values;

  List<Map<String, dynamic>> _projects = [];

  final Map<String, bool> _likedProjects = {};
  final Map<String, bool> _bookmarkedProjects = {};
  final Map<String, bool> _followedCreators = {};

  bool _loading = true;
  String? _error;

  ProjectDiscoveryFilter _selectedFilter =
      ProjectDiscoveryFilter.forYou;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final projects =
          await ProjectDiscoveryService.getProjectsForFilter(
        filter: _selectedFilter,
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
      final projectId = _stringValue(project, 'id');

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

        final creatorId =
            _stringValue(project, 'creator_id');

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

  Future<void> _selectFilter(
    ProjectDiscoveryFilter filter,
  ) async {
    if (_selectedFilter == filter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
    });

    await _loadProjects();
  }

  Future<void> _toggleLike(
    Map<String, dynamic> project,
  ) async {
    final projectId = _stringValue(project, 'id');

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
          await ProjectEngagementService
              .toggleProjectBookmark(
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
    final creatorId =
        _stringValue(project, 'creator_id');

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
          await ProjectEngagementService
              .toggleCreatorFollow(
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
        onRefresh: _loadProjects,
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
              child: _buildFilters(),
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
                    return const _ProjectSkeleton();
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
                        _stringValue(project, 'id');

                    final creatorId =
                        _stringValue(
                      project,
                      'creator_id',
                    );

                    return TchakaEntrance(
                      delay: Duration(
                        milliseconds: 70 * index,
                      ),
                      child: _ProjectCard(
                        project: project,
                        index: index,
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
          'Des idées, des initiatives et des projets '
          'qui méritent ton attention.',
          style:
              Theme.of(context).textTheme.bodyLarge,
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];

          return ChoiceChip(
            label: Text(filter.label),
            selected:
                filter == _selectedFilter,
            onSelected: (_) {
              _selectFilter(filter);
            },
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color:
                Theme.of(context)
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
            onPressed: _loadProjects,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Réessayer',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color:
                Theme.of(context)
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
            'Les nouveaux projets apparaîtront ici '
            'au fur et à mesure.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadProjects,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Actualiser',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.index,
    required this.liked,
    required this.bookmarked,
    required this.followed,
    required this.onLike,
    required this.onBookmark,
    required this.onFollow,
  });

  final Map<String, dynamic> project;
  final int index;
  final bool liked;
  final bool bookmarked;
  final bool followed;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onFollow;

  String _stringValue(
    String key, [
    String fallback = '',
  ]) {
    final value = project[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  int _intValue(String key) {
    final value = project[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _doubleValue(String key) {
    final value = project[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    final title = _stringValue(
      'title',
      'Projet TCHAKA',
    );

    final description = _stringValue(
      'description',
      'Un nouveau projet de la communauté TCHAKA.',
    );

    final imageUrl =
        _stringValue('cover_image_url');

    final category = _stringValue(
      'category',
      'Projet',
    );

    final likes =
        _intValue('likes_count');

    final comments =
        _intValue('comments_count');

    final matchingSkills =
        _intValue('matching_skills_count');

    final score =
        _doubleValue('feed_score');

    final creatorId =
        _stringValue('creator_id');

    final normalizedCategory =
        category.toLowerCase();

    final isTrending = likes >= 100;

    final isRising =
        likes >= 25 && likes < 100;

    final isImpact =
        normalizedCategory.contains('impact') ||
        normalizedCategory.contains('humanitaire');
        return Card(
      clipBehavior: Clip.antiAlias,
      margin:
          const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) {
                      return const
                          _ProjectImagePlaceholder();
                    },
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isTrending)
                          const TchakaBadge(
                            label: 'TENDANCE',
                            icon: Icons
                                .local_fire_department_rounded,
                            highlight: true,
                          ),
                        if (isRising)
                          const TchakaBadge(
                            label: 'RISING',
                            icon: Icons
                                .rocket_launch_rounded,
                            highlight: true,
                          ),
                        if (isImpact)
                          const TchakaBadge(
                            label: 'IMPACT',
                            icon: Icons.public_rounded,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _ProjectImagePlaceholder(),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isTrending)
                          const TchakaBadge(
                            label: 'TENDANCE',
                            icon: Icons
                                .local_fire_department_rounded,
                            highlight: true,
                          ),
                        if (isRising)
                          const TchakaBadge(
                            label: 'RISING',
                            icon: Icons
                                .rocket_launch_rounded,
                            highlight: true,
                          ),
                        if (isImpact)
                          const TchakaBadge(
                            label: 'IMPACT',
                            icon: Icons.public_rounded,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              20,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: TchakaBadge(
                        label:
                            category.toUpperCase(),
                        icon:
                            Icons.category_rounded,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onBookmark,
                      icon: Icon(
                        bookmarked
                            ? Icons
                                .bookmark_rounded
                            : Icons
                                .bookmark_border_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),
                if (matchingSkills > 0) ...[
                  Row(
                    children: [
                      Icon(
                        Icons
                            .auto_awesome_rounded,
                        size: 16,
                        color:
                            Theme.of(context)
                                .colorScheme
                                .primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$matchingSkills compétence'
                          '${matchingSkills > 1 ? 's' : ''} '
                          'correspondante'
                          '${matchingSkills > 1 ? 's' : ''}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 17,
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Score Discovery '
                      '${score.toStringAsFixed(1)}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                                Row(
                  children: [
                    Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons
                              .favorite_border_rounded,
                      size: 18,
                      color: liked
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                          : null,
                    ),
                    const SizedBox(width: 5),
                    Text('$likes'),
                    const SizedBox(width: 18),
                    const Icon(
                      Icons
                          .chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text('$comments'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton.icon(
                        onPressed: onLike,
                        icon: Icon(
                          liked
                              ? Icons
                                  .favorite_rounded
                              : Icons
                                  .favorite_border_rounded,
                        ),
                        label: Text(
                          liked
                              ? 'Aimé'
                              : 'J’aime',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: followed
                          ? FilledButton.icon(
                              onPressed:
                                  creatorId.isEmpty
                                      ? null
                                      : onFollow,
                              icon: const Icon(
                                Icons.person_rounded,
                              ),
                              label: const Text(
                                'Suivi',
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed:
                                  creatorId.isEmpty
                                      ? null
                                      : onFollow,
                              icon: const Icon(
                                Icons
                                    .person_add_alt_1_rounded,
                              ),
                              label: const Text(
                                'Suivre',
                              ),
                            ),
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

class _ProjectImagePlaceholder
    extends StatelessWidget {
  const _ProjectImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.rocket_launch_outlined,
          size: 52,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
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
          const EdgeInsets.only(bottom: 18),
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
                const SizedBox(height: 14),
                box(
                  height: 24,
                  width: 220,
                ),
                const SizedBox(height: 10),
                box(
                  height: 16,
                  width: double.infinity,
                ),
                const SizedBox(height: 8),
                box(
                  height: 16,
                  width: 250,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    box(
                      height: 34,
                      width: 90,
                    ),
                    const SizedBox(width: 10),
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
