
import 'package:flutter/material.dart';
import 'package:skyload/utils/funciones.dart';
import 'package:skyload/widgets/texts/texto_manrope.dart';

class BotonPrincipal extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final Alignment alignment;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final dynamic margin;
  final Color? backgroundColor;

  const BotonPrincipal(
    {
      super.key,
      required this.buttonText,
      required this.onPressed,
      required this.alignment,
      required this.textColor,
      required this.fontSize,
      required this.margin,
      required this.fontWeight,
      this.backgroundColor
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: alignment,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          backgroundColor: WidgetStateProperty.all<Color?>(
            backgroundColor ?? colorPrincipal,
          ),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.height * 0.06,
            ),
          ),
        ),
        child: TextoManrope(
          text: buttonText, 
          fontSize: fontSize, 
          margin: margin, 
          textColor: textColor, 
          fontWeight: fontWeight, 
          alignment: alignment
        )
      ),
    );
  }
}