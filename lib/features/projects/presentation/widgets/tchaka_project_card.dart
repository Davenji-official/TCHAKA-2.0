import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class TchakaProjectCard extends StatefulWidget {
  const TchakaProjectCard({
    super.key,
    required this.project,
    required this.liked,
    required this.bookmarked,
    required this.followed,
    required this.onLike,
    required this.onBookmark,
    required this.onFollow,
    this.onTap,
  });

  final Map<String, dynamic> project;
  final bool liked;
  final bool bookmarked;
  final bool followed;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onFollow;
  final VoidCallback? onTap;

  @override
  State<TchakaProjectCard> createState() =>
      _TchakaProjectCardState();
}

class _TchakaProjectCardState
    extends State<TchakaProjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _likeController;

  @override
  void initState() {
    super.initState();

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  String _stringValue(
    String key, [
    String fallback = '',
  ]) {
    final value = widget.project[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  int _intValue(String key) {
    final value = widget.project[key];

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
    final value = widget.project[key];

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

    final imageUrl = _stringValue(
      'cover_image_url',
    );

    final category = _stringValue(
      'category',
      'Projet',
    );

    final likes = _intValue(
      'likes_count',
    );

    final comments = _intValue(
      'comments_count',
    );

    final followers = _intValue(
      'followers_count',
    );

    final matchingSkills = _intValue(
      'matching_skills_count',
    );

    final score = _doubleValue(
      'feed_score',
    );

    final impactScore = _doubleValue(
      'impact_score',
    );

    final creatorId = _stringValue(
      'creator_id',
    );

    return Card(
  margin: const EdgeInsets.only(
    bottom: 20,
  ),
  elevation: 0,
  color: TchakaTheme.surface,
  clipBehavior: Clip.antiAlias,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(
      TchakaTheme.radiusLarge,
    ),
    side: BorderSide(
      color: Colors.white.withValues(
        alpha: 0.06,
      ),
    ),
  ),
  child: InkWell(
    onTap: widget.onTap,
    borderRadius: BorderRadius.circular(
      TchakaTheme.radiusLarge,
    ),
    child: Column(
              ],
      ),
    ),
  ),
);
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildCover(
            context,
            imageUrl,
          ),
          _buildContent(
            context,
            title: title,
            description: description,
            category: category,
            likes: likes,
            comments: comments,
            followers: followers,
            matchingSkills: matchingSkills,
            score: score,
            impactScore: impactScore,
            creatorId: creatorId,
          ),
        ],
      ),
    );
  }
    Widget _buildCover(
    BuildContext context,
    String imageUrl,
  ) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const
                        _TchakaProjectPlaceholder();
                  },
                )
              : const _TchakaProjectPlaceholder(),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: 0.65,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 14,
          left: 14,
          child: _buildCategoryBadge(
            context,
          ),
        ),

        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            tooltip: widget.bookmarked
                ? 'Retirer des favoris'
                : 'Enregistrer',
            onPressed: widget.onBookmark,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(
                alpha: 0.55,
              ),
              foregroundColor:
                  widget.bookmarked
                      ? TchakaTheme.tchakaYellow
                      : Colors.white,
            ),
            icon: Icon(
              widget.bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ),

        Positioned(
          left: 14,
          bottom: 14,
          child: _buildDiscoveryBadge(
            context,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(
    BuildContext context,
  ) {
    final category = _stringValue(
      'category',
      'Projet',
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: TchakaTheme.tchakaYellow,
        borderRadius: BorderRadius.circular(
          30,
        ),
        boxShadow: [
          BoxShadow(
            color: TchakaTheme.tchakaYellow
                .withValues(
              alpha: 0.22,
            ),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDiscoveryBadge(
    BuildContext context,
  ) {
    final score = _doubleValue(
      'feed_score',
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.68,
        ),
        borderRadius: BorderRadius.circular(
          30,
        ),
        border: Border.all(
          color: TchakaTheme.tchakaYellow
              .withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.trending_up_rounded,
            size: 15,
            color: TchakaTheme.tchakaYellow,
          ),
          const SizedBox(width: 5),
          Text(
            score > 0
                ? 'Discovery ${score.toStringAsFixed(1)}'
                : 'À découvrir',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required String title,
    required String description,
    required String category,
    required int likes,
    required int comments,
    required int followers,
    required int matchingSkills,
    required double score,
    required double impactScore,
    required String creatorId,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: TchakaTheme.textPrimary,
                ),
          ),

          const SizedBox(height: 9),

          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: TchakaTheme.textSecondary,
                  height: 1.45,
                ),
          ),

          const SizedBox(height: 16),

          if (matchingSkills > 0)
            _buildMatchingSkills(
              context,
              matchingSkills,
            ),

          if (impactScore > 0)
            _buildImpactRow(
              context,
              impactScore,
            ),

          const SizedBox(height: 16),

          _buildStats(
            context,
            likes: likes,
            comments: comments,
            followers: followers,
          ),

          const SizedBox(height: 18),

          _buildActions(
            context,
            creatorId,
          ),
        ],
      ),
    );
  }
    Widget _buildMatchingSkills(
    BuildContext context,
    int matchingSkills,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: TchakaTheme.tchakaYellow
            .withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: TchakaTheme.tchakaYellow
              .withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 17,
            color: TchakaTheme.tchakaYellow,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '$matchingSkills compétence'
              '${matchingSkills > 1 ? 's' : ''} '
              'correspondante'
              '${matchingSkills > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow(
    BuildContext context,
    double impactScore,
  ) {
    final percentage =
        impactScore.clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.only(
        top: 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                size: 17,
                color: TchakaTheme.tchakaYellow,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Impact TCHAKA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color:
                      TchakaTheme.tchakaYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 5,
              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.08,
              ),
              valueColor:
                  const AlwaysStoppedAnimation(
                TchakaTheme.tchakaYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context, {
    required int likes,
    required int comments,
    required int followers,
  }) {
    return Row(
      children: [
        _buildStat(
          icon: widget.liked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          value: likes,
          active: widget.liked,
        ),
        const SizedBox(width: 18),
        _buildStat(
          icon: Icons.chat_bubble_outline_rounded,
          value: comments,
        ),
        const SizedBox(width: 18),
        _buildStat(
          icon: Icons.people_outline_rounded,
          value: followers,
        ),
      ],
    );
  }

  Widget _buildStat({
    required IconData icon,
    required int value,
    bool active = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: active
              ? TchakaTheme.tchakaYellow
              : TchakaTheme.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          _formatCount(value),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: TchakaTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    String creatorId,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildLikeButton(
            context,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: widget.followed
              ? FilledButton.icon(
                  onPressed: creatorId.isEmpty
                      ? null
                      : widget.onFollow,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        TchakaTheme.tchakaYellow,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(
                    Icons.person_rounded,
                  ),
                  label: const Text(
                    'Suivi',
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: creatorId.isEmpty
                      ? null
                      : widget.onFollow,
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                  ),
                  label: const Text(
                    'Suivre',
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLikeButton(
    BuildContext context,
  ) {
    return OutlinedButton.icon(
      onPressed: () {
        if (!widget.liked) {
          _likeController.forward(
            from: 0,
          );
        }

        widget.onLike();
      },
      icon: ScaleTransition(
        scale: Tween<double>(
          begin: 1,
          end: 1.28,
        ).animate(
          CurvedAnimation(
            parent: _likeController,
            curve: Curves.easeOutBack,
          ),
        ),
        child: Icon(
          widget.liked
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
        ),
      ),
      label: Text(
        widget.liked
            ? 'Aimé'
            : 'J’aime',
      ),
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toString();
  }
}

class _TchakaProjectPlaceholder
    extends StatelessWidget {
  const _TchakaProjectPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF080808),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: TchakaTheme.tchakaYellow
                .withValues(
              alpha: 0.10,
            ),
            border: Border.all(
              color: TchakaTheme.tchakaYellow
                  .withValues(
                alpha: 0.30,
              ),
            ),
          ),
          child: const Icon(
            Icons.rocket_launch_rounded,
            size: 30,
            color: TchakaTheme.tchakaYellow,
          ),
        ),
      ),
    );
  }
}
