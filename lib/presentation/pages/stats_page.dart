import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/utils/date_utils.dart';
import '../../domain/entities/task_category.dart';
import '../bloc/task/task_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/app_card.dart';
import '../widgets/progress_ring.dart';

/// Analytics screen: overall completion ring, a weekly bar chart of tasks
/// completed per day, and a category breakdown pie chart.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state.allTasks.isEmpty) {
              return const EmptyState(
                icon: Icons.insights,
                title: 'No data yet',
                message: 'Add a few tasks to see your productivity stats.',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Text('Statistics',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _overallAppCard(context, state),
                const SizedBox(height: 16),
                _weeklyChartAppCard(context, state),
                const SizedBox(height: 16),
                _categoryAppCard(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _overallAppCard(BuildContext context, TaskState state) {
    final overall =
        state.totalCount == 0 ? 0.0 : state.completedCount / state.totalCount;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            ProgressRing(
              progress: overall,
              size: 120,
              strokeWidth: 12,
              caption: 'Done',
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall completion',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _legendRow(context, 'Completed', state.completedCount,
                      scheme.primary),
                  _legendRow(context, 'Pending', state.pendingCount,
                      scheme.onSurfaceVariant),
                  _legendRow(
                      context, 'Overdue', state.overdueCount, scheme.error),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(
      BuildContext context, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$label: ',
              style: Theme.of(context).textTheme.bodyMedium),
          Text('$value',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _weeklyChartAppCard(BuildContext context, TaskState state) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // Build last 7 days (oldest -> newest).
    final days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final counts = days.map((day) {
      return state.allTasks
          .where((t) =>
              t.isCompleted && AppDateUtils.isSameDate(t.updatedAt, day))
          .length
          .toDouble();
    }).toList();
    final maxCount = counts.fold<double>(0, (m, c) => c > m ? c : m);
    final maxY = (maxCount < 4 ? 4.0 : maxCount + 1);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completed this week',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withAlpha(76),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('E').format(days[i])[0],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < counts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i],
                            width: 16,
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [scheme.primary, scheme.tertiary],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryAppCard(BuildContext context, TaskState state) {
    final counts = <TaskCategory, int>{};
    for (final task in state.allTasks) {
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }
    final entries =
        counts.entries.where((e) => e.value > 0).toList(growable: false);
    final total = state.allTasks.length;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By category',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: [
                        for (final e in entries)
                          PieChartSectionData(
                            value: e.value.toDouble(),
                            color: e.key.color,
                            title: '${e.value}',
                            radius: 26,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: e.key.color,
                                    borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key.label)),
                              Text(
                                '${((e.value / total) * 100).round()}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



