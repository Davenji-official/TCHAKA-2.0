enum ProjectDiscoveryFilter {
  forYou,
  trending,
  rising,
  mostLiked,
  mostFollowed,
  impact,
  nearby,
}

extension ProjectDiscoveryFilterExtension on ProjectDiscoveryFilter {
  String get label {
    switch (this) {
      case ProjectDiscoveryFilter.forYou:
        return 'Pour toi';
      case ProjectDiscoveryFilter.trending:
        return 'Tendance';
      case ProjectDiscoveryFilter.rising:
        return 'Rising';
      case ProjectDiscoveryFilter.mostLiked:
        return 'Plus aimés';
      case ProjectDiscoveryFilter.mostFollowed:
        return 'Plus suivis';
      case ProjectDiscoveryFilter.impact:
        return 'Impact';
      case ProjectDiscoveryFilter.nearby:
        return 'Près de toi';
    }
  }

  String get key {
    switch (this) {
      case ProjectDiscoveryFilter.forYou:
        return 'for_you';
      case ProjectDiscoveryFilter.trending:
        return 'trending';
      case ProjectDiscoveryFilter.rising:
        return 'rising';
      case ProjectDiscoveryFilter.mostLiked:
        return 'most_liked';
      case ProjectDiscoveryFilter.mostFollowed:
        return 'most_followed';
      case ProjectDiscoveryFilter.impact:
        return 'impact';
      case ProjectDiscoveryFilter.nearby:
        return 'nearby';
    }
  }
}
extension ProjectDiscoveryFilterIconExtension
    on ProjectDiscoveryFilter {
  String get iconName {
    switch (this) {
      case ProjectDiscoveryFilter.forYou:
        return 'auto_awesome';
      case ProjectDiscoveryFilter.trending:
        return 'local_fire_department';
      case ProjectDiscoveryFilter.rising:
        return 'rocket_launch';
      case ProjectDiscoveryFilter.mostLiked:
        return 'favorite';
      case ProjectDiscoveryFilter.mostFollowed:
        return 'people';
      case ProjectDiscoveryFilter.impact:
        return 'volunteer_activism';
      case ProjectDiscoveryFilter.nearby:
        return 'location_on';
    }
  }
}
List<ProjectDiscoveryFilter> getAllProjectDiscoveryFilters() {
  return ProjectDiscoveryFilter.values;
}

ProjectDiscoveryFilter projectDiscoveryFilterFromKey(
  String value,
) {
  return ProjectDiscoveryFilter.values.firstWhere(
    (filter) => filter.key == value,
    orElse: () => ProjectDiscoveryFilter.forYou,
  );
}
