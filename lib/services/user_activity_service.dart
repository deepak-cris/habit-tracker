import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_activity.dart';

class UserActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'user_activity';

  // Create a new UserActivity document
  Future<void> createUserActivity(String userId) async {
    try {
      final userActivity = UserActivity(userId: userId);
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(userActivity.toMap());
      print('User activity created for user: $userId');
    } catch (e) {
      print('Error creating user activity: $e');
    }
  }

  // Get UserActivity document
  Future<UserActivity?> getUserActivity(String userId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();
      if (doc.exists) {
        return UserActivity.fromDocument(doc.data()!, userId);
      } else {
        print('User activity not found for user: $userId');
        return null;
      }
    } catch (e) {
      print('Error getting user activity: $e');
      return null;
    }
  }

  // Increment habitsAdded count
  Future<void> incrementHabitCount(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'habitsAdded': FieldValue.increment(1),
      });
      print('Habit count incremented for user: $userId');
    } catch (e) {
      print('Error incrementing habit count: $e');
    }
  }

  // Increment rewardsAdded count
  Future<void> incrementRewardCount(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'rewardsAdded': FieldValue.increment(1),
      });
      print('Reward count incremented for user: $userId');
    } catch (e) {
      print('Error incrementing reward count: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String userId, String paymentStatus) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'paymentStatus': paymentStatus,
      });
      print('Payment status updated for user: $userId to $paymentStatus');
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }
}
