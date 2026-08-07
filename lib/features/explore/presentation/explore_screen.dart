import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../projects/data/project_discovery_service.dart';
import '../../../projects/data/project_engagement_service.dart';
import '../../../projects/domain/project_discovery_filter.dart';
import '../../../projects/presentation/widgets/tchaka_project_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = const [
    'Design',
    'Technologie',
    'Agriculture',
    'Art',
    'Éducation',
    'Business',
  ];

  final List<Map<String, dynamic>> _projects = [];
  final Map<String, bool> _likedProjects = {};
  final Map<String, bool> _bookmarkedProjects = {};
  final Map<String, bool> _followedCreators = {};

  String? _selectedCategory;
  String? _error;
  bool _loading = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadPopularProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularProjects() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final projects = await ProjectDiscoveryService.getProjectsForFilter(
        filter: ProjectDiscoveryFilter.mostLiked,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _projects
          ..clear()
          ..addAll(projects);
        _loading = false;
      });

      await _loadEngagementStates(projects);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger les projets à découvrir.';
      });
    }
  }

  Future<void> _searchProjects() async {
    final query = _searchController.text.trim();
    final category = _selectedCategory;

    if (query.isEmpty && category == null) {
      await _loadPopularProjects();
      return;
    }

    if (mounted) {
      setState(() {
        _searching = true;
        _error = null;
      });
    }

    try {
      final projects = await ProjectDiscoveryService.searchProjects(
        query: query.isEmpty ? null : query,
        category: category,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _projects
          ..clear()
          ..addAll(projects);
        _searching = false;
      });

      await _loadEngagementStates(projects);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _searching = false;
        _error = 'Impossible d’effectuer la recherche.';
      });
    }
  }

  Future<void> _loadEngagementStates(
    List<Map<String, dynamic>> projects,
  ) async {
    await Future.wait(
      projects.map((project) async {
        final projectId = _stringValue(project, 'id');
        if (projectId.isEmpty) return;

        try {
          final creatorId = _stringValue(project, 'creator_id');

          final results = await Future.wait<dynamic>([
            ProjectEngagementService.isProjectLiked(projectId),
            ProjectEngagementService.isProjectBookmarked(projectId),
            creatorId.isEmpty
                ? Future.value(false)
                : ProjectEngagementService.isFollowingCreator(creatorId),
          ]);

          if (!mounted) return;

          setState(() {
            _likedProjects[projectId] = results[0] as bool;
            _bookmarkedProjects[projectId] = results[1] as bool;

            if (creatorId.isNotEmpty) {
              _followedCreators[creatorId] = results[2] as bool;
            }
          });
        } catch (_) {
          // Une erreur d’engagement ne doit pas bloquer Explorer.
        }
      }),
    );
  }

  Future<void> _toggleLike(Map<String, dynamic> project) async {
    final projectId = _stringValue(project, 'id');
    if (projectId.isEmpty) return;

    final previous = _likedProjects[projectId] ?? false;

    setState(() {
      _likedProjects[projectId] = !previous;
    });

    try {
      final liked = await ProjectEngagementService.toggleProjectLike(
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

  Future<void> _toggleBookmark(Map<String, dynamic> project) async {
    final projectId = _stringValue(project, 'id');
    if (projectId.isEmpty) return;

    final previous = _bookmarkedProjects[projectId] ?? false;

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

      _showError('Impossible de modifier l’enregistrement.');
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> project) async {
    final creatorId = _stringValue(project, 'creator_id');
    if (creatorId.isEmpty) return;

    final previous = _followedCreators[creatorId] ?? false;

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

      _showError('Impossible de modifier l’abonnement.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _stringValue(Map<String, dynamic> project, String key) {
    final value = project[key];
    return value?.toString().trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final hasSearch =
        _searchController.text.trim().isNotEmpty ||
        _selectedCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          if (hasSearch)
            IconButton(
              tooltip: 'Réinitialiser',
              onPressed: () async {
                _searchController.clear();
                setState(() {
                  _selectedCategory = null;
                });
                await _loadPopularProjects();
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _searchProjects,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchProjects(),
                decoration: InputDecoration(
                  hintText: 'Rechercher un projet ou un créateur...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Effacer',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text(
                'Catégories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final selected = _selectedCategory == category;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) async {
                      setState(() {
                        _selectedCategory = selected ? null : category;
                      });
                      await _searchProjects();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasSearch ? 'Résultats' : 'Projets populaires',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_searching || _loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null) _buildErrorState(),
              if (_error == null && _loading) _buildLoadingState(),
              if (_error == null && !_loading && _projects.isEmpty)
                _buildEmptyState(hasSearch),
              if (_error == null && !_loading)
                ..._projects.map(_buildProjectCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final projectId = _stringValue(project, 'id');
    final creatorId = _stringValue(project, 'creator_id');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TchakaProjectCard(
        project: project,
        liked: _likedProjects[projectId] ?? false,
        bookmarked: _bookmarkedProjects[projectId] ?? false,
        followed: creatorId.isNotEmpty
            ? (_followedCreators[creatorId] ?? false)
            : false,
        onLike: () => _toggleLike(project),
        onBookmark: () => _toggleBookmark(project),
        onFollow: () => _toggleFollow(project),
        onTap: projectId.isEmpty
            ? null
            : () => context.push('/projects/$projectId'),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState(bool hasSearch) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.explore_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch
                  ? 'Aucun projet trouvé'
                  : 'Aucun projet populaire pour le moment',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Essaie un autre mot-clé ou une autre catégorie.'
                  : 'Les projets publiés apparaîtront ici dès qu’ils seront disponibles.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _searchProjects,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
