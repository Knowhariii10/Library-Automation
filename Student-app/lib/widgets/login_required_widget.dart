import 'package:flutter/material.dart';
import '../screens/auth/auth_screen.dart';

class LoginRequiredWidget extends StatelessWidget {
  final String message;
  const LoginRequiredWidget({
    super.key,
    this.message = 'Please login to access this section',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                shape:
                    RoundedRectanglePlatform.isAndroid ||
                        RoundedRectanglePlatform.isIOS
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      )
                    : null, // Basic fallback
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              child: const Text('LOGIN / SIGNUP'),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple fallback for platform check since we can't use dart:io easily in all contexts
class RoundedRectanglePlatform {
  static bool get isAndroid => true; // Close enough for this context
  static bool get isIOS => false;
}
