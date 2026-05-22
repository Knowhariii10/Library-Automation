import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import 'user_provider.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final int availableCopies;
  final String imagePath;
  final String localImagePath; // New field
  final String department;
  final List<String> tags;
  final String difficultyLevel;
  final double avgRating;
  final int reviewCount;
  final int totalCopies;
  final String barcode;
  final Map<String, dynamic> location;
  final String rfid;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.availableCopies,
    required this.imagePath,
    this.localImagePath = '', // Default empty
    this.department = '',
    this.tags = const [],
    this.difficultyLevel = 'beginner',
    this.avgRating = 0.0,
    this.reviewCount = 0,
    this.totalCopies = 0,
    this.barcode = '',
    this.location = const {'section': '', 'row': 0, 'column': 0},
    this.rfid = '',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    try {
      // Tags might be a List (API) or a JSON string (DB)
      List<String> parsedTags = [];
      if (json['tags'] is List) {
        parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
      } else if (json['tags'] is String && json['tags'].isNotEmpty) {
        try {
          final decoded = jsonDecode(json['tags']);
          if (decoded is List) {
            parsedTags = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }

      // Location might be a Map (API) or a JSON string (DB)
      Map<String, dynamic> parsedLocation = {
        'section': '',
        'row': 0,
        'column': 0,
      };
      if (json['location'] is Map) {
        parsedLocation.addAll(Map<String, dynamic>.from(json['location']));
      } else if (json['location'] is String && json['location'].isNotEmpty) {
        try {
          final decoded = jsonDecode(json['location']);
          if (decoded is Map) {
            parsedLocation.addAll(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }

      return Book(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        title: (json['title'] ?? 'Unknown Title').toString(),
        author: (json['author'] ?? 'Unknown Author').toString(),
        availableCopies:
            int.tryParse(json['available_copies']?.toString() ?? '0') ?? 0,
        imagePath: (json['image_path'] ?? '').toString(),
        localImagePath: (json['local_image_path'] ?? '').toString(),
        department: (json['department'] ?? '').toString(),
        tags: parsedTags,
        difficultyLevel: (json['difficulty_level'] ?? 'beginner').toString(),
        avgRating:
            double.tryParse(json['avg_rating']?.toString() ?? '0.0') ?? 0.0,
        reviewCount: int.tryParse(json['review_count']?.toString() ?? '0') ?? 0,
        location: parsedLocation,
        barcode: (json['barcode'] ?? '').toString(),
        rfid: (json['rfid'] ?? '').toString(),
        totalCopies: int.tryParse(json['total_copies']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      print('DEBUG: Error parsing book: $e, json: $json');
      return Book(
        id: '',
        title: 'Error Parsing Book',
        author: '',
        availableCopies: 0,
        imagePath: '',
      );
    }
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? availableCopies,
    String? imagePath,
    String? localImagePath,
    String? department,
    List<String>? tags,
    String? difficultyLevel,
    double? avgRating,
    int? reviewCount,
    int? totalCopies,
    String? barcode,
    Map<String, dynamic>? location,
    String? rfid,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      availableCopies: availableCopies ?? this.availableCopies,
      imagePath: imagePath ?? this.imagePath,
      localImagePath: localImagePath ?? this.localImagePath,
      department: department ?? this.department,
      tags: tags ?? this.tags,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalCopies: totalCopies ?? this.totalCopies,
      barcode: barcode ?? this.barcode,
      location: location ?? this.location,
      rfid: rfid ?? this.rfid,
    );
  }
}

class BookProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  List<Book> _recommendations = [];
  bool _isLoading = false;

  List<Book> get books => _filteredBooks.isEmpty ? _books : _filteredBooks;
  List<Book> get recommendations => _recommendations;
  bool get isLoading => _isLoading;

  Future<void> loadBooks() async {
    print('DEBUG: BookProvider.loadBooks() started (kIsWeb: $kIsWeb)');
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        // On Web, we don't have SQLite, so we must fetch from API
        await syncBooks();
      } else {
        // On Mobile, adhere to Golden Rule: Read from SQLite
        final localData = await DatabaseHelper.instance.getBooks();
        _books = localData.map((json) => Book.fromJson(json)).toList();
        _filteredBooks = List.from(_books);
        print('DEBUG: Loaded ${_books.length} books from SQLite');

        // Load cached recommendations
        final cachedRecIds = await DatabaseHelper.instance.getRecommendations();
        if (cachedRecIds.isNotEmpty) {
          _recommendations = _books
              .where((b) => cachedRecIds.contains(b.id))
              .toList();
          print(
            'DEBUG: Loaded ${_recommendations.length} cached recommendations',
          );
        }

        // If SQLite is empty, trigger a sync immediately
        if (_books.isEmpty) {
          print('DEBUG: SQLite is empty, triggering syncBooks()');
          await syncBooks();
        } else {
          // Even if we have data, trigger a background sync to update location/status
          print('DEBUG: SQLite has data, triggering background syncBooks()');
          syncBooks().ignore();
        }
      }
    } catch (e) {
      print('DEBUG: BookProvider.loadBooks error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncBooks() async {
    print('DEBUG: BookProvider.syncBooks() started');
    try {
      final data = await _apiService.getBooks();
      print(
        'DEBUG: BookProvider.syncBooks() API returned ${data.length} items',
      );

      if (data.isNotEmpty) {
        final newBooks = data
            .map((json) => Book.fromJson(json as Map<String, dynamic>))
            .where((b) => b.id.isNotEmpty)
            .toList();

        if (!kIsWeb) {
          await DatabaseHelper.instance.saveBooks(
            data.cast<Map<String, dynamic>>(),
          );
          print('DEBUG: Synced and cached ${newBooks.length} books to SQLite');
        }

        // Always update state to avoid recursion and ensure immediate UI refresh
        _books = newBooks;
        _filteredBooks = List.from(_books);
        print('DEBUG: Updated BookProvider state with ${_books.length} books');
      }
      notifyListeners();
    } catch (e) {
      print('DEBUG: BookProvider.syncBooks error: $e');
    }
  }

  void filterBooks(String query) {
    if (query.isEmpty) {
      _filteredBooks = List.from(_books);
    } else {
      _filteredBooks = _books
          .where(
            (book) =>
                book.title.toLowerCase().contains(query.toLowerCase()) ||
                book.author.toLowerCase().contains(query.toLowerCase()) ||
                book.department.toLowerCase().contains(query.toLowerCase()) ||
                book.tags.any(
                  (tag) => tag.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .toList();
    }
    notifyListeners();
  }

  Future<void> logBookInterest(Book book) async {
    if (kIsWeb) return;
    try {
      await DatabaseHelper.instance.saveInterestTags(book.tags);
    } catch (e) {
      print('DEBUG: Error logging book interest: $e');
    }
  }

  Future<void> generateRecommendations(User user) async {
    if (kIsWeb || _books.isEmpty) return;

    try {
      final dept = user.department.toLowerCase();

      // 1. Department matches (Strictly based on department)
      final deptBooks = _books.where((b) {
        return b.department.toLowerCase().contains(dept) && b.id.isNotEmpty;
      }).toList();

      print(
        'DEBUG: Found ${deptBooks.length} dept books for user ${user.id} (Dept: $dept)',
      );

      // 2. Fallback: If no department books, use interest tags or random
      List<Book> recs = [];
      if (deptBooks.isNotEmpty) {
        recs = deptBooks;
      } else {
        // Fallback if NO department books found
        final recentTags = await DatabaseHelper.instance.getRecentInterestTags(
          10,
        );
        final interestBooks = _books.where((b) {
          if (b.tags.isEmpty) return false;
          return b.tags.any((t) => recentTags.contains(t));
        }).toList();

        recs = interestBooks;
        if (recs.isEmpty) {
          final remainingBooks = _books.toList();
          remainingBooks.shuffle();
          recs = remainingBooks;
        }
      }

      // Take top 10
      _recommendations = recs.take(10).toList();
      notifyListeners();

      // Cache recommendations
      if (_recommendations.isNotEmpty) {
        await DatabaseHelper.instance.saveRecommendations(
          _recommendations.map((b) => b.id).toList(),
        );
        print(
          'DEBUG: Generated and cached ${_recommendations.length} recommendations',
        );
      } else {
        print(
          'DEBUG: No recommendations generated even after fallback. Total books: ${_books.length}',
        );
      }
    } catch (e) {
      print('DEBUG: Error generating recommendations: $e');
    }
  }

  void clearRecommendations() {
    _recommendations = [];
    notifyListeners();
    // Also clear from cache
    DatabaseHelper.instance.saveRecommendations([]);
  }
}
