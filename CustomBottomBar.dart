import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final VoidCallback? onNavigate;
  final VoidCallback? onScan;
  final VoidCallback? onProfile;

  const CustomBottomBar({
    Key? key,
    this.onNavigate,
    this.onScan,
    this.onProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    // Ensure minimum padding for gesture nav
    final double safeBottom = bottomPadding < 0 ? 0.0 : bottomPadding;
    return
      Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, -6), // shadow only on top
            ),
          ],
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            // Radius.circular(35),
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        child: Padding(
          padding:  EdgeInsets.only(
            left: 40,
            right: 40,
            top: 15,
            bottom: 17+safeBottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onNavigate,
                child: Image.asset(
                  'assets/images/nav-home.png',
                  height: 25,
                  width: 25,
                ),
              ),
              InkWell(
                onTap: onScan,
                child: const Icon(Icons.qr_code_scanner, size: 25.0),
              ),
              InkWell(
                onTap: onProfile,
                child: const Icon(Icons.account_circle, size: 25.0),
              ),
            ],
          ),
        ),

      );
  }
}