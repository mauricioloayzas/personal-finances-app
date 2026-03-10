import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final bool enabled;
  final TextInputType keyboardType;
  // 1. Agregamos la propiedad requerida
  final bool isRequired;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.isRequired = false, // Por defecto no es requerido
  });

  @override
  Widget build(BuildContext context) {
    const customColor = Color(0xFFFFECB3);
    const focusColor = Color(0xFFFFD700);

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      keyboardType: keyboardType == TextInputType.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },

      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label, // Agrega un asterisco visual si es requerido
        labelStyle: const TextStyle(color: customColor),
        floatingLabelStyle: const TextStyle(color: focusColor),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: customColor, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: focusColor, width: 2.0),
        ),
        // Estilo cuando hay un error de validación
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}