import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5001';

    // IMPORTANT: Change this to your computer's local IP for physical devices
    // Example: static const String computerIp = '192.168.1.5';
    const String computerIp = '10.42.99.143';

    // For Android physical devices or if you know your IP:
    return 'http://$computerIp:5001';
    // return "http://10.42.99.143:5001";
  }

  static String getImageUrl(String path) {
    if (path.isEmpty) return '';
    // Handle cases where the path might already contain 'books_img/'
    final cleanPath = path.startsWith('books_img/')
        ? path.replaceFirst('books_img/', '')
        : path;
    return '$baseUrl/books_img/$cleanPath';
  }

  Future<List<dynamic>> getBooks() async {
    try {
      print('DEBUG: ApiService.getBooks calling $baseUrl/user/books');
      final response = await http.get(Uri.parse('$baseUrl/user/books'));
      print(
        'DEBUG: ApiService.getBooks response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          'DEBUG: ApiService.getBooks parsed data success: ${data['success']}',
        );

        if (data is Map && data['success'] == true) {
          final booksList = data['books'];
          if (booksList is List) {
            print(
              'DEBUG: ApiService.getBooks returning ${booksList.length} books',
            );
            return booksList;
          }
        }
      }
      print('DEBUG: ApiService.getBooks failed or returned unexpected format');
      return [];
    } catch (e) {
      print('DEBUG: ApiService.getBooks error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBookByBarcode(String barcode) async {
    try {
      print(
        'DEBUG: ApiService.getBookByBarcode calling $baseUrl/user/books/by-barcode/$barcode',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/user/books/by-barcode/$barcode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('DEBUG: ApiService.getBookByBarcode error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> studentLogin(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/student/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/student/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );
      if (response.statusCode == 201 || response.statusCode == 400) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Registration error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> guestRegister(
    String name,
    String email,
    String purpose,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/student/guest-register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'purpose': purpose}),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Guest registration error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/student/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Forgot password error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/student/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Reset password error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/student/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Verify OTP error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> rentBooks(
    String token,
    List<Map<String, String>> items,
  ) async {
    try {
      final bodyData = {'items': items};
      final bodyJson = jsonEncode(bodyData);
      print(
        'DEBUG: ApiService.rentBooks URL: $baseUrl/auth/admin/student/rent-books',
      );
      print('DEBUG: ApiService.rentBooks body: $bodyJson');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/student/rent-books'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: bodyJson,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) return data;
      throw Exception(data['error'] ?? 'Failed to rent books');
    } catch (e) {
      print('DEBUG: ApiService.rentBooks error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> syncData(String token, String? lastSync) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/auth/admin/student/sync?last_sync=${lastSync ?? ''}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Sync error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> reserveBook(String token, String bookId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/reserve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'book_id': bookId}),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Reserve error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> cancelReservation(
    String token,
    String reservationId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/reserve/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reservation_id': reservationId}),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Cancel reservation error: $e');
      return null;
    }
  }

  // Review API methods
  Future<Map<String, dynamic>?> submitReview(
    String token,
    String bookId,
    int rating,
    String reviewText,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'book_id': bookId,
          'rating': rating,
          'review_text': reviewText,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      print('Submit review error: $e');
      return null;
    }
  }

  Future<List<dynamic>> getBookReviews(String bookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/book/$bookId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['reviews'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Get book reviews error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getUserReviews(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['reviews'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print('Get user reviews error: $e');
      return [];
    }
  }
}
