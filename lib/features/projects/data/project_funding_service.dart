import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectFundingStats {
  const ProjectFundingStats({
    required this.projectId,
    required this.goalAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.progressPercent,
    required this.contributorCount,
    required this.currency,
  });

  final String projectId;
  final double goalAmount;
  final double collectedAmount;
  final double remainingAmount;
  final double progressPercent;
  final int contributorCount;
  final String currency;

  factory ProjectFundingStats.fromMap(
    Map<String, dynamic> map,
  ) {
    return ProjectFundingStats(
      projectId: map['project_id'] as String,
      goalAmount: _toDouble(map['goal_amount']),
      collectedAmount: _toDouble(
        map['collected_amount'],
      ),
      remainingAmount: _toDouble(
        map['remaining_amount'],
      ),
      progressPercent: _toDouble(
        map['progress_percent'],
      ),
      contributorCount: _toInt(
        map['contributor_count'],
      ),
      currency: (map['currency'] as String?) ?? 'HTG',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static int _toInt(dynamic value) {
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
  String get formattedGoalAmount {
    return _formatAmount(goalAmount);
  }

  String get formattedCollectedAmount {
    return _formatAmount(collectedAmount);
  }

  String get formattedRemainingAmount {
    return _formatAmount(remainingAmount);
  }

  String _formatAmount(double amount) {
    final rounded = amount.round();

    return rounded.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ' ',
        );
  }

  bool get hasReachedGoal {
    return collectedAmount >= goalAmount;
  }
}

class ProjectFundingService {
  ProjectFundingService._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<ProjectFundingStats?> getStats(
    String projectId,
  ) async {
    final cleanProjectId = projectId.trim();

    if (cleanProjectId.isEmpty) {
      return null;
    }

    final response = await _client.rpc(
      'get_project_funding_stats',
      params: {
        'p_project_id': cleanProjectId,
      },
    );

    if (response == null) {
      return null;
    }

    if (response is! List || response.isEmpty) {
      return null;
    }

    final firstRow = response.first;

    if (firstRow is! Map) {
      return null;
    }

    return ProjectFundingStats.fromMap(
      Map<String, dynamic>.from(firstRow),
    );
  }
}
// ============================================================
// Usage:
//
// final stats = await ProjectFundingService.getStats(
//   projectId,
// );
//
// if (stats != null) {
//   print(stats.formattedCollectedAmount);
//   print(stats.formattedGoalAmount);
//   print(stats.progressPercent);
//   print(stats.contributorCount);
// }
// ============================================================
