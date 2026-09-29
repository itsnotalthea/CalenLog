/// Habit model — `{ id, name, color }`.
library;

/// A single tracked habit.
class Habit {
  const Habit({required this.id, required this.name, required this.color});

  /// Stable identifier. Log keys embed this, so deleting a habit leaves its
  /// entries orphaned until a habit with the same id exists again.
  final String id;

  /// Display name. Must be unique (case-insensitive) across habits.
  final String name;

  /// Hex colour, `#rrggbb`.
  final String color;

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};

  Habit copyWith({String? name, String? color}) =>
      Habit(id: id, name: name ?? this.name, color: color ?? this.color);

  @override
  bool operator ==(Object other) =>
      other is Habit &&
      other.id == id &&
      other.name == name &&
      other.color == color;

  @override
  int get hashCode => Object.hash(id, name, color);

  @override
  String toString() => 'Habit($id, $name, $color)';
}
