import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? icon;
  final TextInputType keyboardType;

  final Color? textColor;
  final Color? hintColor;
  final Color? iconColor;
  final Color? fillColor;
  final Color? borderColor;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.textColor,
    this.hintColor,
    this.iconColor,
    this.fillColor,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor ?? const Color(0xFFDDE6FF),
        borderRadius: BorderRadius.circular(30),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: 'NeuraDisplay',
          fontSize: 16,
          color: textColor ?? const Color(0xFF2563EB),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'NeuraDisplay',
            color: hintColor ?? const Color(0xFF2563EB).withOpacity(0.5),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon:
              icon != null
                  ? Icon(
                    icon,
                    color:
                        iconColor ?? const Color(0xFF2563EB).withOpacity(0.7),
                  )
                  : null,
          suffixIcon:
              isPassword
                  ? Icon(
                    Icons.visibility_off_outlined,
                    color:
                        iconColor ?? const Color(0xFF2563EB).withOpacity(0.7),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
