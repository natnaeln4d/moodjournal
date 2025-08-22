import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:job5/modules/dashboard/views/dashboard_screen.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';

import '../../../data/models/dashboard/controllers/mood_controller.dart';

class ProfileScreen extends StatelessWidget {
  final MoodController _moodController = Get.find<MoodController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile & Achievements'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade400, Colors.purple.shade200],
          ),
        ),
        child: Obx(() => ListView(
          padding: EdgeInsets.all(16),
          children: [
            // User Card
            _buildUserCard(),
            SizedBox(height: 20),
            
            // Progress towards next achievement
            _buildProgressCard(),
            SizedBox(height: 20),
            
            // Achievements List
            _buildAchievementsList(),
          ],
        )),
      ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'User Name', // Replace with actual user name
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('user@example.com'), // Replace with actual user email
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${_moodController.streakCount.value}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('Day Streak'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${_moodController.totalEntries.value}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('Total Entries'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '5', // Replace with actual achievement count
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('Achievements'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildProgressCard() {
    final int entries = _moodController.totalEntries.value;
    final int nextMilestone = entries < 5 ? 5 : entries < 10 ? 10 : entries < 25 ? 25 : 50;
    final double progress = entries / nextMilestone;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress to Next Achievement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: LiquidLinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(Colors.deepPurple),
                    borderRadius: 12,
                    direction: Axis.horizontal,
                    center: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Text('$entries/$nextMilestone entries'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Next achievement at $nextMilestone entries!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAchievementsList() {
    final List<Map<String, dynamic>> achievements = [
      {
        'title': 'First Entry',
        'description': 'Log your first mood entry',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'unlocked': _moodController.totalEntries.value >= 1,
      },
      {
        'title': 'Consistent Logger',
        'description': 'Log 5 mood entries',
        'icon': Icons.emoji_events,
        'color': Colors.blue,
        'unlocked': _moodController.totalEntries.value >= 5,
      },
      {
        'title': 'Mood Expert',
        'description': 'Log 10 mood entries',
        'icon': Icons.emoji_events,
        'color': Colors.green,
        'unlocked': _moodController.totalEntries.value >= 10,
      },
      {
        'title': 'Journal Keeper',
        'description': 'Write 5 journal entries',
        'icon': Icons.emoji_events,
        'color': Colors.purple,
        'unlocked': false, // Replace with actual journal count
      },
      {
        'title': '7-Day Streak',
        'description': 'Log moods for 7 consecutive days',
        'icon': Icons.emoji_events,
        'color': Colors.red,
        'unlocked': _moodController.streakCount.value >= 7,
      },
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementItem(achievement, index);
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAchievementItem(Map<String, dynamic> achievement, int index) {
    return ListTile(
      leading: Icon(
        achievement['icon'],
        color: achievement['unlocked'] ? achievement['color'] : Colors.grey,
        size: 30,
      ),
      title: Text(
        achievement['title'],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: achievement['unlocked'] ? Colors.black : Colors.grey,
        ),
      ),
      subtitle: Text(
        achievement['description'],
        style: TextStyle(
          color: achievement['unlocked'] ? Colors.black54 : Colors.grey,
        ),
      ),
      trailing: achievement['unlocked']
          ? Icon(Icons.check_circle, color: Colors.green)
          : Icon(Icons.lock, color: Colors.grey),
    ).animate().fadeIn(delay: (index * 200).ms).slideX(begin: 0.5, end: 0);
  }
}