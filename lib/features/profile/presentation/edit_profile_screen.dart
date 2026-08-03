import 'package:flutter/material.dart';

import '../data/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _bioController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _avatarUrlController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getCurrentProfile();

      if (!mounted) return;

      if (profile != null) {
        _usernameController.text =
            profile['username'] as String? ?? '';
        _fullNameController.text =
            profile['full_name'] as String? ?? '';
        _avatarUrlController.text =
            profile['avatar_url'] as String? ?? '';
        _bioController.text =
            profile['bio'] as String? ?? '';
        _countryController.text =
            profile['country'] as String? ?? '';
        _cityController.text =
            profile['city'] as String? ?? '';
      }

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Impossible de charger ton profil.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      await ProfileService.updateProfile(
        username: _usernameController.text,
        fullName: _fullNameController.text,
        avatarUrl: _avatarUrlController.text,
        bio: _bioController.text,
        country: _countryController.text,
        city: _cityController.text,
      );

      if (!mounted) return;

      setState(() {
        _success = 'Profil mis à jour.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Impossible de sauvegarder ton profil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: AppBar(
          title: Text('Modifier mon profil'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 52,
                  child: Icon(
                    Icons.person_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Nom complet'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Nom d’utilisateur'),
                validator: (value) {
                  final username = value?.trim() ?? '';

                  if (username.isEmpty) {
                    return null;
                  }

                  if (username.length < 3) {
                    return 'Minimum 3 caractères.';
                  }

                  if (username.length > 30) {
                    return 'Maximum 30 caractères.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 160,
                decoration: _decoration('Bio'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: _decoration('URL de la photo de profil'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                textInputAction: TextInputAction.next,
                decoration: _decoration('Pays'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.done,
                decoration: _decoration('Ville'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 16),
                Text(
                  _success!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _saveProfile,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Sauvegarder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

