import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'group_detail_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  final int? groupId; // Can be passed from deep link

  const JoinGroupScreen({super.key, this.groupId});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _wishlistController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      _groupIdController.text = widget.groupId.toString();
    }
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _wishlistController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final groupId = int.parse(_groupIdController.text);
      final response = await http.post(
        Uri.parse(ApiService.joinGroup(groupId)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text.isEmpty ? null : _emailController.text,
          'wishlist': _wishlistController.text.isEmpty ? null : _wishlistController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final participantId = data['id'];

        // Save participant info locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('participant_id_$groupId', participantId);
        await prefs.setString('participant_name_$groupId', _nameController.text);

        // Save to group history
        final groupsJson = prefs.getString('my_groups') ?? '[]';
        final List<dynamic> groups = jsonDecode(groupsJson);
        // Check if group already exists
        final existingIndex = groups.indexWhere((g) => g['group_id'] == groupId);
        if (existingIndex == -1) {
          groups.add({
            'group_id': groupId,
            'name': 'Group $groupId', // Will be updated when viewing
            'my_participant_id': participantId,
            'joined_at': DateTime.now().toIso8601String(),
            'role': 'participant',
          });
          await prefs.setString('my_groups', jsonEncode(groups));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully joined! 🎉')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                groupId: groupId,
                participantId: participantId,
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to join group');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join a Secret Santa group',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the group code and your details',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              
              // Group ID
              TextFormField(
                controller: _groupIdController,
                decoration: const InputDecoration(
                  labelText: 'Group Code',
                  hintText: 'Enter the code from your invite',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the group code';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Your Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'How should others see you?',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Email (Optional)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'For notifications',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              
              // Wishlist (Optional)
              TextFormField(
                controller: _wishlistController,
                decoration: const InputDecoration(
                  labelText: 'Wishlist (optional)',
                  hintText: 'Gift ideas for your Secret Santa',
                  prefixIcon: Icon(Icons.list),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              // Join Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _joinGroup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
