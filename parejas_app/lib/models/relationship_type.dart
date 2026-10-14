enum RelationshipType { saliendo, novios, amantes, esposos }

extension RelationshipTypeX on RelationshipType {
  String get label => switch (this) {
        RelationshipType.saliendo => 'Saliendo',
        RelationshipType.novios => 'Novios',
        RelationshipType.amantes => 'Amantes',
        RelationshipType.esposos => 'Esposos',
      };
}
