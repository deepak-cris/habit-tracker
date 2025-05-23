import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart'; // Added

part 'reward.g.dart'; // To be generated by build_runner

@HiveType(typeId: 2) // Ensure unique typeId (0=Habit, 1=HabitStatus)
@JsonSerializable() // Added
class Reward extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int pointCost;

  // Store icon code point as int, or use a String identifier
  @HiveField(4)
  int? iconCodePoint;

  Reward({
    required this.id,
    required this.name,
    this.description,
    required this.pointCost,
    this.iconCodePoint,
  });

  // Factory constructor for JSON deserialization
  factory Reward.fromJson(Map<String, dynamic> json) => _$RewardFromJson(json);

  // Method for JSON serialization
  Map<String, dynamic> toJson() => _$RewardToJson(this);
}
