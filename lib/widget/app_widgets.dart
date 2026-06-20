 import 'package:flutter/material.dart';
 

 
void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return PopScope(
        canPop: false,
         onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
      },
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(28),
              color: const Color(0xFF111827),
              border: Border.all(
                color:
                    Colors.greenAccent.withOpacity(
                      0.3,
                    ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent
                      .withOpacity(0.25),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        const LinearGradient(
                      colors: [
                        Colors.greenAccent,
                        Colors.teal,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent
                            .withOpacity(0.4),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.black,
                    size: 45,
                  ),
                ),
        
                const SizedBox(height: 24),
        
                const Text(
                  'LOADING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
        
                const SizedBox(height: 14),
        
                const CircularProgressIndicator(
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
 
   Widget walletButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: width * 0.18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.05),
          gradient: LinearGradient(
            colors: [
              glowColor.withOpacity(0.35),
              glowColor.withOpacity(0.12),
            ],
          ),
          border: Border.all(
            color: glowColor,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 25,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: glowColor,
                size: width * 0.07,
              ),

              SizedBox(width: width * 0.04),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: glowColor,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.04,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                color: glowColor,
                size: width * 0.045,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget secondaryButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: width * 0.16,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.05),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(
            color: Colors.purpleAccent.withOpacity(0.25),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: width * 0.06,
              ),

              SizedBox(width: width * 0.04),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.038,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: width * 0.04,
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget footerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final width = MediaQuery.of(context).size.width;

    return Flexible(
      child: Column(
        children: [
          Container(
            height: width * 0.16,
            width: width * 0.16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.purpleAccent.withOpacity(0.25),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.greenAccent,
              size: width * 0.07,
            ),
          ),

          SizedBox(height: width * 0.025),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.028,
            ),
          ),
        ],
      ),
    );
  }

 Widget glow({
    required Color color,
    required double size,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.8),
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
