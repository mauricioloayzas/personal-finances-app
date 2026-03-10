import 'package:flutter/material.dart';
import 'package:mifinper/models/journal_entry.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_account_selector.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/custom_text_field.dart';
import 'package:mifinper/widgets/main_layout.dart';

class AnotherTransaction extends StatefulWidget {
  const AnotherTransaction({
    super.key,
  });

  @override
  State<AnotherTransaction> createState() => _AnotherTransactionState();
}

class _AnotherTransactionState extends State<AnotherTransaction> {
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

  void _showAccountSelector(
    BuildContext context,
    Function(String) onAccountSelected,
  ) {
    // A stateful builder is used to manage the search query state within the modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            final filteredAccounts = _accounts.where((account) {
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
                              onAccountSelected(account['id']);
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
    return MainLayout(
      appBar: CustomAppBar(
        onDashboardInformationChanged: (_) {},
        onFetchingDashboardInformationChanged: (_) {},
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
                            Text(
                              'Crear Transaccion',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(_descriptionController, 'Descripción'),
                            const SizedBox(height: 20),
                            _buildTextField(
                              _valueController,
                              'Valor de la transacción',
                              isNumeric: true
                            ),
                            const SizedBox(height: 20),
                            CustomAccountSelector(
                              label: 'Selecciona una cuenta debito',
                              accounts: _accounts,
                              selectedAccountId: _selectedDebitAccount,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDebitAccount = newValue;
                                });
                              },
                              onTapMobile: () => _showAccountSelector(context, (accountId) {
                                      setState(() {
                                        _selectedCreditAccount = accountId;
                                      });
                                    }),
                              validator: (value) => value == null ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 20),
                            CustomAccountSelector(
                              label: 'Selecciona una cuenta debito',
                              accounts: _accounts,
                              selectedAccountId: _selectedCreditAccount,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCreditAccount = newValue;
                                });
                              },
                              onTapMobile: () => _showAccountSelector(context, (accountId) {
                                      setState(() {
                                        _selectedCreditAccount = accountId;
                                      });
                                    }),
                              validator: (value) => value == null ? 'Campo requerido' : null,
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
              },
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    {isNumeric = false}
  ) {
    return CustomTextField(
      controller: controller,
      label: label,
      isPassword: false,
      keyboardType: (!isNumeric) ? TextInputType.text : TextInputType.number,
      isRequired: true,
    );
  }
}
