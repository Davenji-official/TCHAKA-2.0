import 'package:flutter/material.dart';

import '../data/project_engagement_service.dart';
import '../data/project_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState
    extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _project;

  bool _loading = true;
  bool _error = false;

  bool _liked = false;
  bool _bookmarked = false;

  bool _likeLoading = false;
  bool _bookmarkLoading = false;

  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 350,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadProject();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final project =
          await ProjectService.getProject(
        widget.projectId,
      );

      final liked =
          await ProjectEngagementService
              .isProjectLiked(
        widget.projectId,
      );

      final bookmarked =
          await ProjectEngagementService
              .isProjectBookmarked(
        widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _project = project;
        _liked = liked;
        _bookmarked = bookmarked;
        _loading = false;
      });

      _animationController.forward();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;

    setState(() {
      _likeLoading = true;
    });

    try {
      final liked =
          await ProjectEngagementService
              .toggleProjectLike(
        projectId: widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _liked = liked;
        _likeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _likeLoading = false;
      });

      _showMessage(
        'Connecte-toi pour aimer ce projet.',
      );
    }
  }
  Future<void> _toggleBookmark() async {
    if (_bookmarkLoading) return;

    setState(() {
      _bookmarkLoading = true;
    });

    try {
      final bookmarked =
          await ProjectEngagementService
              .toggleProjectBookmark(
        projectId: widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _bookmarked = bookmarked;
        _bookmarkLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _bookmarkLoading = false;
      });

      _showMessage(
        'Connecte-toi pour enregistrer ce projet.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? _buildLoading()
          : _error
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Projet'),
          leading: IconButton(
            onPressed: () =>
                Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _skeleton(
                height: 220,
                radius: 24,
              ),
              const SizedBox(height: 20),
              _skeleton(
                height: 24,
                width: 180,
              ),
              const SizedBox(height: 12),
              _skeleton(
                height: 18,
                width: 120,
              ),
              const SizedBox(height: 24),
              _skeleton(
                height: 100,
              ),
              const SizedBox(height: 24),
              _skeleton(
                height: 54,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _skeleton({
    required double height,
    double? width,
    double radius = 14,
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger ce projet.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadProject,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildContent() {
    final project = _project!;

    final title =
        project['title']?.toString() ??
            'Projet sans titre';

    final description =
        project['description']?.toString();

    final category =
        project['category']?.toString();

    final coverImageUrl =
        project['cover_image_url']?.toString();

    final status =
        project['status']?.toString();

    final country =
        project['country']?.toString();

    final city =
        project['city']?.toString();

    final teamSize =
        project['team_size'];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              stretch: true,
              leading: IconButton(
                onPressed: () =>
                    Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    _showMessage(
                      'Partage bientôt disponible.',
                    );
                  },
                  icon: const Icon(
                    Icons.more_vert,
                  ),
                ),
              ],
              flexibleSpace:
                  FlexibleSpaceBar(
                background:
                    _buildCover(
                  coverImageUrl,
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                40,
              ),
              sliver: SliverList(
                delegate:
                    SliverChildListDelegate([
                  _buildStatus(status),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                        ),
                  ),
                  if (category != null &&
                      category.trim().isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 12,
                      ),
                      child: Align(
                        alignment:
                            Alignment.centerLeft,
                        child: Chip(
                          label: Text(
                            category,
                          ),
                        ),
                      ),
                    ),
                  if (country != null ||
                      city != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          [
                            if (city != null &&
                                city
                                    .trim()
                                    .isNotEmpty)
                              city,
                            if (country != null &&
                                country
                                    .trim()
                                    .isNotEmpty)
                              country,
                          ].join(' · '),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildActionBar(),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    'À propos du projet',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description?.trim()
                                .isNotEmpty ==
                            true
                        ? description!
                        : 'Aucune description '
                          'disponible pour le moment.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          height: 1.55,
                        ),
                  ),
                  const SizedBox(height: 28),
                  _buildTeamInfo(teamSize),
                  const SizedBox(height: 28),
                  _buildCollaborateButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(
    String? imageUrl,
  ) {
    if (imageUrl == null ||
        imageUrl.trim().isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Icon(
            Icons.rocket_launch_outlined,
            size: 64,
            color: const Color(0xFFFFD54A),
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Color(0xFFFFD54A),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatus(
    String? status,
  ) {
    final published =
        status == 'published';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          published
              ? Icons.check_circle
              : Icons.circle_outlined,
          size: 17,
          color: published
              ? const Color(0xFFFFD54A)
              : Theme.of(context)
                  .colorScheme
                  .secondary,
        ),
        const SizedBox(width: 6),
        Text(
          published
              ? 'PROJET PUBLIÉ'
              : 'PROJET',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
    Widget _buildActionBar() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: _liked
                ? Icons.favorite
                : Icons.favorite_border,
            label: _liked
                ? 'Aimé'
                : 'J’aime',
            active: _liked,
            loading: _likeLoading,
            onPressed: _toggleLike,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            icon: _bookmarked
                ? Icons.bookmark
                : Icons.bookmark_border,
            label: _bookmarked
                ? 'Enregistré'
                : 'Enregistrer',
            active: _bookmarked,
            loading: _bookmarkLoading,
            onPressed: _toggleBookmark,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool active,
    required bool loading,
    required VoidCallback onPressed,
  }) {
    final color = active
        ? const Color(0xFFFFD54A)
        : Theme.of(context)
            .colorScheme
            .onSurface;

    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 180),
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Icon(
                icon,
                color: color,
              ),
        label: Text(label),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }

  Widget _buildTeamInfo(
    dynamic teamSize,
  ) {
    final count = teamSize is num
        ? teamSize.toInt()
        : 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: Color(0xFFFFD54A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Équipe',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$count membre${count > 1 ? 's' : ''}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          _showMessage(
            'La collaboration sera activée '
            'dans le prochain bloc.',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFFFD54A),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(
          Icons.handshake_outlined,
        ),
        label: const Text(
          'Collaborer',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
