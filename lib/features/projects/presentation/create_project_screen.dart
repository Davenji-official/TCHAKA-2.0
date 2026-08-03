import 'package:flutter/material.dart';

import '../data/project_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  static const List<String> _categories = [
    'Technologie',
    'Éducation',
    'Santé',
    'Agriculture',
    'Finance',
    'Commerce',
    'Environnement',
    'Culture',
    'Art',
    'Jeunesse',
    'Autre',
  ];

  String? _category;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final project = await ProjectService.createProject(
        title: _titleController.text,
        description: _descriptionController.text,
        problemStatement: _problemController.text,
        solutionDescription: _solutionController.text,
        category: _category,
        country: _countryController.text,
        city: _cityController.text,
        status: 'draft',
        visibility: 'public',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Projet enregistré comme brouillon.'),
        ),
      );

      Navigator.of(context).pop(project);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _errorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString();

    if (message.contains('duplicate') ||
        message.contains('unique') ||
        message.contains('23505')) {
      return 'Un problème est survenu avec ce projet. Réessaie avec un autre titre.';
    }

    if (message.contains('JWT') ||
        message.contains('auth') ||
        message.contains('connecté')) {
      return 'Ta session a expiré. Reconnecte-toi puis réessaie.';
    }

    return 'Impossible de créer le projet. Vérifie les informations puis réessaie.';
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un projet'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text(
                'Donne vie à ton idée.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Présente ton projet à la communauté TCHAKA.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              _sectionTitle(
                'Présentation',
                subtitle: 'Les informations principales de ton projet.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                maxLength: 150,
                decoration: _inputDecoration(
                  label: 'Titre du projet',
                  hint: 'Ex. Mon application mobile',
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';

                  if (title.isEmpty) {
                    return 'Le titre est obligatoire.';
                  }

                  if (title.length < 3) {
                    return 'Minimum 3 caractères.';
                  }

                  if (title.length > 150) {
                    return 'Maximum 150 caractères.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  label: 'Description',
                  hint: 'Décris ton projet en quelques mots...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration(
                  label: 'Catégorie',
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _category = value;
                        });
                      },
              ),
              const SizedBox(height: 32),
              _sectionTitle(
                'Ton idée',
                subtitle: 'Aide les autres à comprendre la valeur du projet.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _problemController,
                maxLines: 4,
                maxLength: 1500,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  label: 'Quel problème veux-tu résoudre ?',
                  hint: 'Explique le problème...',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _solutionController,
                maxLines: 4,
                maxLength: 1500,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  label: 'Quelle est ta solution ?',
                  hint: 'Explique comment ton projet répond au problème...',
                ),
              ),
              const SizedBox(height: 32),
              _sectionTitle(
                'Localisation',
                subtitle: 'Indique où ton projet est principalement développé.',
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        label: 'Pays',
                        hint: 'Haïti',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      textInputAction: TextInputAction.done,
                      decoration: _inputDecoration(
                        label: 'Ville',
                        hint: 'Delmas',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _createProject,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'Enregistrement...'
                      : 'Enregistrer le brouillon',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
