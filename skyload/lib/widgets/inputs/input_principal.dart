
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class InputPrincipal extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final EdgeInsets margin;
  final dynamic textoAdicional;
  final dynamic formatearInput;
  final dynamic onChanged;
  final dynamic readOnly;
  final dynamic textColor;
  final dynamic colorInput;
  

  const InputPrincipal (
    {
      super.key, 
      required this.controller,
      required this.keyboardType,
      required this.margin,
      required this.textColor,
      required this.colorInput,
      this.textoAdicional,
      this.formatearInput,
      this.onChanged,
      this.readOnly
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: TextField(
        readOnly: readOnly != null ? true : false,
        style: GoogleFonts.manrope(
          color: textColor,
          fontSize: MediaQuery.of(context).size.width * 0.035,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          height: 1.5,
        ),
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.015, 
            horizontal: MediaQuery.of(context).size.width * 0.05
          ),
          filled: true,
          fillColor: colorInput,
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
          suffix: textoAdicional!= null ? Padding(
            padding: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.05),
            child: Text(
              textoAdicional,
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.01,
                height: 1.5,
              ), 
            ),
          ) : null,
        ),
      ),
    );
  }
}