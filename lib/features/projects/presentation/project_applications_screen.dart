import 'package:flutter/material.dart';

import '../data/project_application_service.dart';

class ProjectApplicationsScreen extends StatefulWidget {
  const ProjectApplicationsScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  State<ProjectApplicationsScreen> createState() =>
      _ProjectApplicationsScreenState();
}

class _ProjectApplicationsScreenState
    extends State<ProjectApplicationsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _yellow = Color(0xFFFFD54A);

  bool _loading = true;
  bool _actionLoading = false;
  String? _error;
  String _filter = 'all';

  List<Map<String, dynamic>> _applications = [];

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

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

    _loadApplications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final applications =
          await ProjectApplicationService
              .getProjectApplications(
        widget.projectId,
      );

      if (!mounted) return;

      setState(() {
        _applications = applications;
        _loading = false;
      });

      _animationController
        ..reset()
        ..forward();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _errorMessage(error);
      });
    }
  }

  String _errorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('connect') ||
        message.contains('auth')) {
      return 'Connecte-toi pour consulter '
          'les candidatures.';
    }

    if (message.contains('permission') ||
        message.contains('policy') ||
        message.contains('forbidden')) {
      return 'Tu n’as pas l’autorisation '
          'de consulter ces candidatures.';
    }

    return 'Impossible de charger les candidatures.';
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_filter == 'all') {
      return _applications;
    }

    return _applications.where((application) {
      final status =
          application['status']
              ?.toString()
              .toLowerCase();

      return status == _filter;
    }).toList();
  }

  int _countStatus(String status) {
    return _applications.where((application) {
      return application['status']
              ?.toString()
              .toLowerCase() ==
          status;
    }).length;
  }

  int get _pendingCount =>
      _countStatus('pending');

  int get _reviewingCount =>
      _countStatus('reviewing');

  int get _acceptedCount =>
      _countStatus('accepted');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('Candidatures'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 14),
                  child: _skeleton(),
                );
              },
              childCount: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _skeleton() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(22),
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
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: _yellow,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Candidatures indisponibles',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      color: _yellow,
      onRefresh: _loadApplications,
      child: CustomScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              40,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverview(),
                const SizedBox(height: 22),
                _buildFilters(),
                const SizedBox(height: 18),
              ]),
            ),
          ),
          if (_filteredApplications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                48,
              ),
              sliver: SliverList.builder(
                itemCount:
                    _filteredApplications.length,
                itemBuilder: (context, index) {
                  final application =
                      _filteredApplications[index];

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: _buildApplicationCard(
                        application,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 155,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.arrow_back),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Candidatures',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _yellow.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 28,
              bottom: 48,
              child: Icon(
                Icons.groups_2_outlined,
                color: _yellow,
                size: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          '${_applications.length} '
          'candidature${_applications.length > 1 ? 's' : ''}',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Gère les personnes qui souhaitent '
          'rejoindre ton projet.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'En attente',
                _pendingCount,
                Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                'Examen',
                _reviewingCount,
                Icons.visibility_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                'Acceptées',
                _acceptedCount,
                Icons.check_circle_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    int count,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _yellow,
            size: 21,
          ),
          const SizedBox(height: 9),
          Text(
            '$count',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelSmall,
          ),
        ],
      ),
    );
  }
    Widget _buildFilters() {
    final filters = <String, String>{
      'all': 'Toutes',
      'pending': 'En attente',
      'reviewing': 'Examen',
      'accepted': 'Acceptées',
      'rejected': 'Refusées',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.entries.map((entry) {
          final selected =
              _filter == entry.key;

          return Padding(
            padding:
                const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filter = entry.key;
                });
              },
              selectedColor: _yellow,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.black
                    : null,
                fontWeight: selected
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
              side: BorderSide(
                color: selected
                    ? _yellow
                    : Theme.of(context)
                        .colorScheme
                        .outline,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius:
                    BorderRadius.circular(27),
              ),
              child: const Icon(
                Icons.person_search_outlined,
                color: _yellow,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _filter == 'all'
                  ? 'Aucune candidature'
                  : 'Aucune candidature ici',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _filter == 'all'
                  ? 'Les personnes intéressées '
                    'par ton projet apparaîtront ici.'
                  : 'Essaie un autre filtre.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(
    Map<String, dynamic> application,
  ) {
    final id =
        application['id']?.toString();

    final status =
        application['status']
            ?.toString()
            .toLowerCase() ??
        'pending';

    final role =
        application['proposed_role']
            ?.toString()
            .trim();

    final message =
        application['cover_message']
            ?.toString()
            .trim();

    final applicantId =
        application['applicant_id']
            ?.toString();

    final createdAt =
        application['created_at']
            ?.toString();

    final displayRole =
        role != null && role.isNotEmpty
            ? role
            : 'Collaborateur';

    final displayMessage =
        message != null && message.isNotEmpty
            ? message
            : 'Aucun message de motivation.';

    return InkWell(
      onTap: id == null
          ? null
          : () => _showApplicationDetails(
                application,
              ),
      borderRadius:
          BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: status == 'pending'
                ? _yellow.withValues(
                    alpha: 0.35,
                  )
                : Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(applicantId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Candidat',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayRole,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              displayMessage,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _formatDate(createdAt),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? applicantId) {
    final initials =
        applicantId != null &&
                applicantId.length >= 2
            ? applicantId
                .substring(0, 2)
                .toUpperCase()
            : 'U';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius:
            BorderRadius.circular(17),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: _yellow,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: config.$3.withValues(
          alpha: 0.13,
        ),
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.$1,
            size: 14,
            color: config.$3,
          ),
          const SizedBox(width: 4),
          Text(
            config.$2,
            style: TextStyle(
              color: config.$3,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _statusConfig(
    String status,
  ) {
    switch (status) {
      case 'reviewing':
        return (
          Icons.visibility_outlined,
          'EXAMEN',
          Colors.blue,
        );
      case 'accepted':
        return (
          Icons.check_circle_outline,
          'ACCEPTÉE',
          Colors.green,
        );
      case 'rejected':
        return (
          Icons.cancel_outlined,
          'REFUSÉE',
          Colors.red,
        );
      case 'withdrawn':
        return (
          Icons.undo_outlined,
          'RETIRÉE',
          Colors.grey,
        );
      default:
        return (
          Icons.schedule_outlined,
          'EN ATTENTE',
          _yellow,
        );
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date inconnue';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Date inconnue';
    }

    final local = date.toLocal();

    String two(int number) =>
        number.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/'
        '${local.year}';
  }
    Future<void> _showApplicationDetails(
    Map<String, dynamic> application,
  ) async {
    final id =
        application['id']?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    final status =
        application['status']
            ?.toString()
            .toLowerCase() ??
        'pending';

    final role =
        application['proposed_role']
            ?.toString()
            .trim();

    final message =
        application['cover_message']
            ?.toString()
            .trim();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext)
                          .size
                          .height *
                      0.86,
            ),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext)
                  .scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                22,
                12,
                22,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          sheetContext,
                        )
                            .colorScheme
                            .outline,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _buildAvatar(
                        application['applicant_id']
                            ?.toString(),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Candidature',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              role != null &&
                                      role.isNotEmpty
                                  ? role
                                  : 'Collaborateur',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _detailSection(
                    title: 'Rôle proposé',
                    icon: Icons.badge_outlined,
                    child: Text(
                      role != null &&
                              role.isNotEmpty
                          ? role
                          : 'Aucun rôle précisé.',
                      style: Theme.of(sheetContext)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _detailSection(
                    title: 'Message de motivation',
                    icon: Icons
                        .description_outlined,
                    child: Text(
                      message != null &&
                              message.isNotEmpty
                          ? message
                          : 'Aucun message fourni.',
                      style: Theme.of(sheetContext)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            height: 1.55,
                          ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (status == 'pending')
                    _buildPendingActions(
                      sheetContext,
                      id,
                    )
                  else if (status == 'reviewing')
                    _buildReviewingActions(
                      sheetContext,
                      id,
                    ),
                  if (status == 'accepted')
                    _infoBanner(
                      Icons.check_circle_outline,
                      'Cette candidature est acceptée.',
                      Colors.green,
                    ),
                  if (status == 'rejected')
                    _infoBanner(
                      Icons.cancel_outlined,
                      'Cette candidature a été refusée.',
                      Colors.red,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
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
          Row(
            children: [
              Icon(
                icon,
                color: _yellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPendingActions(
    BuildContext sheetContext,
    String applicationId,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _actionLoading
                ? null
                : () => _review(
                      applicationId,
                      'reviewing',
                      sheetContext,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: Colors.black,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.visibility_outlined,
            ),
            label: const Text(
              'Commencer l’examen',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _actionLoading
                ? null
                : () => _confirmReject(
                      applicationId,
                      sheetContext,
                    ),
            icon: const Icon(
              Icons.close,
              color: Colors.red,
            ),
            label: const Text(
              'Refuser',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewingActions(
    BuildContext sheetContext,
    String applicationId,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _actionLoading
                ? null
                : () => _confirmReject(
                      applicationId,
                      sheetContext,
                    ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(
                color: Colors.red,
              ),
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
            child: const Text(
              'Refuser',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _actionLoading
                ? null
                : () => _accept(
                      applicationId,
                      sheetContext,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: Colors.black,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
            child: const Text(
              'Accepter',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBanner(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _review(
    String applicationId,
    String status,
    BuildContext sheetContext,
  ) async {
    setState(() {
      _actionLoading = true;
    });

    try {
      final updated =
          await ProjectApplicationService
              .reviewApplication(
        applicationId: applicationId,
        status: status,
      );

      if (!mounted || !sheetContext.mounted) return;

_replaceApplication(updated);

Navigator.of(sheetContext).pop();

      _showMessage(
        'Candidature placée en examen.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _actionErrorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _accept(
    String applicationId,
    BuildContext sheetContext,
  ) async {
    setState(() {
      _actionLoading = true;
    });

    try {
      final updated =
          await ProjectApplicationService
              .acceptApplication(
        applicationId: applicationId,
      );

      if (!mounted || !sheetContext.mounted) return;

_replaceApplication(updated);

Navigator.of(sheetContext).pop();
      _showMessage(
        'Candidature acceptée. 🎉',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _actionErrorMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _confirmReject(
    String applicationId,
    BuildContext sheetContext,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Refuser cette candidature ?',
          ),
          content: const Text(
            'Cette action modifiera le statut '
            'de la candidature.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _reject(
      applicationId,
      sheetContext,
    );
  }

    Future<void> _reject(
    String applicationId,
    BuildContext sheetContext,
  ) async {
    if (!mounted || !sheetContext.mounted) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final updated =
          await ProjectApplicationService.rejectApplication(
        applicationId,
      );

      if (!mounted || !sheetContext.mounted) {
        return;
      }

      _replaceApplication(updated);

      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Candidature refusée.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _actionErrorMessage(error),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _actionLoading = false;
      });
    }
    }

  void _replaceApplication(
    Map<String, dynamic> updated,
  ) {
    final id =
        updated['id']?.toString();

    if (id == null) return;

    final index =
        _applications.indexWhere(
      (application) =>
          application['id']?.toString() == id,
    );

    if (index == -1) return;

    setState(() {
      _applications[index] = updated;
    });
  }

  String _actionErrorMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('policy')) {
      return 'Tu n’as pas l’autorisation '
          'd’effectuer cette action.';
    }

    if (message.contains('auth') ||
        message.contains('connect')) {
      return 'Ta session a expiré. '
          'Reconnecte-toi.';
    }

    return 'Impossible de modifier cette candidature.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
