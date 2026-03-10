import 'package:flutter/material.dart';
import 'package:mifinper/screens/transactions/list_transactions_screen.dart';
import 'package:mifinper/screens/transactions/transaction_screen.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/custom_text_field.dart';
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _balanceValueController = TextEditingController();
  final _newBalanceValueController = TextEditingController();
  Map<String, dynamic> _accountDetail = {};
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
      _accountDetail = await _apiService.getAccountProfileDetails(
          widget.profileId, widget.accountId);

      setState(() {
        _nameController.text = _accountDetail['name'] ?? '';
        _descriptionController.text = _accountDetail['description'] ?? '';
        _balanceValueController.text =
            _accountDetail['balance']?.toString() ?? '0';
        _newBalanceValueController.text = '0';
        _currentBalance = num.tryParse(_balanceValueController.text) ?? 0;
        _accountId = _accountDetail['id'];

        if (_currentBalance != 0) {
          _isBalanceFieldVisible = true;
        }

        _canBePaid = _accountDetail.containsKey('can_be_paid') ? true : false;
        _canBeAdjusted =
            _accountDetail.containsKey('can_be_adjusted') ? true : false;
        if (_canBePaid) {
          _canBePaidOnlyCash =
              _accountDetail.containsKey('paid_only_cash') ? true : false;
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
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Account',
                                style:
                                    Theme.of(context).textTheme.displayLarge),
                            const SizedBox(height: 20),
                            _buildTextField(_nameController, 'Name'),
                            const SizedBox(height: 20),
                            _buildTextField(
                                _descriptionController, 'Description'),
                            const SizedBox(height: 20),
                            _buildTextField(_balanceValueController, 'Balance',
                                enabledField:
                                    !_isBalanceFieldVisible && _canBeAdjusted,
                                isNumeric: true),
                            const SizedBox(height: 20),
                            Visibility(
                              visible:
                                  _isBalanceFieldVisible && _canBeAdjusted,
                              child: _buildTextField(
                                  _newBalanceValueController, 'Adjust',
                                enabledField: true,
                                isNumeric: true),
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
                                        builder: (context) =>
                                            TransactionScreen(
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
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ListTransactionsScreen(
                                        accountId: _accountId,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('See Transactions'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool enabledField = true, bool isNumeric = false}) {
    return CustomTextField(
      enabled: enabledField,
      controller: controller,
      label: label,
      keyboardType: (!isNumeric) ? TextInputType.text : TextInputType.number,
      isRequired: true,
    );
  }
}
