import 'package:flutter/material.dart';
import 'package:mifinper/core/enums.dart';
import 'package:mifinper/models/journal_entry.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/main_layout.dart';

class TransactionScreen extends StatefulWidget {
  final String accountId;
  final String profileId;
  final bool onlyCash;

  const TransactionScreen({
    super.key,
    required this.accountId,
    required this.profileId,
    required this.onlyCash,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _apiService = ApiService();
  List<dynamic> _accountsToPaid = [];
  Map<String, dynamic> _account = {};
  bool _isCreating = false;
  bool _isLoading = true;
  String? _selectedAccountToPaid;

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
      final account = await _apiService.getAccountProfileDetails(
          widget.profileId, widget.accountId);
      List<dynamic> accountsToPaid = await _apiService.fetchAccounts(
          widget.profileId, "1.1.01",
          isOnlyParent: false, isOnlyFinal: true);
      if (account['type'] != AccountType.liability.name) {
        List<dynamic> creditcardAccounts = await _apiService.fetchAccounts(
            widget.profileId, "2.1.01",
            isOnlyParent: false, isOnlyFinal: true);
        accountsToPaid.addAll(creditcardAccounts);
      }

      setState(() {
        _accountsToPaid = accountsToPaid;
        _account = account;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      num journalValue = num.tryParse(_valueController.text) ?? 0;

      List<JournalEntry> entries = [];
      if (_account['type'] == AccountType.income.name) {
        entries = [
          JournalEntry(
              accountId: _selectedAccountToPaid!,
              debitValue: journalValue,
              creditValue: 0),
          JournalEntry(
              accountId: widget.accountId,
              debitValue: 0,
              creditValue: journalValue)
        ];
      } else {
        entries = [
          JournalEntry(
              accountId: widget.accountId,
              debitValue: journalValue,
              creditValue: 0),
          JournalEntry(
              accountId: _selectedAccountToPaid!,
              debitValue: 0,
              creditValue: journalValue)
        ];
      }

      await _apiService.createJournalEntry(widget.profileId,
          DateTime.now().toString(), _descriptionController.text, entries);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proceso completado con éxito')),
        );
        Navigator.pop(context);
      } else {
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la operación: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleWidget = "Transaction to ${_account['name']}";
    return MainLayout(
      appBar: CustomAppBar(
        onDashboardInformationChanged: (_) {},
        onFetchingDashboardInformationChanged: (_) {},
        onSelectedProfileChanged: (_) {},
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
                      Text(titleWidget,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTextField(_descriptionController, 'Description'),
                      const SizedBox(height: 20),
                      _buildTextField(
                        _valueController,
                        'Transaction value',
                        isNumber: true,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedAccountToPaid,
                        hint: const Text('Select account to paid'),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedAccountToPaid = newValue;
                          });
                        },
                        items: _accountsToPaid
                            .map<DropdownMenuItem<String>>((dynamic account) {
                          return DropdownMenuItem<String>(
                            value: account['id'],
                            child: Text(account['name']),
                          );
                        }).toList(),
                        validator: (value) =>
                            value == null ? 'Please select an account' : null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isCreating)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _createTransaction,
                            child: const Text('Save Transaction'),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false, bool enabledField = true}) {
    // 1. Intentamos parsear. Si no es un número, doubleValue será null.
    final doubleValue = num.tryParse(controller.text);

    // 2. Definimos el color como opcional (Color?)
    Color? dynamicColor;

    // 3. Solo aplicamos la lógica de color si es un campo numérico Y el valor es un número válido
    if (isNumber && doubleValue != null) {
      dynamicColor = doubleValue > 0 ? Colors.blue : Colors.red;
    }

    return TextFormField(
      enabled: enabledField,
      controller: controller,
      // style controla el color del texto escrito
      style: TextStyle(color: dynamicColor),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        // labelStyle controla el color del texto de la etiqueta
        labelStyle: TextStyle(color: dynamicColor),

        // Bordes con lógica de "fallback" (si es null, usa un color neutro o el del tema)
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: dynamicColor ??
                Colors.grey.shade400, // Color por defecto si no es número
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: dynamicColor ??
                Theme.of(context)
                    .primaryColor, // Color del tema si no es número
            width: 2.0,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: (dynamicColor ?? Colors.grey).withOpacity(0.5),
          ),
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Required field' : null,
      onChanged: (val) {
        // Forzamos el redibujado para que el color cambie mientras el usuario escribe
        if (isNumber) setState(() {});
      },
    );
  }
}
