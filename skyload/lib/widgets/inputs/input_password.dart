import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InputPassword extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final EdgeInsets margin;
  final dynamic textoAdicional;
  final dynamic formatearInput;
  final dynamic onChanged;
  final bool readOnly;
  final dynamic textColor;
  final Color colorInput;

  const InputPassword({
    super.key,
    required this.controller,
    required this.keyboardType,
    required this.margin,
    required this.textColor,
    required this.colorInput,
    this.textoAdicional,
    this.formatearInput,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<InputPassword> createState() => _InputPasswordState();
}

class _InputPasswordState extends State<InputPassword> {
  bool _visible = false; 

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: TextField(
        readOnly: widget.readOnly,
        style: GoogleFonts.manrope(
          color: widget.textColor,
          fontSize: MediaQuery.of(context).size.width * 0.035,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          height: 1.5,
        ),
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: !_visible,
        onChanged: widget.onChanged,
        inputFormatters: widget.formatearInput != null ? [widget.formatearInput] : [],
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.015,
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          filled: true,
          fillColor: widget.colorInput,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.white, 
              width: 1
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.white, 
              width: 1
            ),
          ),
          hintStyle: const TextStyle(color: Color(0xFFABB3B8)),
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _visible = !_visible; 
              });
            },
            child: Icon(_visible ? Icons.visibility : Icons.visibility_off),
          ),
        ),
      ),
    );
  }
}
