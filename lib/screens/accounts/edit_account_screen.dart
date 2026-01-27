import 'package:flutter/material.dart';
import 'package:mifinper/screens/transactions/transaction_screen.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/main_layout.dart';

class EditAccountScreen extends StatefulWidget {
  final String accountId;
  final String profileId;

  const EditAccountScreen({
    super.key,
    required this.accountId,
    required this.profileId,
  });

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _balanceValueController = TextEditingController();
  final _newBalanceValueController = TextEditingController();
  String _accountId = "";
  num _currentBalance = 0;
  final _apiService = ApiService();
  bool _isCreating = false;
  bool _isLoading = true;
  bool _isBalanceFieldVisible = false;
  bool _canBeAdjusted = false;
  bool _canBePaid = false;
  bool _canBePaidOnlyCash = false;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _balanceValueController.dispose();
    _newBalanceValueController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountData() async {
    try {
      final details = await _apiService.getAccountProfileDetails(
          widget.profileId, widget.accountId);

      setState(() {
        _nameController.text = details['name'] ?? '';
        _descriptionController.text = details['description'] ?? '';
        _balanceValueController.text = details['balance']?.toString() ?? '0';
        _newBalanceValueController.text = '0';
        _currentBalance = num.tryParse(_balanceValueController.text) ?? 0;
        _accountId = details['id'];

        if (_currentBalance != 0) {
          _isBalanceFieldVisible = true;
        }

        _canBePaid = details.containsKey('can_be_paid') ? true : false;
        _canBeAdjusted = details.containsKey('can_be_adjusted') ? true : false;
        if (_canBePaid) {
          _canBePaidOnlyCash =
              details.containsKey('paid_only_cash') ? true : false;
        }

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

  Future<void> _editAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      num journalValue = 0;
      if (num.tryParse(_newBalanceValueController.text) != 0) {
        journalValue = num.tryParse(_newBalanceValueController.text) ?? 0;
      } else {
        journalValue = num.tryParse(_balanceValueController.text) ?? 0;
      }

      final accountData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'journal_value': journalValue
      };

      await _apiService.editAccount(
          widget.profileId, widget.accountId, accountData);

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
                      const Text('Edit Account',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTextField(_nameController, 'Name'),
                      const SizedBox(height: 20),
                      _buildTextField(_descriptionController, 'Description'),
                      const SizedBox(height: 20),
                      _buildTextField(_balanceValueController, 'Balance',
                          isNumber: true,
                          enabledField:
                              !_isBalanceFieldVisible && _canBeAdjusted),
                      const SizedBox(height: 20),
                      Visibility(
                        visible: _isBalanceFieldVisible && _canBeAdjusted,
                        child: _buildTextField(
                            _newBalanceValueController, 'Adjust',
                            isNumber: true),
                      ),
                      const SizedBox(height: 20),
                      if (_isCreating)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _editAccount,
                            child: const Text('Save Changes'),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (_canBePaid)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionScreen(
                                    profileId: widget.profileId,
                                    accountId: _accountId,
                                    onlyCash: _canBePaidOnlyCash,
                                  ),
                                ),
                              ).then((_) async {
                                await _loadAccountData();
                              });
                            },
                            child: const Text('Add a transaction'),
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
