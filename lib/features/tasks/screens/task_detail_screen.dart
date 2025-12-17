import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/task.dart';

/// Task Detail Screen - shows task information
class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur edit segera hadir!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriorityBadge(context),
            const SizedBox(height: 16),
            Text(
              task.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.description_outlined,
              label: 'Deskripsi',
              value: task.description,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Tenggat Waktu',
              value: task.dueDate != null 
                  ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(task.dueDate!)
                  : 'Tidak ada tenggat',
            ),
            const SizedBox(height: 16),
            _buildStatusRow(context),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              icon: Icons.access_time_outlined,
              label: 'Dibuat',
              value: task.createdAt != null
                  ? DateFormat('dd MMM yyyy - HH:mm', 'id_ID').format(task.createdAt!)
                  : 'Tidak diketahui',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (task.priority) {
      case TaskPriority.high:
        backgroundColor = AppColors.priorityHighBg;
        textColor = AppColors.priorityHigh;
        break;
      case TaskPriority.medium:
        backgroundColor = AppColors.priorityMediumBg;
        textColor = AppColors.priorityMedium;
        break;
      case TaskPriority.low:
        backgroundColor = AppColors.priorityLowBg;
        textColor = AppColors.priorityLow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Prioritas ${task.priority.displayName}',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = AppColors.statusCompleted;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.pending:
        statusColor = AppColors.statusPending;
        statusIcon = Icons.schedule;
        break;
      case TaskStatus.overdue:
        statusColor = AppColors.statusOverdue;
        statusIcon = Icons.error_outline;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.status.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
