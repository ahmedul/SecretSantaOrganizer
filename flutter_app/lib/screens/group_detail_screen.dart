import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
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

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  String? _myTarget;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
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
        });
      }
    } catch (e) {
      // Silently fail - user might not have been assigned yet
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGroupDetails,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroupDetails,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Group Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Group Info',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow('Group Code', widget.groupId.toString()),
                    const SizedBox(height: 8),
                    _InfoRow('Participants', '${participants.length}'),
                    const SizedBox(height: 8),
                    _InfoRow('Status', isDrawn ? '✅ Names Drawn' : '⏳ Waiting'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // My Target Card (if drawn)
            if (isDrawn && _myTarget != null) ...[
              Card(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Participants List
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...participants.map((p) => Card(
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
                    trailing: p['wishlist'] != null
                        ? const Icon(Icons.list_alt)
                        : null,
                  ),
                )),
            const SizedBox(height: 24),

            // Draw Button (only if not drawn yet)
            if (!isDrawn)
              SizedBox(
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
                  label: Text(_isDrawing ? 'Drawing...' : 'Draw Names'),
                ),
              ),

            if (!isDrawn && participants.length < 2)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Need at least 2 participants to draw names',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        ),
      ),
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
