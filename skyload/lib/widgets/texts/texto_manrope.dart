import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextoManrope extends StatelessWidget {
  final String text;
  final EdgeInsets margin;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final Alignment alignment;
  final TextAlign? textAlign;

  const TextoManrope(
    {
      super.key,
      required this.text,
      required this.fontSize,
      required this.margin,
      required this.textColor,
      required this.fontWeight,
      required this.alignment,
      this.textAlign
    }
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      alignment: alignment,
      child: Text(
        text,
        textAlign: textAlign,
        style: GoogleFonts.manrope(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: -0.01,
          height: 1.5,
        ),
        softWrap: true,
      ),
    );
  }
}