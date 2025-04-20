class UserActivity {
  final String userId;
  final int habitsAdded;
  final int rewardsAdded;
  final String paymentStatus;

  UserActivity({
    required this.userId,
    this.habitsAdded = 0,
    this.rewardsAdded = 0,
    this.paymentStatus = 'free',
  });

  // Factory method to create a UserActivity object from a Firestore document
  factory UserActivity.fromDocument(Map<String, dynamic> data, String userId) {
    return UserActivity(
      userId: userId,
      habitsAdded: data['habitsAdded'] ?? 0,
      rewardsAdded: data['rewardsAdded'] ?? 0,
      paymentStatus: data['paymentStatus'] ?? 'free',
    );
  }

  // Method to convert UserActivity object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'habitsAdded': habitsAdded,
      'rewardsAdded': rewardsAdded,
      'paymentStatus': paymentStatus,
    };
  }
}
