import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';

class CreateAccountScreen extends StatefulWidget {
  final String profileId;
  final String code;
  final String accountType;
  final String accountNature;
  final bool isFinal;

  const CreateAccountScreen({
    super.key,
    required this.profileId,
    required this.code,
    required this.accountType,
    required this.accountNature,
    required this.isFinal,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      try {
        // TODO: Figure out how to generate the account code.
        // It probably depends on the parentCode and the existing sibling accounts.
        // For now, this will likely fail if the backend requires a code.
        final accountData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'code': widget.code, 
          'nature': widget.accountNature,
          'type': widget.accountType,
          'final': widget.isFinal,
          'balance': 0,
        };

        await _apiService.createAccount(widget.profileId, accountData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create account: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onJournalsChanged: (_) {},
        onFetchingJournalsChanged: (_) {},
        onSelectedProfileChanged: (_) {},
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create New Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isCreating)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _createAccount,
                  child: const Text('Create Account'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
