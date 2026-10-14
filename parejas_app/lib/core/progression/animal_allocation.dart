import 'dart:math';
import '../../models/customization.dart';

class AnimalAllocationResult {
  final String animalForUser1;
  final String animalForUser2;
  const AnimalAllocationResult(this.animalForUser1, this.animalForUser2);
}

/// Elige un animal al azar para cada integrante de la pareja al subir de
/// nivel, garantizando que:
///  - ninguno de los dos repite un animal que ya tiene el otro (regla de
///    unicidad dentro de la pareja, sección 5.1 del diseño)
///  - los dos animales elegidos en esta tirada son distintos entre sí
///
/// Lanza [StateError] si no quedan al menos 2 animales libres en el
/// catálogo — en ese caso hay que agregar más a CustomizationCatalog.animals.
AnimalAllocationResult allocateAnimalsOnLevelUp({
  required List<String> ownedByUser1,
  required List<String> ownedByUser2,
  Random? random,
}) {
  final taken = {...ownedByUser1, ...ownedByUser2};
  final available = CustomizationCatalog.animals
      .map((a) => a.id)
      .where((id) => !taken.contains(id))
      .toList()
    ..shuffle(random ?? Random());

  if (available.length < 2) {
    throw StateError(
      'No quedan animales suficientes en el catálogo para repartir — '
      'agregar más a CustomizationCatalog.animals.',
    );
  }

  return AnimalAllocationResult(available[0], available[1]);
}
