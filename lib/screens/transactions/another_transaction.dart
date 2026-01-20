import 'package:flutter/material.dart';
import 'package:frontend/models/journal_entry.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';

class AnotherTransaction extends StatefulWidget {
  const AnotherTransaction({
    super.key,
  });

  @override
  State<AnotherTransaction> createState() => _AnotherTransactionState();
}

class _AnotherTransactionState extends State<AnotherTransaction> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _apiService = ApiService();
  String _selectedProfile = "";
  List<dynamic> _accounts = [];
  bool _isCreating = false;
  bool _isLoading = true;
  String? _selectedDebitAccount;
  String? _selectedCreditAccount;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      List<dynamic> accounts = await _apiService.fetchAccounts(
        _selectedProfile,
        "",
        isOnlyParent: false,
        isOnlyFinal: true,
      );
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar las cuentas: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      num journalValue = num.tryParse(_valueController.text) ?? 0;

      List<JournalEntry> entries = [
        JournalEntry(
          accountId: _selectedDebitAccount!,
          debitValue: journalValue,
          creditValue: 0,
        ),
        JournalEntry(
          accountId: _selectedCreditAccount!,
          debitValue: 0,
          creditValue: journalValue,
        ),
      ];

      await _apiService.createJournalEntry(
        _selectedProfile,
        DateTime.now().toString(),
        _descriptionController.text,
        entries,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción creada con éxito')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la transacción: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onJournalsChanged: (_) {},
        onFetchingJournalsChanged: (_) {},
        onSelectedProfileChanged: (profileId) {
          if (mounted) {
            setState(() {
              _selectedProfile = profileId ?? "";
              _loadAccounts();
            });
          }
        },
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crear Transaccion',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(_descriptionController, 'Descripción'),
                      const SizedBox(height: 20),
                      _buildTextField(
                        _valueController,
                        'Valor de la transacción',
                        isNumber: true,
                      ),
                      const SizedBox(height: 20),
                      _buildAccountDropdown(
                        'Cuenta de Débito',
                        _selectedDebitAccount,
                        (newValue) {
                          setState(() {
                            _selectedDebitAccount = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildAccountDropdown(
                        'Cuenta de Crédito',
                        _selectedCreditAccount,
                        (newValue) {
                          setState(() {
                            _selectedCreditAccount = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_isCreating)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveTransaction,
                            child: const Text('Guardar Transacción'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Campo requerido' : null,
    );
  }

  Widget _buildAccountDropdown(
    String hint,
    String? selectedAccount,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedAccount,
      hint: Text(hint),
      onChanged: onChanged,
      items: _accounts.map<DropdownMenuItem<String>>((dynamic account) {
        return DropdownMenuItem<String>(
          value: account['id'],
          child: Text(account['name']),
        );
      }).toList(),
      validator: (value) =>
          value == null ? 'Por favor seleccione una cuenta' : null,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }
}
