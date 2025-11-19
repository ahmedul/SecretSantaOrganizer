import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final int? participantId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.participantId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  String? _myTarget;
  String? _myTargetWishlist;
  bool _isDrawing = false;
  late TabController _tabController;
  List<Map<String, dynamic>> _exclusions = [];
  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic>? _budgetData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGroupDetails();
    _loadExclusions();
    _loadExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(ApiService.getGroup(widget.groupId)),
      );

      if (response.statusCode == 200) {
        setState(() {
          _groupData = jsonDecode(response.body);
          _isLoading = false;
        });

        // Try to load target if draw is complete and we have participant ID
        if (_groupData!['drawn'] == true && widget.participantId != null) {
          _loadMyTarget();
        }
      } else {
        throw Exception('Failed to load group');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMyTarget() async {
    try {
      final response = await http.get(
        Uri.parse(ApiService.getMyTarget(widget.groupId, widget.participantId!)),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _myTarget = data['name'];
          _myTargetWishlist = data['wishlist'];
        });
      }
    } catch (e) {
      // Silently fail - user might not have been assigned yet
    }
  }

  Future<void> _loadExclusions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/groups/${widget.groupId}/exclusions'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _exclusions = List<Map<String, dynamic>>.from(data['exclusions']);
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/groups/${widget.groupId}/expenses'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _budgetData = data;
          _expenses = List<Map<String, dynamic>>.from(data['expenses'] ?? []);
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _performDraw() async {
    setState(() => _isDrawing = true);

    try {
      final response = await http.post(
        Uri.parse(ApiService.drawNames(widget.groupId)),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Names drawn! 🎄')),
          );
          _loadGroupDetails(); // Reload to show new state
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to draw names');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDrawing = false);
      }
    }
  }

  void _shareGroup() {
    final shareLink = 'https://yourdomain.com/join/${widget.groupId}';
    Share.share(
      'Join my Secret Santa group on DrawJoy!\n\n$shareLink',
      subject: 'Join ${_groupData!['name']} on DrawJoy',
    );
  }

  Future<void> _editWishlist(int participantId, String currentWishlist) async {
    final controller = TextEditingController(text: currentWishlist);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Wishlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your wishlist items...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final response = await http.put(
          Uri.parse('${ApiService.baseUrl}/participants/$participantId/wishlist?wishlist=${Uri.encodeComponent(result)}'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wishlist updated!')),
          );
          _loadGroupDetails();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addExclusion() async {
    final participants = _groupData!['participants'] as List;
    int? giverId;
    int? receiverId;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Exclusion Rule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Prevent this pairing:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Person',
                  border: OutlineInputBorder(),
                ),
                items: participants.map((p) => DropdownMenuItem(
                  value: p['id'],
                  child: Text(p['name']),
                )).toList(),
                onChanged: (value) => setState(() => giverId = value),
              ),
              const SizedBox(height: 12),
              const Text('Cannot give to:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Person',
                  border: OutlineInputBorder(),
                ),
                items: participants.map((p) => DropdownMenuItem(
                  value: p['id'],
                  child: Text(p['name']),
                )).toList(),
                onChanged: (value) => setState(() => receiverId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: giverId != null && receiverId != null
                  ? () => Navigator.pop(context, {'giver_id': giverId!, 'receiver_id': receiverId!})
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/groups/${widget.groupId}/exclude?giver_id=${result['giver_id']}&receiver_id=${result['receiver_id']}'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exclusion added!')),
          );
          _loadExclusions();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addExpense() async {
    final participants = _groupData!['participants'] as List;
    int? participantId;
    final amountController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Who spent',
                  border: OutlineInputBorder(),
                ),
                items: participants.map((p) => DropdownMenuItem(
                  value: p['id'],
                  child: Text(p['name']),
                )).toList(),
                onChanged: (value) => setState(() => participantId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (participantId != null && amountController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'participant_id': participantId!,
                    'amount': double.parse(amountController.text),
                    'description': descController.text.isEmpty ? null : descController.text,
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/groups/${widget.groupId}/expenses'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(result),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added!')),
          );
          _loadExpenses();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: const Text('This will permanently delete the group and all its data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiService.baseUrl}/groups/${widget.groupId}'),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group deleted')),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeParticipant(int participantId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Participant?'),
        content: Text('Remove $name from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiService.baseUrl}/participants/$participantId'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Participant removed')),
          );
          _loadGroupDetails();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _groupData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final participants = _groupData!['participants'] as List;
    final isDrawn = _groupData!['drawn'] as bool;

    return Scaffold(
      appBar: AppBar(
        title: Text(_groupData!['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareGroup,
            tooltip: 'Share invite link',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              if (!isDrawn)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Group', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'refresh') {
                _loadGroupDetails();
                _loadExclusions();
                _loadExpenses();
              } else if (value == 'delete') {
                _deleteGroup();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Participants'),
            Tab(icon: Icon(Icons.block), text: 'Exclusions'),
            Tab(icon: Icon(Icons.attach_money), text: 'Budget'),
            Tab(icon: Icon(Icons.info), text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Participants Tab
          _buildParticipantsTab(participants, isDrawn),
          
          // Exclusions Tab
          _buildExclusionsTab(isDrawn),
          
          // Budget Tab
          _buildBudgetTab(),
          
          // Info Tab
          _buildInfoTab(participants, isDrawn),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(List participants, bool isDrawn) {
    return Column(
      children: [
        // My Target Card (if drawn)
        if (isDrawn && _myTarget != null)
          Card(
            margin: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You\'re buying for:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _myTarget!,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  if (_myTargetWishlist != null && _myTargetWishlist!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Wishlist:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _myTargetWishlist!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Participants List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final p = participants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(p['name'][0].toUpperCase()),
                  ),
                  title: Text(p['name']),
                  subtitle: p['wishlist'] != null
                      ? Text(
                          p['wishlist'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : const Text('No wishlist yet'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      if (p['id'] == widget.participantId)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit Wishlist'),
                            ],
                          ),
                        ),
                      if (!isDrawn)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove'),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editWishlist(p['id'], p['wishlist'] ?? '');
                      } else if (value == 'remove') {
                        _removeParticipant(p['id'], p['name']);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // Draw Button
        if (!isDrawn)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: participants.length >= 2 && !_isDrawing
                    ? _performDraw
                    : null,
                icon: _isDrawing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shuffle),
                label: Text(_isDrawing ? 'Drawing...' : '🎁 Draw Names'),
              ),
            ),
          ),

        if (!isDrawn && participants.length < 2)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Need at least 2 participants to draw names',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildExclusionsTab(bool isDrawn) {
    return Column(
      children: [
        if (!isDrawn)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Exclusion rules prevent specific pairings (e.g., couples, roommates).',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _addExclusion,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exclusion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: _exclusions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No exclusions set',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Everyone can be paired with anyone',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exclusions.length,
                  itemBuilder: (context, index) {
                    final e = _exclusions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.block, color: Colors.red),
                        title: Text('${e['giver_name']} → ${e['receiver_name']}'),
                        subtitle: const Text('Cannot be paired'),
                        trailing: !isDrawn
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await http.delete(
                                      Uri.parse('${ApiService.baseUrl}/exclusions/${e['id']}'),
                                    );
                                    _loadExclusions();
                                  } catch (err) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to delete')),
                                    );
                                  }
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBudgetTab() {
    final budget = _budgetData?['budget'];
    final totalSpent = _budgetData?['total_spent'] ?? 0.0;
    final remaining = _budgetData?['remaining'];

    return Column(
      children: [
        if (budget != null)
          Card(
            margin: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BudgetStat('Budget', '\$${budget.toStringAsFixed(2)}'),
                      _BudgetStat('Spent', '\$${totalSpent.toStringAsFixed(2)}'),
                      if (remaining != null)
                        _BudgetStat(
                          'Remaining',
                          '\$${remaining.toStringAsFixed(2)}',
                          color: remaining < 0 ? Colors.red : Colors.green,
                        ),
                    ],
                  ),
                  if (budget > 0) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (totalSpent / budget).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        totalSpent > budget ? Colors.red : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: _addExpense,
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No expenses yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final e = _expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('\$'),
                        ),
                        title: Text(e['participant_name']),
                        subtitle: e['description'] != null ? Text(e['description']) : null,
                        trailing: Text(
                          '\$${e['amount'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(List participants, bool isDrawn) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),
                _InfoRow('Group Code', widget.groupId.toString()),
                const SizedBox(height: 12),
                _InfoRow('Participants', '${participants.length}'),
                const SizedBox(height: 12),
                _InfoRow('Status', isDrawn ? '✅ Names Drawn' : '⏳ Waiting'),
                if (_groupData!['budget'] != null) ...[
                  const SizedBox(height: 12),
                  _InfoRow('Budget', '\$${_groupData!['budget']}'),
                ],
                const SizedBox(height: 12),
                _InfoRow('Exclusions', '${_exclusions.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(height: 24),
                _FeatureItem('✅ Smart derangement algorithm'),
                _FeatureItem('✅ Wishlist support'),
                _FeatureItem('✅ Exclusion rules'),
                _FeatureItem('✅ Budget tracking'),
                _FeatureItem('✅ Email notifications'),
                _FeatureItem('✅ Private assignments'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _BudgetStat(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text),
    );
  }
}
