import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:frontend/models/account_data.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';

class CreateAccountScreen extends StatefulWidget {
  final String profileId;
  final String code;
  final String parentCode;
  final String accountType;
  final String accountNature;
  final bool isFinal;

  const CreateAccountScreen({
    super.key,
    required this.profileId,
    required this.code,
    required this.parentCode,
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
  bool _withInterest = false;
  bool _withInsurance = false;

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
        final accountPayload = AccountData(
          name: _nameController.text,
          description: _descriptionController.text,
          code: widget.code,
          nature: widget.accountNature,
          type: widget.accountType,
          isFinal: widget.isFinal,
          balance: 0,
          withInterest: _withInterest,
          withInsurance: _withInsurance,
        ).toJson();

        await _apiService.createAccount(widget.profileId, accountPayload);

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
        onDashboardInformationChanged: (_) {},
        onFetchingDashboardInformationChanged: (_) {},
        onSelectedProfileChanged: (_) {},
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create New Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
              if (widget.parentCode == '2.1.02.') ...[
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text('With Interest'),
                  value: _withInterest,
                  onChanged: (newValue) {
                    setState(() {
                      _withInterest = newValue!;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('With Insurance'),
                  value: _withInsurance,
                  onChanged: (newValue) {
                    setState(() {
                      _withInsurance = newValue!;
                    });
                  },
                ),
              ],
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
