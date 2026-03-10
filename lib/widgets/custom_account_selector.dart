import 'package:flutter/material.dart';

class CustomAccountSelector extends StatelessWidget {
  final List<dynamic> accounts;
  final String? selectedAccountId;
  final String label;
  final Function(String?) onChanged;
  final VoidCallback onTapMobile;
  final String? Function(String?)? validator;

  const CustomAccountSelector({
    super.key,
    required this.accounts,
    required this.selectedAccountId,
    required this.label,
    required this.onChanged,
    required this.onTapMobile,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos el color que ya estamos usando en los otros campos
    const customColor = Color(0xFFFFECB3);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Estilo común para mantener la coherencia visual
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
      // VISTA MÓVIL: Un campo que al tocarlo abre el modal
      final selectedAccount = accounts.firstWhere(
        (acc) => acc['id'] == selectedAccountId,
        orElse: () => null,
      );

      return InkWell(
        onTap: onTapMobile,
        child: InputDecorator(
          decoration: commonDecoration,
          child: Text(
            selectedAccount != null ? selectedAccount['name'] : 'Selecciona una opción',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } else {
      // VISTA DESKTOP/TABLET: Dropdown estándar
      return DropdownButtonFormField<String>(
        value: selectedAccountId,
        hint: Text(label, style: const TextStyle(color: customColor)),
        onChanged: onChanged,
        validator: validator,
        decoration: commonDecoration,
        dropdownColor: Colors.grey[900], // Ajusta según tu tema oscuro
        items: accounts.map<DropdownMenuItem<String>>((dynamic account) {
          return DropdownMenuItem<String>(
            value: account['id'],
            child: Text(
              account['name'],
              style: const TextStyle(color: Colors.white), // Ajusta el color del texto
            ),
          );
        }).toList(),
      );
    }
  }
}