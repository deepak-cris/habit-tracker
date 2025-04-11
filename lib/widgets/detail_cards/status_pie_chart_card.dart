import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/habit.dart';
import '../../models/habit_status.dart';
import '../../utils/habit_utils.dart'; // Import the calculation utility

class StatusPieChartCard extends StatelessWidget {
  final Habit habit;
  final DateTime fromDate;
  final DateTime toDate;

  const StatusPieChartCard({
    super.key,
    required this.habit,
    required this.fromDate,
    required this.toDate,
  });

  // Helper to get color based on status
  Color _getColorForStatus(HabitStatus status) {
    switch (status) {
      case HabitStatus.done:
        return Colors.green.shade400;
      case HabitStatus.fail:
        return Colors.red.shade400;
      case HabitStatus.skip:
        return Colors.orange.shade400;
      case HabitStatus.none:
        return Colors.grey.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // Helper to get title for status
  String _getTitleForStatus(HabitStatus status) {
    switch (status) {
      case HabitStatus.done:
        return 'Done';
      case HabitStatus.fail:
        return 'Fail';
      case HabitStatus.skip:
        return 'Skip';
      case HabitStatus.none:
        return 'None'; // Or maybe 'Missed'/'Unmarked'
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<HabitStatus, int> distribution = calculateStatusDistribution(
      habit,
      fromDate,
      toDate,
    );
    final List<PieChartSectionData> sections = [];
    int totalCount = 0;

    // Calculate total count excluding 'none'
    distribution.forEach((status, count) {
      if (status != HabitStatus.none) {
        // Exclude 'none' from total for percentage calculation
        totalCount += count;
      }
    });

    if (totalCount == 0) {
      // Handle case with no data in the range
      return Card(
        elevation: 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status Distribution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('No data for this period.')),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    // Create sections for the pie chart, excluding 'none'
    distribution.forEach((status, count) {
      if (count > 0 && status != HabitStatus.none) {
        // Exclude 'none' from chart sections
        final double percentage =
            totalCount > 0 ? (count / totalCount) * 100 : 0;
        sections.add(
          PieChartSectionData(
            color: _getColorForStatus(status),
            value: count.toDouble(), // Use raw count for value
            title: '${percentage.toStringAsFixed(0)}%', // Show percentage
            radius: 50, // Adjust radius as needed
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 2),
              ], // Add shadow for readability
            ),
          ),
        );
      }
    });

    // Create legend items, excluding 'none'
    List<Widget> legendItems = [];
    distribution.forEach((status, count) {
      if (count > 0 && status != HabitStatus.none) {
        // Exclude 'none' from legend
        legendItems.add(
          _buildLegendItem(
            _getColorForStatus(status),
            _getTitleForStatus(status),
            count,
          ),
        );
      }
    });

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2, // Give more space to the chart
                  child: AspectRatio(
                    aspectRatio: 1, // Make it square
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 30, // Make it a donut chart
                        sectionsSpace: 2, // Space between sections
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  flex: 1, // Less space for the legend
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: legendItems,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for legend items
  Widget _buildLegendItem(Color color, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text('$title: $count', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
