import 'package:flutter/material.dart';

import '../data/project_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState
    extends State<CreateProjectScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _fundingGoalController = TextEditingController();

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

  static const List<String> _currencies = [
    'USD',
    'HTG',
    'EUR',
    'CAD',
  ];

  String? _category;
  String _currency = 'USD';

  int _teamSize = 1;

  bool _saving = false;
  String? _error;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();

    _titleController.dispose();
    _descriptionController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _coverImageController.dispose();
    _fundingGoalController.dispose();

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
      final fundingText =
          _fundingGoalController.text.trim();

      final fundingGoal = fundingText.isEmpty
          ? null
          : double.tryParse(
              fundingText.replaceAll(',', '.'),
            );

      final coverImage =
          _coverImageController.text.trim();

      final project =
          await ProjectService.createProject(
        title: _titleController.text.trim(),
        description:
            _descriptionController.text.trim(),
        problemStatement:
            _problemController.text.trim(),
        solutionDescription:
            _solutionController.text.trim(),
        category: _category,
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        coverImageUrl:
            coverImage.isEmpty ? null : coverImage,
        status: 'draft',
        visibility: 'public',
        fundingGoal: fundingGoal,
        fundingCurrency: _currency,
        teamSize: _teamSize,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Projet enregistré comme brouillon.',
          ),
          behavior: SnackBarBehavior.floating,
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
    final message = error.toString().toLowerCase();

    if (message.contains('duplicate') ||
        message.contains('unique') ||
        message.contains('23505')) {
      return 'Un projet avec ces informations existe déjà. '
          'Réessaie avec un autre titre.';
    }

    if (message.contains('jwt') ||
        message.contains('auth') ||
        message.contains('connecté')) {
      return 'Ta session a expiré. '
          'Reconnecte-toi puis réessaie.';
    }

    return 'Impossible de créer le projet. '
        'Vérifie les informations puis réessaie.';
  }
    InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final yellow = const Color(0xFFFFD54A);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon),
      filled: true,
      fillColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: yellow,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    String? subtitle,
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon ?? Icons.layers_outlined,
            color: const Color(0xFFFFD54A),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  String? _requiredValidator(
    String? value, {
    int minimum = 1,
    String field = 'Ce champ',
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return '$field est obligatoire.';
    }

    if (text.length < minimum) {
      return '$field doit contenir au moins '
          '$minimum caractères.';
    }

    return null;
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: _inputDecoration(
        label: 'Catégorie',
        hint: 'Choisis une catégorie',
        icon: Icons.category_outlined,
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Choisis une catégorie.';
        }

        return null;
      },
    );
  }
    Widget _buildTeamSizeSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
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
                  'Taille de l’équipe',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Combien de personnes travaillent '
                  'sur le projet ?',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _saving || _teamSize <= 1
                ? null
                : () {
                    setState(() {
                      _teamSize--;
                    });
                  },
            icon: const Icon(
              Icons.remove_circle_outline,
            ),
          ),
          Text(
            '$_teamSize',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          IconButton(
            onPressed: _saving || _teamSize >= 100
                ? null
                : () {
                    setState(() {
                      _teamSize++;
                    });
                  },
            icon: const Icon(
              Icons.add_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyField() {
    return DropdownButtonFormField<String>(
      initialValue: _currency,
      decoration: _inputDecoration(
        label: 'Devise',
        icon: Icons.currency_exchange_outlined,
      ),
      items: _currencies
          .map(
            (currency) => DropdownMenuItem<String>(
              value: currency,
              child: Text(currency),
            ),
          )
          .toList(),
      onChanged: _saving
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                _currency = value;
              });
            },
    );
  }

  Widget _buildFundingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD54A)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54A),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Financement',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Tu peux indiquer l’objectif financier '
            'de ton projet. Ce champ est facultatif.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fundingGoalController,
            enabled: !_saving,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Objectif financier',
              hintText: 'Ex. 5000',
              prefixIcon: const Icon(
                Icons.payments_outlined,
              ),
              filled: true,
              fillColor: Colors.white.withValues(
                alpha: 0.08,
              ),
              labelStyle: const TextStyle(
                color: Colors.white70,
              ),
              hintStyle: const TextStyle(
                color: Colors.white38,
              ),
              prefixIconColor:
                  const Color(0xFFFFD54A),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFFFD54A),
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';

              if (text.isEmpty) {
                return null;
              }

              final amount = double.tryParse(
                text.replaceAll(',', '.'),
              );

              if (amount == null) {
                return 'Entre un montant valide.';
              }

              if (amount < 0) {
                return 'Le montant ne peut pas être négatif.';
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildCurrencyField(),
        ],
      ),
    );
  }
    Widget _buildCoverPreview() {
    final url =
        _coverImageController.text.trim();

    if (url.isEmpty) {
      return Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: Color(0xFFFFD54A),
              size: 46,
            ),
            SizedBox(height: 10),
            Text(
              'Ajoute une image de couverture',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        url,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            height: 190,
            color: Colors.black,
            child: const Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFFFFD54A),
                  size: 42,
                ),
                SizedBox(height: 8),
                Text(
                  'Impossible de charger cette image',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    if (_error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed:
            _saving ? null : _createProject,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFFFD54A),
          foregroundColor: Colors.black,
          disabledBackgroundColor:
              const Color(0xFFFFD54A)
                  .withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
        ),
        icon: _saving
            ? const SizedBox(
                width: 21,
                height: 21,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.black,
                ),
              )
            : const Icon(
                Icons.save_outlined,
              ),
        label: Text(
          _saving
              ? 'Enregistrement...'
              : 'Enregistrer le brouillon',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -25,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD54A)
                    .withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                  Icons.lightbulb_outline,
                  color: Colors.black,
                  size: 27,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Donne vie à ton idée.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Présente ton projet à la communauté '
                'TCHAKA et commence à construire '
                'ton équipe.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Créer un projet',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: ListView(
                physics:
                    const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  48,
                ),
                children: [
                  _buildIntro(),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    'Présentation',
                    subtitle:
                        'Les informations principales '
                        'de ton projet.',
                    icon: Icons.description_outlined,
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: _titleController,
                    label: 'Titre du projet',
                    hint:
                        'Ex. Mon application mobile',
                    icon: Icons.title_outlined,
                    maxLength: 150,
                    textInputAction:
                        TextInputAction.next,
                    validator: (value) =>
                        _requiredValidator(
                      value,
                      minimum: 3,
                      field: 'Le titre',
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller:
                        _descriptionController,
                    label: 'Description',
                    hint:
                        'Décris ton projet en quelques mots...',
                    icon: Icons.subject_outlined,
                    maxLines: 5,
                    maxLength: 2000,
                    textInputAction:
                        TextInputAction.newline,
                  ),

                  const SizedBox(height: 16),

                  _buildCategoryField(),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    'Ton idée',
                    subtitle:
                        'Explique le problème et la '
                        'solution proposée.',
                    icon: Icons.lightbulb_outline,
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: _problemController,
                    label:
                        'Quel problème veux-tu résoudre ?',
                    hint:
                        'Explique le problème...',
                    icon: Icons.warning_amber_outlined,
                    maxLines: 5,
                    maxLength: 1500,
                    textInputAction:
                        TextInputAction.newline,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    controller:
                        _solutionController,
                    label:
                        'Quelle est ta solution ?',
                    hint:
                        'Explique comment ton projet '
                        'répond au problème...',
                    icon:
                        Icons.auto_awesome_outlined,
                    maxLines: 5,
                    maxLength: 1500,
                    textInputAction:
                        TextInputAction.newline,
                  ),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    'Localisation',
                    subtitle:
                        'Indique où ton projet est '
                        'principalement développé.',
                    icon:
                        Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller:
                              _countryController,
                          label: 'Pays',
                          hint: 'Haïti',
                          icon: Icons.flag_outlined,
                          textInputAction:
                              TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller:
                              _cityController,
                          label: 'Ville',
                          hint: 'Delmas',
                          icon:
                              Icons.location_city_outlined,
                          textInputAction:
                              TextInputAction.done,
                        ),
                      ),
                    ],
                  ),
                                    const SizedBox(height: 30),

                  _sectionTitle(
                    'Équipe',
                    subtitle:
                        'Indique le nombre de personnes '
                        'qui travaillent sur le projet.',
                    icon: Icons.groups_outlined,
                  ),

                  const SizedBox(height: 18),

                  _buildTeamSizeSelector(),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    'Financement',
                    subtitle:
                        'Facultatif : ajoute un objectif '
                        'de financement.',
                    icon:
                        Icons.account_balance_wallet_outlined,
                  ),

                  const SizedBox(height: 18),

                  _buildFundingCard(),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    'Image du projet',
                    subtitle:
                        'Ajoute une URL d’image pour '
                        'la couverture du projet.',
                    icon: Icons.image_outlined,
                  ),

                  const SizedBox(height: 18),

                  _buildTextField(
                    controller:
                        _coverImageController,
                    label:
                        'URL de l’image de couverture',
                    hint:
                        'https://...',
                    icon:
                        Icons.link_outlined,
                    keyboardType:
                        TextInputType.url,
                    textInputAction:
                        TextInputAction.done,
                    validator: (value) {
                      final url =
                          value?.trim() ?? '';

                      if (url.isEmpty) {
                        return null;
                      }

                      final uri =
                          Uri.tryParse(url);

                      if (uri == null ||
                          !uri.hasScheme ||
                          !uri.host.isNotEmpty) {
                        return 'Entre une URL valide.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  ValueListenableBuilder<
                      TextEditingValue>(
                    valueListenable:
                        _coverImageController,
                    builder: (
                      context,
                      value,
                      child,
                    ) {
                      return AnimatedSwitcher(
                        duration:
                            const Duration(
                          milliseconds: 250,
                        ),
                        child: _buildCoverPreview(),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  _buildError(),

                  if (_error != null)
                    const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54A)
                          .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFD54A)
                            .withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFFD54A),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ton projet sera enregistré '
                            'comme brouillon et restera '
                            'modifiable avant sa publication.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildSaveButton(),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      'Tu pourras compléter et publier '
                      'ton projet plus tard.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
