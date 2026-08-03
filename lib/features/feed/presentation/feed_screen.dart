import 'package:flutter/material.dart';

import '../data/feed_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<Map<String, dynamic>> _projects = [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _offset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
    });

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
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger le fil TCHAKA.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || _projects.length < _offset) {
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
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCHAKA'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: _projects.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _projects.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _ProjectCard(
            project: _projects[index],
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _loadingCard(),
        const SizedBox(height: 16),
        _loadingCard(),
        const SizedBox(height: 16),
        _loadingCard(),
      ],
    );
  }

  Widget _loadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _loadingLine(width: 150),
            const SizedBox(height: 12),
            _loadingLine(width: 100),
            const SizedBox(height: 20),
            _loadingBox(height: 180),
            const SizedBox(height: 16),
            _loadingLine(width: double.infinity),
            const SizedBox(height: 8),
            _loadingLine(width: 220),
          ],
        ),
      ),
    );
  }

  Widget _loadingLine({required double width}) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
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
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: _loadFeed,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
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
        const SizedBox(height: 120),
        Icon(
          Icons.auto_awesome_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          'Ton Feed est encore calme.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Les nouveaux projets apparaîtront ici.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
  });

  final Map<String, dynamic> project;

  @override
  Widget build(BuildContext context) {
    final title = project['title'] as String? ?? 'Projet sans titre';
    final description = project['description'] as String? ?? '';
    final category = project['category'] as String?;
    final country = project['country'] as String?;
    final city = project['city'] as String?;
    final coverImageUrl = project['cover_image_url'] as String?;
    final likesCount = project['likes_count'] ?? 0;
    final commentsCount = project['comments_count'] ?? 0;

    final location = [
      if (country?.trim().isNotEmpty == true) country!,
      if (city?.trim().isNotEmpty == true) city!,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline),
            ),
            title: const Text('Créateur TCHAKA'),
            subtitle: Text(
              location.isNotEmpty
                  ? location
                  : category ?? 'Projet',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (coverImageUrl?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                ),
                Text('$likesCount'),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text('$commentsCount'),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
