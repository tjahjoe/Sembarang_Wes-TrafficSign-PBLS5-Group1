import 'package:flutter/material.dart';

class UsernameField extends StatelessWidget {
  final void Function(String value) onChanged;

  const UsernameField({super.key, this.onChanged = _emptyFunction});

  static void _emptyFunction(String value) {}

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: 'Username',
        labelStyle: const TextStyle(
          color: Color(0xFFE0E0E0),
        ),
        hintText: 'Masukkan username',
        hintStyle: const TextStyle(
          color: Color(0xFFCCCCCC),
        ),

        filled: true,
        fillColor: Colors.black26,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.amber.shade400,
            width: 1.2,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.amber.shade400,
            width: 1.2,
          ),
        ),
      ),
      onChanged: onChanged,
    );
  }
}