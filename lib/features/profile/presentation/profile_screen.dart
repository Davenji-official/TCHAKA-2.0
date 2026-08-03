import 'package:flutter/material.dart';

import '../data/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getCurrentProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Impossible de charger ton profil.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon profil'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final profile = _profile;

    if (profile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Profil introuvable.'),
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        size: 48,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    fullName?.isNotEmpty == true
                        ? fullName!
                        : 'Utilisateur TCHAKA',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    size: 20,
                  ),
                ],
                if (isPremium) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.workspace_premium,
                    size: 20,
                  ),
                ],
              ],
            ),
            if (username?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                '@$username',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (bio?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                bio!,
                textAlign: TextAlign.center,
              ),
            ],
            if (country?.isNotEmpty == true || city?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                [
                  if (country?.isNotEmpty == true) country!,
                  if (city?.isNotEmpty == true) city!,
                ].join(' · '),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier mon profil'),
            ),
            const SizedBox(height: 32),
            Text(
              'Mes projets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aucun projet pour le moment',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tes futurs projets et créations apparaîtront ici.',
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
}
