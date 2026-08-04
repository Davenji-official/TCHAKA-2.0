import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../projects/data/project_engagement_service.dart';
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({
    super.key,
    this.userId,
  });

  final String? userId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic>? _profile;

  bool _loading = true;
  bool _following = false;
  bool _followLoading = false;

  String? _error;

  String? get _profileId => widget.userId ?? _client.auth.currentUser?.id;

  bool get _isOwnProfile {
    final currentUserId = _client.auth.currentUser?.id;
    return currentUserId != null &&
        _profileId != null &&
        currentUserId == _profileId;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profileId = _profileId;

      if (profileId == null) {
        throw Exception('Utilisateur non connecté.');
      }

      final response = await _client
          .from('public_profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _profile = null;
          _loading = false;
        });
        return;
      }

      var following = false;

      if (!_isOwnProfile) {
        following = await ProjectEngagementService.isFollowingCreator(
          profileId,
        );
      }

      if (!mounted) return;

      setState(() {
        _profile = response;
        _following = following;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger ce profil.';
      });
    }
  }

  Future<void> _toggleFollow() async {
    final profileId = _profileId;

    if (profileId == null || _isOwnProfile || _followLoading) {
      return;
    }

    setState(() {
      _followLoading = true;
    });

    try {
      final following = await ProjectEngagementService.toggleCreatorFollow(
        creatorId: profileId,
      );

      if (!mounted) return;

      setState(() {
        _following = following;
        _followLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _followLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de modifier le suivi.'),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildProfile(),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Center(
          child: CircleAvatar(
            radius: 52,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _loadingLine(width: 180),
        const SizedBox(height: 12),
        _loadingLine(width: 120),
        const SizedBox(height: 24),
        _loadingBox(height: 80),
        const SizedBox(height: 24),
        _loadingBox(height: 56),
      ],
    );
  }

  Widget _loadingLine({required double width}) {
    return Center(
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _loadingBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
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
          Icons.cloud_off_outlined,
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
        Center(
          child: FilledButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    final profile = _profile;

    if (profile == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.person_off_outlined,
            size: 56,
          ),
          SizedBox(height: 16),
          Text(
            'Profil introuvable.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final username = profile['username'] as String?;
    final fullName = profile['full_name'] as String?;
    final avatarUrl = profile['avatar_url'] as String?;
    final bio = profile['bio'] as String?;
    final country = profile['country'] as String?;
    final city = profile['city'] as String?;
    final isVerified = profile['is_verified'] == true;
    final isPremium = profile['is_premium'] == true;

    final displayName = fullName?.trim().isNotEmpty == true
        ? fullName!
        : 'Utilisateur TCHAKA';

    final hasLocation =
        country?.trim().isNotEmpty == true ||
        city?.trim().isNotEmpty == true;

    final location = [
      if (country?.trim().isNotEmpty == true) country!,
      if (city?.trim().isNotEmpty == true) city!,
    ].join(' · ');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      children: [
        Center(
          child: CircleAvatar(
            radius: 58,
            backgroundImage: avatarUrl?.trim().isNotEmpty == true
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl?.trim().isNotEmpty != true
                ? const Icon(
                    Icons.person_outline,
                    size: 52,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.verified,
                size: 21,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
            if (isPremium) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.workspace_premium,
                size: 21,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ],
        ),
        if (username?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            '@${username!.trim()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (bio?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 18),
          Text(
            bio!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        if (hasLocation) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  location,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        if (!_isOwnProfile)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _followLoading ? null : _toggleFollow,
                  icon: _followLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _following
                              ? Icons.person_remove_alt_1
                              : Icons.person_add_alt_1,
                        ),
                  label: Text(
                    _following ? 'Ne plus suivre' : 'Suivre',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Partager'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 36),
        Text(
          'Publications',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Les publications arrivent bientôt.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Les créations de cet utilisateur apparaîtront ici.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
