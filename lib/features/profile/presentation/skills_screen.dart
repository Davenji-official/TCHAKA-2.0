import 'package:flutter/material.dart';

import '../data/skill_service.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _mySkills = [];
  List<Map<String, dynamic>> _searchResults = [];

  bool _loading = true;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMySkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMySkills() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final skills = await SkillService.getMySkills();

      if (!mounted) return;

      setState(() {
        _mySkills = skills;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger tes compétences.';
      });
    }
  }

  Future<void> _searchSkills(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      final results = await SkillService.searchSkills(normalizedQuery);

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _searchResults = [];
        _searching = false;
      });
    }
  }

  bool _alreadyHasSkill(String skillId) {
    return _mySkills.any(
      (item) => item['skill_id']?.toString() == skillId,
    );
  }

  Future<void> _addSkill(Map<String, dynamic> skill) async {
    final skillId = skill['id']?.toString();

    if (skillId == null || _alreadyHasSkill(skillId)) {
      return;
    }

    try {
      await SkillService.addSkill(
        skillId: skillId,
        proficiency: 3,
      );

      if (!mounted) return;

      _searchController.clear();

      setState(() {
        _searchResults = [];
      });

      await _loadMySkills();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${skill['name'] ?? 'Compétence'} ajoutée.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’ajouter cette compétence.',
          ),
        ),
      );
    }
  }

  Future<void> _changeProficiency(
    Map<String, dynamic> skill,
    int proficiency,
  ) async {
    final skillId = skill['skill_id']?.toString();

    if (skillId == null) return;

    try {
      await SkillService.updateProficiency(
        skillId: skillId,
        proficiency: proficiency,
      );

      if (!mounted) return;

      setState(() {
        final index = _mySkills.indexOf(skill);

        if (index != -1) {
          _mySkills[index] = {
            ..._mySkills[index],
            'proficiency': proficiency,
          };
        }
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de modifier le niveau.',
          ),
        ),
      );
    }
  }

  Future<void> _removeSkill(Map<String, dynamic> skill) async {
    final skillId = skill['skill_id']?.toString();

    if (skillId == null) return;

    final skillData = skill['skills'];

    final skillName = skillData is Map<String, dynamic>
        ? skillData['name']?.toString() ?? 'cette compétence'
        : 'cette compétence';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la compétence ?'),
          content: Text(
            'Veux-tu supprimer « $skillName » de ton profil ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await SkillService.removeSkill(
        skillId: skillId,
      );

      if (!mounted) return;

      setState(() {
        _mySkills.remove(skill);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '« $skillName » supprimée.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de supprimer cette compétence.',
          ),
        ),
      );
    }
  }

  String _skillName(Map<String, dynamic> skill) {
    final data = skill['skills'];

    if (data is Map<String, dynamic>) {
      return data['name']?.toString() ?? 'Compétence';
    }

    return 'Compétence';
  }

  String? _skillCategory(Map<String, dynamic> skill) {
    final data = skill['skills'];

    if (data is Map<String, dynamic>) {
      final category = data['category']?.toString();

      if (category != null && category.trim().isNotEmpty) {
        return category;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes compétences'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMySkills,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _buildIntro(),
            const SizedBox(height: 24),
            _buildSearch(),
            if (_searchController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSearchResults(),
            ],
            const SizedBox(height: 28),
            _buildMySkills(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tes compétences',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoute les compétences que tu maîtrises. '
          'Elles aideront TCHAKA à te proposer des projets '
          'et des collaborateurs pertinents.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: _searchSkills,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Ajouter une compétence',
        hintText: 'Ex. Flutter, Python, Design...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchResults = [];
                  });
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aucune compétence trouvée.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Card(
      child: Column(
        children: _searchResults.map((skill) {
          final skillId = skill['id']?.toString();
          final alreadyAdded =
              skillId != null && _alreadyHasSkill(skillId);

          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.auto_awesome),
            ),
            title: Text(
              skill['name']?.toString() ?? 'Compétence',
            ),
            subtitle: skill['category'] != null
                ? Text(
                    skill['category'].toString(),
                  )
                : null,
            trailing: alreadyAdded
                ? const Icon(
                    Icons.check_circle,
                  )
                : IconButton(
                    onPressed: () => _addSkill(skill),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMySkills() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadMySkills,
            child: const Text('Réessayer'),
          ),
        ],
      );
    }

    if (_mySkills.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune compétence pour le moment.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Utilise la recherche ci-dessus pour ajouter '
                'tes premières compétences.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes compétences (${_mySkills.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ..._mySkills.map(_buildSkillCard),
      ],
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skill) {
    final proficiency = ((skill['proficiency'] as num?) ?? 1).toInt();
    final category = _skillCategory(skill);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    _skillName(skill).isNotEmpty
                        ? _skillName(skill)[0].toUpperCase()
                        : '?',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _skillName(skill),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                      if (category != null)
                        Text(
                          category,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _removeSkill(skill);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Maîtrise',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '$proficiency/5',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (index) {
                  final level = index + 1;

                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: '$level/5',
                    onPressed: () {
                      _changeProficiency(
                        skill,
                        level,
                      );
                    },
                    icon: Icon(
                      level <= proficiency
                          ? Icons.star
                          : Icons.star_border,
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
}
