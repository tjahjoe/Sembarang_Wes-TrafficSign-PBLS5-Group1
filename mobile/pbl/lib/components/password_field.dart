import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final void Function(String value) onChanged;
  const PasswordField({super.key, this.onChanged = _emptyFunction});
  static void _emptyFunction(String value) {}

  @override
  State<StatefulWidget> createState() {
    return _PasswordFieldState();
  }
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  void _toggleVisibilityIconButton() {
    setState(() {
      _obscure = !_obscure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: _obscure,

      style: const TextStyle(
        color: Colors.white,
      ),

      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(
          color: Color(0xFFE0E0E0),
        ),
        hintText: 'Masukkan password',
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

        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: _toggleVisibilityIconButton,
        ),
      ),

      onChanged: widget.onChanged,
    );
  }
}