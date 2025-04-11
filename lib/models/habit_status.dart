import 'package:hive/hive.dart';

part 'habit_status.g.dart'; // We'll generate this

@HiveType(typeId: 1) // Use a unique typeId (e.g., 1)
enum HabitStatus {
  @HiveField(0)
  none, // Default state

  @HiveField(1)
  done,

  @HiveField(2)
  fail,

  @HiveField(3)
  skip,
}
