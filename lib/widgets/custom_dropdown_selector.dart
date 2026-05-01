import 'package:flutter/material.dart';

class CustomDropdownSelector extends StatelessWidget {
  final List<dynamic> items;
  final String? selectedId;
  final String label;
  final Function(String?) onChanged;
  final String Function(dynamic)? itemLabel;
  final String? Function(String?)? validator;
  final bool enabled;

  const CustomDropdownSelector({
    super.key,
    required this.items,
    required this.selectedId,
    required this.label,
    required this.onChanged,
    this.itemLabel,
    this.validator,
    this.enabled = true,
  });

  String _getLabel(dynamic item) {
    if (itemLabel != null) return itemLabel!(item);
    return item['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    const customColor = Color(0xFFFFECB3);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final commonDecoration = InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: customColor),
      floatingLabelStyle: const TextStyle(color: Color(0xFFFFD700)),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: customColor, width: 1.0),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFFD700), width: 2.0),
      ),
      border: const OutlineInputBorder(),
    );

    if (isSmallScreen) {
      final selectedItem = items.firstWhere(
        (item) => item['id'] == selectedId,
        orElse: () => null,
      );

      return InkWell(
        onTap: enabled ? () => _showSelector(context) : null,
        child: InputDecorator(
          decoration: commonDecoration,
          child: Text(
            selectedItem != null
                ? _getLabel(selectedItem)
                : 'Selecciona una opción',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      return DropdownButtonFormField<String>(
        value: items.any((item) => item['id'] == selectedId) ? selectedId : null,
        hint: Text(label, style: const TextStyle(color: customColor)),
        onChanged: enabled ? onChanged : null,
        validator: validator,
        decoration: commonDecoration,
        dropdownColor: Colors.grey[900],
        items: items.map<DropdownMenuItem<String>>((dynamic item) {
          return DropdownMenuItem<String>(
            value: item['id'],
            child: Text(
              _getLabel(item),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      );
    }
  }

  void _showSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        String searchQuery = "";
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            final filteredItems = items.where((item) {
              return _getLabel(item)
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
                          labelText: 'Buscar',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredItems.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = filteredItems[index];
                          return ListTile(
                            title: Text(_getLabel(item)),
                            onTap: () {
                              onChanged(item['id']);
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
}
