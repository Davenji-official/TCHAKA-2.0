import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectMatchingService {
  ProjectMatchingService._();

  static final SupabaseClient _client = Supabase.instance.client;

  /// Retourne les compétences du profil connecté.
  static Future<List<Map<String, dynamic>>> getMySkills() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      return [];
    }

    final response = await _client
        .from('user_skills')
        .select(
          'skill_id, proficiency, skills(id, name, slug, category)',
        )
        .eq('profile_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Calcule la pertinence d'un projet par rapport aux compétences
  /// de l'utilisateur.
  ///
  /// Le score est volontairement transparent :
  /// - 60 % : couverture des compétences demandées
  /// - 20 % : niveau de maîtrise
  /// - 10 % : activité/engagement du projet
  /// - 10 % : impact du projet
  static double calculateMatchScore({
    required Map<String, dynamic> project,
    required List<Map<String, dynamic>> userSkills,
  }) {
    if (userSkills.isEmpty) {
      return 0;
    }

    final userSkillIds = <String, double>{};

    for (final item in userSkills) {
      final skillId = item['skill_id']?.toString();

      if (skillId == null || skillId.isEmpty) {
        continue;
      }

      final proficiency = _number(item['proficiency']);

      userSkillIds[skillId] = proficiency.clamp(1, 5).toDouble();
    }

    if (userSkillIds.isEmpty) {
      return 0;
    }

    final requiredSkills = _extractRequiredSkillIds(project);

    if (requiredSkills.isEmpty) {
      return _fallbackProjectScore(project);
    }

    var matched = 0;
    var proficiencyTotal = 0.0;

    for (final requiredSkillId in requiredSkills) {
      final proficiency = userSkillIds[requiredSkillId];

      if (proficiency == null) {
        continue;
      }

      matched++;
      proficiencyTotal += proficiency / 5;
    }

    final coverage = matched / requiredSkills.length;

    final proficiencyScore = matched == 0
        ? 0.0
        : proficiencyTotal / matched;

    final engagementScore = _normalize(
      _number(
        project['feed_score'] ??
            project['engagement_score'] ??
            project['likes_count'],
      ),
      100,
    );

    final impactScore = _normalize(
      _number(project['impact_score']),
      100,
    );

    final score =
        (coverage * 60) +
        (proficiencyScore * 20) +
        (engagementScore * 10) +
        (impactScore * 10);

    return score.clamp(0, 100).toDouble();
  }

  /// Classe les projets du plus pertinent au moins pertinent.
  static List<Map<String, dynamic>> rankProjects({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> userSkills,
  }) {
    final ranked = projects.map((project) {
      final score = calculateMatchScore(
        project: project,
        userSkills: userSkills,
      );

      return {
        ...project,
        'match_score': score,
      };
    }).toList();

    ranked.sort((a, b) {
      final scoreA = _number(a['match_score']);
      final scoreB = _number(b['match_score']);

      return scoreB.compareTo(scoreA);
    });

    return ranked;
  }

  /// Retourne uniquement les projets suffisamment pertinents.
  static List<Map<String, dynamic>> getRelevantProjects({
    required List<Map<String, dynamic>> projects,
    required List<Map<String, dynamic>> userSkills,
    double minimumScore = 25,
  }) {
    return rankProjects(
      projects: projects,
      userSkills: userSkills,
    ).where((project) {
      return _number(project['match_score']) >= minimumScore;
    }).toList();
  }

  static List<String> _extractRequiredSkillIds(
    Map<String, dynamic> project,
  ) {
    final rawValues = <dynamic>[
      project['required_skill_ids'],
      project['skill_ids'],
    ];

    for (final raw in rawValues) {
      if (raw is List) {
        return raw
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
      }
    }

    final projectSkills = project['project_skills'];

    if (projectSkills is List) {
      return projectSkills
          .whereType<Map>()
          .map((skill) {
            return skill['skill_id']?.toString() ?? '';
          })
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
    }

    return [];
  }

  static double _fallbackProjectScore(
    Map<String, dynamic> project,
  ) {
    final engagement = _normalize(
      _number(
        project['feed_score'] ??
            project['engagement_score'] ??
            project['likes_count'],
      ),
      100,
    );

    final impact = _normalize(
      _number(project['impact_score']),
      100,
    );

    return ((engagement * 0.5) + (impact * 0.5)) * 100;
  }

  static double _normalize(
    double value,
    double maximum,
  ) {
    if (maximum <= 0) {
      return 0;
    }

    return (value / maximum).clamp(0, 1).toDouble();
  }

  static double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
