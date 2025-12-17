import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../models/task.dart';

/// Professional TaskCard dengan Material Design 3 styling
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.deleteTask),
            content: const Text(AppStrings.deleteConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(AppStrings.taskDeleted),
            action: SnackBarAction(
              label: AppStrings.undo,
              onPressed: () {
                // TODO: Implement undo in P7 with state management
              },
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.onError,
          size: 28,
        ),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Show sync indicator if not synced
                    if (!task.isSynced) ...[
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 16,
                        color: AppColors.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _buildPriorityBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withOpacity(0.7),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate != null 
                          ? DateFormat('MMM dd, yyyy').format(task.dueDate!)
                          : 'No due date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const Spacer(),
                    _buildStatusIndicator(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        task.priority.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          statusIcon,
          size: 16,
          color: statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          task.status.displayName,
          style: TextStyle(
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
