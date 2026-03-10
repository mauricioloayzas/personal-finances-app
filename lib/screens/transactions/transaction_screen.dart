import 'package:flutter/material.dart';
import 'package:mifinper/core/enums.dart';
import 'package:mifinper/models/journal_entry.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_account_selector.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/custom_text_field.dart';
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
      if (account['type'] != AccountType.liability.name &&
          account['type'] != AccountType.income.name) {
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

  void _showAccountSelector(BuildContext context) {
    // A stateful builder is used to manage the search query state within the modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            final filteredAccounts = _accountsToPaid.where((account) {
              return account['name']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              maxChildSize: 0.9,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) {
                          setStateModal(() {
                            searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Search Accounts',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredAccounts.length,
                        itemBuilder: (BuildContext context, int index) {
                          final account = filteredAccounts[index];
                          return ListTile(
                            title: Text(account['name']),
                            onTap: () {
                              setState(() {
                                _selectedAccountToPaid = account['id'];
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
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
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 600
                          ? 600
                          : constraints.maxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titleWidget,
                                style:
                                    Theme.of(context).textTheme.displayLarge),
                            const SizedBox(height: 20),
                            _buildTextField(
                                _descriptionController, 'Description'),
                            const SizedBox(height: 20),
                            _buildTextField(
                              _valueController,
                              'Transaction value',
                              isNumeric: true
                            ),
                            const SizedBox(height: 20),
                            CustomAccountSelector(
                              label: 'Selecciona una cuenta para pagar',
                              accounts: _accountsToPaid,
                              selectedAccountId: _selectedAccountToPaid,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedAccountToPaid = newValue;
                                });
                              },
                              onTapMobile: () => _showAccountSelector(context),
                              validator: (value) => value == null ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 20),
                            if (_isCreating)
                              const Center(child: CircularProgressIndicator())
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _createTransaction,
                                  child: const Text('Guardar Transacción'),
                                ),
                              ),
                            const SizedBox(height: 20),
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
      {bool enabledField = true, isNumeric = false}) {
    return CustomTextField(
      enabled: enabledField,
      controller: controller,
      label: label,
      keyboardType: (!isNumeric) ? TextInputType.text : TextInputType.number,
      isRequired: true,
    );
  }
}
