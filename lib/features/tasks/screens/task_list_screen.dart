import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/task_provider.dart';
import '../../../routes/app_routes.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';

/// Task List Screen - Refactored untuk Provider (P9)
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

enum TaskFilter {
  all,
  pending,
  overdue,
  completed;

  String get displayName {
    switch (this) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.pending:
        return 'Pending';
      case TaskFilter.overdue:
        return 'Overdue';
      case TaskFilter.completed:
        return 'Completed';
    }
  }
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskFilter _selectedFilter = TaskFilter.all;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoaded) {
        _hasLoaded = true;
        context.read<TaskProvider>().loadTasksOfflineFirst();
      }
    });
  }

  Future<void> _deleteTask(Task task) async {
    final success = await context.read<TaskProvider>().deleteTask(task);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<TaskProvider>().errorMessage ?? 'Gagal menghapus task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    switch (_selectedFilter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.pending:
        return tasks.where((task) => task.status == TaskStatus.pending).toList();
      case TaskFilter.overdue:
        return tasks.where((task) => task.status == TaskStatus.overdue).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.status == TaskStatus.completed).toList();
    }
  }

  void _onFilterChanged(TaskFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TaskProvider>().logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final filteredTasks = _getFilteredTasks(taskProvider.tasks);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.taskList,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                if (taskProvider.email.isNotEmpty)
                  Text(
                    taskProvider.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
            backgroundColor: const Color(0xFFF5F7FA),
            elevation: 0,
            actions: [
              // Show sync indicator
              if (taskProvider.isSyncing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 26),
                onPressed: () => taskProvider.refreshTasks(),
                tooltip: 'Refresh',
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 26),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout();
                  }
                },
              ),
            ],
          ),
          body: _buildBody(taskProvider, filteredTasks),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _navigateToAddTask,
            tooltip: AppStrings.addTask,
            backgroundColor: const Color(0xFF6C5CE7),
            elevation: 4,
            icon: const Icon(Icons.add, size: 24),
            label: const Text(
              'New Task',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(TaskProvider taskProvider, List<Task> filteredTasks) {
    // Show loading
    if (taskProvider.isTaskLoading && taskProvider.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error
    if (taskProvider.errorMessage != null && taskProvider.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(taskProvider.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => taskProvider.refreshTasks(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterChips(),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => taskProvider.refreshTasks(),
            child: filteredTasks.isEmpty
                ? _buildEmptyState()
                : _buildTaskList(filteredTasks),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: TaskFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          
          Color backgroundColor;
          Color textColor;
          IconData icon;

          switch (filter) {
            case TaskFilter.all:
              icon = Icons.dashboard_rounded;
              if (isSelected) {
                backgroundColor = const Color(0xFF6C5CE7);
                textColor = Colors.white;
              } else {
                backgroundColor = Colors.transparent;
                textColor = const Color(0xFF6C5CE7);
              }
              break;
            case TaskFilter.pending:
              icon = Icons.pending_outlined;
              if (isSelected) {
                backgroundColor = const Color(0xFFFFA726);
                textColor = Colors.white;
              } else {
                backgroundColor = Colors.transparent;
                textColor = const Color(0xFFFFA726);
              }
              break;
            case TaskFilter.overdue:
              icon = Icons.warning_amber_rounded;
              if (isSelected) {
                backgroundColor = const Color(0xFFEF5350);
                textColor = Colors.white;
              } else {
                backgroundColor = Colors.transparent;
                textColor = const Color(0xFFEF5350);
              }
              break;
            case TaskFilter.completed:
              icon = Icons.check_circle_rounded;
              if (isSelected) {
                backgroundColor = const Color(0xFF66BB6A);
                textColor = Colors.white;
              } else {
                backgroundColor = Colors.transparent;
                textColor = const Color(0xFF66BB6A);
              }
              break;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => _onFilterChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: textColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filter.displayName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildModernTaskCard(task),
        );
      },
    );
  }

  Widget _buildModernTaskCard(Task task) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (task.status) {
      case TaskStatus.completed:
        statusColor = const Color(0xFF66BB6A);
        statusBgColor = const Color(0xFFE8F5E9);
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.pending:
        statusColor = const Color(0xFFFFA726);
        statusBgColor = const Color(0xFFFFF3E0);
        statusIcon = Icons.schedule;
        break;
      case TaskStatus.overdue:
        statusColor = const Color(0xFFEF5350);
        statusBgColor = const Color(0xFFFFEBEE);
        statusIcon = Icons.error;
        break;
    }

    return Dismissible(
      key: Key(task.serverId?.toString() ?? task.title),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Task'),
            content: const Text('Yakin ingin menghapus task ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (direction) => _deleteTask(task),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () => _navigateToDetail(task),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3436),
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Toggle completed checkbox
                  Checkbox(
                    value: task.completed,
                    onChanged: task.completed
                        ? null
                        : (value) async {
                            await context.read<TaskProvider>().toggleTask(task);
                          },
                    activeColor: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.status.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Due date
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd, yyyy').format(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.priority.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getPriorityColor(task.priority),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFE53E3E);
      case TaskPriority.medium:
        return const Color(0xFFED8936);
      case TaskPriority.low:
        return const Color(0xFF48BB78);
    }
  }

  Widget _buildEmptyState() {
    String emptyMessage;
    String emptyDescription;
    IconData emptyIcon;
    Color iconColor;

    switch (_selectedFilter) {
      case TaskFilter.all:
        emptyMessage = AppStrings.noTasks;
        emptyDescription = AppStrings.noTasksDescription;
        emptyIcon = Icons.inbox_rounded;
        iconColor = const Color(0xFF6C5CE7);
        break;
      case TaskFilter.pending:
        emptyMessage = 'No Pending Tasks';
        emptyDescription = 'All tasks are either completed or overdue';
        emptyIcon = Icons.pending_actions_rounded;
        iconColor = const Color(0xFFFFA726);
        break;
      case TaskFilter.overdue:
        emptyMessage = 'No Overdue Tasks';
        emptyDescription = 'Great! All tasks are on time';
        emptyIcon = Icons.celebration_rounded;
        iconColor = const Color(0xFF66BB6A);
        break;
      case TaskFilter.completed:
        emptyMessage = 'No Completed Tasks';
        emptyDescription = 'Start completing tasks to see them here';
        emptyIcon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF66BB6A);
        break;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    emptyIcon,
                    size: 64,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddTask() {
    Navigator.pushNamed(context, AppRoutes.addTask);
  }
}
