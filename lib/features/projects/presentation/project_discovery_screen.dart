import 'package:flutter/material.dart';

import '../data/project_discovery_service.dart';

class ProjectDiscoveryScreen extends StatefulWidget {
  const ProjectDiscoveryScreen({super.key});

  @override
  State<ProjectDiscoveryScreen> createState() =>
      _ProjectDiscoveryScreenState();
}

class _ProjectDiscoveryScreenState extends State<ProjectDiscoveryScreen> {
  final List<String> _categories = const [
    'Pour toi',
    '🔥 Tendance',
    '🚀 Rising',
    '❤️ Populaires',
    '👥 Plus suivis',
    '🌍 Impact',
    '📍 Près de toi',
  ];

  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;
  String? _error;
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projects = await ProjectDiscoveryService.getProjectFeed();

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les projets.';
      });
    }
  }

  Future<void> _refresh() async {
    await _loadProjects();
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
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildCategories(),
            ),
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    return _ProjectCard(
                      project: _projects[index],
                      index: index,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Découvre des projets',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Des idées, des initiatives et des projets qui méritent ton attention.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        TextField(
          readOnly: true,
          onTap: () {},
          decoration: InputDecoration(
            hintText: 'Rechercher un projet...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: const Icon(Icons.tune_rounded),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;

          return ChoiceChip(
            label: Text(_categories[index]),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = index;
              });
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadProjects,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Aucun projet pour le moment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Les nouveaux projets apparaîtront ici au fur et à mesure.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadProjects,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualiser'),
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
  });

  final Map<String, dynamic> project;
  final int index;

  String _stringValue(String key, [String fallback = '']) {
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

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(String key) {
    final value = project[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final title = _stringValue(
      'title',
      _stringValue('name', 'Projet TCHAKA'),
    );

    final description = _stringValue(
      'description',
      'Un nouveau projet de la communauté TCHAKA.',
    );

    final imageUrl = _stringValue(
      'cover_url',
      _stringValue('image_url'),
    );

    final category = _stringValue(
      'category',
      'Projet',
    );

    final likes = _intValue('likes_count');
    final comments = _intValue('comments_count');
    final followers = _intValue('followers_count');

    final rawScore = _doubleValue('feed_score');
    final progress = rawScore.clamp(0.0, 100.0) / 100.0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + (index * 80)),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const _ProjectImagePlaceholder();
                  },
                ),
              )
            else
              const AspectRatio(
                aspectRatio: 16 / 9,
                child: _ProjectImagePlaceholder(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                        ),
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Enregistrer',
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score Discovery : ${rawScore.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.favorite_border_rounded,
                        value: likes,
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        value: comments,
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Icons.people_outline_rounded,
                        value: followers,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_border_rounded),
                          label: const Text('J’aime'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Suivre'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 5),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _ProjectImagePlaceholder extends StatelessWidget {
  const _ProjectImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.rocket_launch_outlined,
          size: 52,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ProjectSkeleton extends StatelessWidget {
  const _ProjectSkeleton();

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.surfaceContainerHighest;

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
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box(
            height: 190,
            width: double.infinity,
            radius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(height: 18, width: 90),
                const SizedBox(height: 14),
                box(height: 24, width: 220),
                const SizedBox(height: 10),
                box(height: 16, width: double.infinity),
                const SizedBox(height: 8),
                box(height: 16, width: 250),
                const SizedBox(height: 20),
                box(height: 8, width: double.infinity),
                const SizedBox(height: 20),
                Row(
                  children: [
                    box(height: 34, width: 90),
                    const SizedBox(width: 10),
                    box(height: 34, width: 110),
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
