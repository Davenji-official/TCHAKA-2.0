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
      duration: const Duration(milliseconds: 450),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.035),
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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }

    try {
      final project = await ProjectService.getProject(
        widget.projectId,
      );

      final liked =
          await ProjectEngagementService.isProjectLiked(
        widget.projectId,
      );

      final bookmarked =
          await ProjectEngagementService.isProjectBookmarked(
        widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _project = project;
        _liked = liked;
        _bookmarked = bookmarked;
        _loading = false;
      });

      _animationController
        ..reset()
        ..forward();
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
          await ProjectEngagementService.toggleProjectLike(
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
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _skeleton(
                height: 230,
                radius: 24,
              ),
              const SizedBox(height: 20),
              _skeleton(
                height: 24,
                width: 210,
              ),
              const SizedBox(height: 12),
              _skeleton(
                height: 18,
                width: 130,
              ),
              const SizedBox(height: 24),
              _skeleton(height: 100),
              const SizedBox(height: 18),
              _skeleton(height: 100),
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
        borderRadius: BorderRadius.circular(radius),
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFFFD54A),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Impossible de charger ce projet.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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

    final problem =
        project['problem_statement']?.toString();

    final solution =
        project['solution_description']?.toString();

    final category =
        project['category']?.toString();

    final coverImageUrl =
        project['cover_image_url']?.toString();

    final status =
        project['status']?.toString();

    final visibility =
        project['visibility']?.toString();

    final country =
        project['country']?.toString();

    final city =
        project['city']?.toString();

    final teamSize =
        project['team_size'];

    final fundingGoal =
        project['funding_goal'];

    final fundingCurrency =
        project['funding_currency']?.toString();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics:
              const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(
              title,
              coverImageUrl,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                48,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatus(status),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w900,
                          height: 1.1,
                        ),
                  ),
                  if (category != null &&
                      category.trim().isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 14,
                      ),
                      child: Align(
                        alignment:
                            Alignment.centerLeft,
                        child: _buildCategory(
                          category,
                        ),
                      ),
                    ),
                  if (country != null ||
                      city != null)
                    _buildLocation(
                      city,
                      country,
                    ),
                  const SizedBox(height: 24),
                  _buildActionBar(),
                  const SizedBox(height: 34),
                  _buildSectionTitle(
                    'À propos du projet',
                  ),
                  const SizedBox(height: 10),
                  _buildTextBlock(
                    description,
                    'Aucune description disponible '
                    'pour le moment.',
                  ),
                  if (problem != null &&
                      problem.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      'Le problème',
                    ),
                    const SizedBox(height: 10),
                    _buildTextBlock(
                      problem,
                      'Aucun problème renseigné.',
                    ),
                  ],
                  if (solution != null &&
                      solution.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                      'La solution',
                    ),
                    const SizedBox(height: 10),
                    _buildTextBlock(
                      solution,
                      'Aucune solution renseignée.',
                    ),
                  ],
                  const SizedBox(height: 28),
                  _buildProjectStats(
                    teamSize,
                    visibility,
                  ),
                  if (fundingGoal != null) ...[
                    const SizedBox(height: 18),
                    _buildFundingCard(
                      fundingGoal,
                      fundingCurrency,
                    ),
                  ],
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
    Widget _buildAppBar(
    String title,
    String? imageUrl,
  ) {
    return SliverAppBar(
      expandedHeight: 270,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          onPressed: () {
            _showMessage(
              'Le partage sera ajouté prochainement.',
            );
          },
          icon: const Icon(
            Icons.share_outlined,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsetsDirectional.only(
          start: 56,
          bottom: 16,
          end: 56,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildCover(imageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: 0.12,
                    ),
                    Colors.black.withValues(
                      alpha: 0.75,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(String? imageUrl) {
    if (imageUrl == null ||
        imageUrl.trim().isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.rocket_launch_outlined,
            size: 68,
            color: Color(0xFFFFD54A),
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
              size: 52,
              color: Color(0xFFFFD54A),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatus(String? status) {
    final published =
        status?.toLowerCase() == 'published';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD54A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD54A)
                    .withValues(alpha: 0.45),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          published
              ? 'PROJET PUBLIÉ'
              : 'PROJET',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
        ),
      ],
    );
  }

  Widget _buildCategory(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54A),
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLocation(
    String? city,
    String? country,
  ) {
    final parts = <String>[];

    if (city != null &&
        city.trim().isNotEmpty) {
      parts.add(city.trim());
    }

    if (country != null &&
        country.trim().isNotEmpty) {
      parts.add(country.trim());
    }

    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 18,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              parts.join(' · '),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ),
        ],
      ),
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
    final yellow =
        const Color(0xFFFFD54A);

    return AnimatedContainer(
      duration:
          const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: OutlinedButton.icon(
        onPressed:
            loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
          side: BorderSide(
            color: active
                ? yellow
                : Theme.of(context)
                    .colorScheme
                    .outline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
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
                color: active
                    ? yellow
                    : null,
              ),
        label: Text(label),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 23,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD54A),
            borderRadius:
                BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextBlock(
    String? value,
    String fallback,
  ) {
    final hasValue =
        value?.trim().isNotEmpty == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Text(
        hasValue ? value!.trim() : fallback,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(
              height: 1.6,
            ),
      ),
    );
  }

  Widget _buildProjectStats(
    dynamic teamSize,
    String? visibility,
  ) {
    final count = teamSize is num
        ? teamSize.toInt()
        : 1;

    final publicProject =
        visibility?.toLowerCase() == 'public';

    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.groups_outlined,
            title: 'Équipe',
            value:
                '$count membre${count > 1 ? 's' : ''}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: publicProject
                ? Icons.public
                : Icons.lock_outline,
            title: 'Visibilité',
            value: publicProject
                ? 'Public'
                : 'Privé',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFD54A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
    Widget _buildFundingCard(
    dynamic fundingGoal,
    String? currency,
  ) {
    double? amount;

    if (fundingGoal is num) {
      amount = fundingGoal.toDouble();
    } else {
      amount = double.tryParse(
        fundingGoal.toString(),
      );
    }

    if (amount == null) {
      return const SizedBox.shrink();
    }

    final formatted =
        amount.toStringAsFixed(2);

    final currencyLabel =
        currency?.trim().isNotEmpty == true
            ? currency!.trim().toUpperCase()
            : 'USD';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54A),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Objectif de financement',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formatted $currencyLabel',
                  style: const TextStyle(
                    color: Color(0xFFFFD54A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
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
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () {
          _showMessage(
            'La collaboration sera activée '
            'dans le module de collaboration.',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFFFD54A),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(17),
          ),
        ),
        icon: const Icon(
          Icons.handshake_outlined,
        ),
        label: const Text(
          'Collaborer',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
