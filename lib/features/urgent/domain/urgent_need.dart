enum UrgentSeverity {
  critical,
  high,
  medium,
}

enum UrgentStatus {
  active,
  mobilizing,
  resolved,
  expired,
}

enum UrgentTargetType {
  expert,
  organization,
  nearby,
  investor,
  follower,
}

class UrgentNeed {
  const UrgentNeed({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.authorId,
    this.location,
    this.latitude,
    this.longitude,
    this.requiredSkillIds = const [],
    this.resourceTypes = const [],
    this.targetTypes = const [],
    this.expiresAt,
    this.resolvedAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;

  final UrgentSeverity severity;
  final UrgentStatus status;

  final String? authorId;

  final String? location;
  final double? latitude;
  final double? longitude;

  final List<String> requiredSkillIds;
  final List<String> resourceTypes;
  final List<UrgentTargetType> targetTypes;

  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? resolvedAt;

  bool get isActive {
    if (status == UrgentStatus.resolved ||
        status == UrgentStatus.expired) {
      return false;
    }

    if (expiresAt == null) {
      return true;
    }

    return expiresAt!.isAfter(DateTime.now());
  }

  bool get isCritical =>
      severity == UrgentSeverity.critical;

  factory UrgentNeed.fromMap(
    Map<String, dynamic> map,
  ) {
    return UrgentNeed(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description:
          map['description']?.toString() ?? '',
      category:
          map['category']?.toString() ?? 'general',
      severity: _severityFromString(
        map['severity']?.toString(),
      ),
      status: _statusFromString(
        map['status']?.toString(),
      ),
      authorId: map['author_id']?.toString(),
      location: map['location']?.toString(),
      latitude: _doubleOrNull(map['latitude']),
      longitude: _doubleOrNull(map['longitude']),
      requiredSkillIds:
          _stringList(map['required_skill_ids']),
      resourceTypes:
          _stringList(map['resource_types']),
      targetTypes:
          _targetTypesFromList(map['target_types']),
      createdAt: _dateOrNow(map['created_at']),
      expiresAt:
          _dateOrNull(map['expires_at']),
      resolvedAt:
          _dateOrNull(map['resolved_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'severity': severity.name,
      'status': status.name,
      'author_id': authorId,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'required_skill_ids': requiredSkillIds,
      'resource_types': resourceTypes,
      'target_types':
          targetTypes.map((e) => e.name).toList(),
      'created_at': createdAt.toIso8601String(),
      'expires_at':
          expiresAt?.toIso8601String(),
      'resolved_at':
          resolvedAt?.toIso8601String(),
    };
  }

  static UrgentSeverity _severityFromString(
    String? value,
  ) {
    switch (value) {
      case 'critical':
        return UrgentSeverity.critical;
      case 'high':
        return UrgentSeverity.high;
      default:
        return UrgentSeverity.medium;
    }
  }

  static UrgentStatus _statusFromString(
    String? value,
  ) {
    switch (value) {
      case 'mobilizing':
        return UrgentStatus.mobilizing;
      case 'resolved':
        return UrgentStatus.resolved;
      case 'expired':
        return UrgentStatus.expired;
      default:
        return UrgentStatus.active;
    }
  }

  static List<UrgentTargetType> _targetTypesFromList(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) {
          switch (item.toString()) {
            case 'expert':
              return UrgentTargetType.expert;
            case 'organization':
              return UrgentTargetType.organization;
            case 'nearby':
              return UrgentTargetType.nearby;
            case 'investor':
              return UrgentTargetType.investor;
            case 'follower':
              return UrgentTargetType.follower;
            default:
              return null;
          }
        })
        .whereType<UrgentTargetType>()
        .toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item?.toString() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static double? _doubleOrNull(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  static DateTime _dateOrNow(dynamic value) {
    return DateTime.tryParse(
          value?.toString() ?? '',
        ) ??
        DateTime.now();
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}
