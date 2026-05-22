import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web');
    }
    if (_database != null) return _database!;
    _database = await _initDB('library.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 21,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE user_profile ADD COLUMN purpose TEXT DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE user_profile ADD COLUMN is_guest INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE transactions (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          amount REAL,
          date TEXT,
          type TEXT,
          message TEXT,
          created_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          message TEXT,
          read_status INTEGER,
          created_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE sync_meta (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE books ADD COLUMN local_image_path TEXT DEFAULT ""',
      );
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE reservations (
          id TEXT PRIMARY KEY,
          book_id TEXT,
          book_title TEXT,
          reserved_at TEXT,
          expires_at TEXT,
          status TEXT
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE rentals (
          book_id TEXT,
          book_title TEXT,
          due_date TEXT,
          rental_id TEXT,
          PRIMARY KEY (book_id, rental_id)
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('CREATE TABLE cart (book_id TEXT PRIMARY KEY)');
      await db.execute('CREATE TABLE wishlist (book_id TEXT PRIMARY KEY)');
      await db.execute(
        'CREATE TABLE cart_selection (book_id TEXT PRIMARY KEY)',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN transaction_id TEXT DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN status TEXT DEFAULT "PENDING"',
      );
      await db.execute('ALTER TABLE transactions ADD COLUMN items TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN qr_payload TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN due_date TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN returned_at TEXT');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN fine_amount REAL DEFAULT 0.0',
      );
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN fine_paid INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE rentals ADD COLUMN rfid TEXT DEFAULT ""');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE reviews (
          id TEXT PRIMARY KEY,
          book_id TEXT,
          user_id TEXT,
          user_name TEXT,
          rating INTEGER,
          review_text TEXT,
          department TEXT,
          year TEXT,
          created_at TEXT
        )
      ''');
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE search_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          search_term TEXT,
          timestamp TEXT,
          result_count INTEGER
        )
      ''');
    }
    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE user_interests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tag TEXT,
          timestamp TEXT
        )
      ''');
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE recommendations (
          book_id TEXT PRIMARY KEY,
          timestamp TEXT
        )
      ''');
    }
    if (oldVersion < 14) {
      await db.execute(
        'ALTER TABLE books ADD COLUMN location TEXT DEFAULT "{}"',
      );
    }
    if (oldVersion < 15) {
      await db.execute('ALTER TABLE cart ADD COLUMN barcode TEXT DEFAULT ""');
    }
    if (oldVersion < 17) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recommendations (
          book_id TEXT PRIMARY KEY,
          timestamp TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS search_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          search_term TEXT,
          timestamp TEXT,
          result_count INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_interests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tag TEXT,
          timestamp TEXT
        )
      ''');
      // Ensure location column exists
      try {
        await db.execute(
          'ALTER TABLE books ADD COLUMN location TEXT DEFAULT "{}"',
        );
      } catch (_) {
        // Column likely exists
      }
    }
    if (oldVersion < 18) {
      await db.execute('''
        CREATE TABLE fines (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          amount REAL,
          reason TEXT,
          status TEXT,
          date TEXT,
          paid_date TEXT,
          transaction_id TEXT
        )
      ''');
    }
    if (oldVersion < 19) {
      await db.execute('ALTER TABLE fines ADD COLUMN book_id TEXT DEFAULT ""');
      await db.execute(
        'ALTER TABLE fines ADD COLUMN book_title TEXT DEFAULT ""',
      );
      await db.execute('ALTER TABLE fines ADD COLUMN author TEXT DEFAULT ""');
      await db.execute('ALTER TABLE fines ADD COLUMN rfid TEXT DEFAULT ""');
    }
    if (oldVersion < 20) {
      // Add missing columns to books table
      try {
        await db.execute('ALTER TABLE books ADD COLUMN tags TEXT DEFAULT "[]"');
        await db.execute(
          'ALTER TABLE books ADD COLUMN total_copies INTEGER DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE books ADD COLUMN barcode TEXT DEFAULT ""',
        );
        await db.execute('ALTER TABLE books ADD COLUMN rfid TEXT DEFAULT ""');
      } catch (_) {
        // columns might exist if db was partially updated
      }
    }
    if (oldVersion < 21) {
      await db.execute('ALTER TABLE cart ADD COLUMN rfid TEXT DEFAULT ""');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE books (
  id $idType,
  title $textType,
  author $textType,
  available_copies $intType,
  image_path $textType,
  local_image_path TEXT,
  department $textType,
  difficulty_level $textType,
  avg_rating $doubleType,
  review_count $intType,
  location TEXT,
  tags TEXT,
  total_copies INTEGER,
  barcode TEXT,
  rfid TEXT
)
''');

    await db.execute('''
CREATE TABLE user_profile (
  id $idType,
  name $textType,
  email $textType,
  student_id $textType,
  department $textType,
  year $textType,
  phone $textType,
  purpose TEXT,
  is_guest INTEGER,
  token TEXT
)
''');

    await db.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  transaction_id TEXT,
  user_id TEXT,
  amount REAL,
  date TEXT,
  type TEXT,
  message TEXT,
  status TEXT DEFAULT "PENDING",
  items TEXT,
  qr_payload TEXT,
  due_date TEXT,
  returned_at TEXT,
  fine_amount REAL DEFAULT 0.0,
  fine_paid INTEGER DEFAULT 0,
  created_at TEXT
)
''');

    await db.execute('''
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  message TEXT,
  read_status INTEGER,
  created_at TEXT
)
''');

    await db.execute('''
CREATE TABLE reservations (
  id TEXT PRIMARY KEY,
  book_id TEXT,
  book_title TEXT,
  reserved_at TEXT,
  expires_at TEXT,
  status TEXT
)
''');

    await db.execute('''
CREATE TABLE rentals (
  book_id TEXT,
  book_title TEXT,
  due_date TEXT,
  rental_id TEXT,
  rfid TEXT,
  PRIMARY KEY (book_id, rental_id)
)
''');

    await db.execute(
      'CREATE TABLE cart (book_id TEXT PRIMARY KEY, barcode TEXT DEFAULT "")',
    );
    await db.execute('CREATE TABLE wishlist (book_id TEXT PRIMARY KEY)');
    await db.execute('CREATE TABLE cart_selection (book_id TEXT PRIMARY KEY)');

    await db.execute('''
CREATE TABLE reviews (
  id TEXT PRIMARY KEY,
  book_id TEXT,
  user_id TEXT,
  user_name TEXT,
  rating INTEGER,
  review_text TEXT,
  department TEXT,
  year TEXT,
  created_at TEXT
)
''');

    await db.execute('''
CREATE TABLE search_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  search_term TEXT,
  timestamp TEXT,
  result_count INTEGER
)
''');

    await db.execute('''
CREATE TABLE user_interests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tag TEXT,
  timestamp TEXT
)
''');

    await db.execute('''
CREATE TABLE recommendations (
  book_id TEXT PRIMARY KEY,
  timestamp TEXT
)
''');

    await db.execute('''
CREATE TABLE sync_meta (
  key TEXT PRIMARY KEY,
  value TEXT
)
''');

    await db.execute('''
CREATE TABLE fines (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  amount REAL,
  reason TEXT,
  status TEXT,
  date TEXT,
  paid_date TEXT,
  transaction_id TEXT,
  book_id TEXT,
  book_title TEXT,
  author TEXT,
  rfid TEXT
)
''');
  }

  // Book Operations
  Future<void> saveBooks(List<Map<String, dynamic>> books) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var book in books) {
      batch.insert('books', {
        'id': book['id'] ?? '',
        'title': book['title'] ?? '',
        'author': book['author'] ?? '',
        'available_copies': book['available_copies'] ?? 0,
        'image_path': book['image_path'] ?? '',
        'local_image_path': book['local_image_path'] ?? '',
        'department': book['department'] ?? '',
        'difficulty_level': book['difficulty_level'] ?? '',
        'avg_rating': (book['avg_rating'] ?? 0.0).toDouble(),
        'review_count': book['review_count'] ?? 0,
        'location': jsonEncode(book['location'] ?? {}),
        'tags': jsonEncode(book['tags'] ?? []),
        'total_copies': book['total_copies'] ?? 0,
        'barcode': book['barcode'] ?? '',
        'rfid': book['rfid'] ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Debug print for first item to avoid spam
      if (book == books.first) {
        print(
          'DEBUG: DatabaseHelper saving book ${book['title']} with location: ${book['location']}',
        );
      }
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getBooks() async {
    final db = await instance.database;
    return await db.query('books');
  }

  Future<Map<String, dynamic>?> getBookById(String id) async {
    final db = await instance.database;
    final results = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  // User Operations
  Future<void> saveUser(Map<String, dynamic> user, String token) async {
    final db = await instance.database;
    await db.delete('user_profile');
    await db.insert('user_profile', {...user, 'token': token});
  }

  Future<Map<String, dynamic>?> getUser() async {
    final db = await instance.database;
    final results = await db.query('user_profile');
    if (results.isNotEmpty) return results.first;
    return null;
  }

  Future<void> clearUser() async {
    final db = await instance.database;
    await db.delete('user_profile');
    await db.delete('transactions');
    await db.delete('notifications');
    // await db.delete('books'); // Keep books cached for offline/guest use
    await db.delete('reservations');
    await db.delete('rentals');
    await db.delete('sync_meta');
    await db.delete('cart');
    await db.delete('wishlist');
    await db.delete('cart_selection');
    await db.delete('fines');
  }

  // Atomic Save for Initial Sync
  Future<void> saveInitialData({
    required Map<String, dynamic> user,
    required String token,
    List<Map<String, dynamic>>? transactions,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? books,
    List<Map<String, dynamic>>? reservations,
    List<Map<String, dynamic>>? fines,
  }) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('user_profile');
      await txn.insert('user_profile', {...user, 'token': token});

      if (transactions != null) {
        for (var t in transactions) {
          await txn.insert('transactions', {
            'id': t['id'] ?? '',
            'transaction_id': t['transaction_id'] ?? '',
            'user_id': t['user_id'] ?? '',
            'amount': (t['amount'] ?? 0.0).toDouble(),
            'date': t['date'] ?? '',
            'type': t['type'] ?? '',
            'message': t['message'] ?? '',
            'status': t['status'] ?? 'PENDING',
            'items': t['items'] != null ? jsonEncode(t['items']) : null,
            'qr_payload': t['qr_payload'] != null
                ? jsonEncode(t['qr_payload'])
                : null,
            'due_date': t['due_date'] ?? '',
            'returned_at': t['returned_at'] ?? '',
            'fine_amount': (t['fine_amount'] ?? 0.0).toDouble(),
            'fine_paid': (t['fine_paid'] == true || t['fine_paid'] == 1)
                ? 1
                : 0,
            'created_at': t['created_at'] ?? '',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (notifications != null) {
        for (var n in notifications) {
          await txn.insert('notifications', {
            'id': n['id'] ?? '',
            'user_id': n['user_id'] ?? '',
            'message': n['message'] ?? '',
            'read_status': (n['read_status'] == true || n['read_status'] == 1)
                ? 1
                : 0,
            'created_at': n['created_at'] ?? '',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (books != null) {
        for (var book in books) {
          await txn.insert('books', {
            'id': book['id'] ?? '',
            'title': book['title'] ?? '',
            'author': book['author'] ?? '',
            'available_copies': book['available_copies'] ?? 0,
            'image_path': book['image_path'] ?? '',
            'local_image_path': book['local_image_path'] ?? '',
            'department': book['department'] ?? '',
            'difficulty_level': book['difficulty_level'] ?? '',
            'avg_rating': (book['avg_rating'] ?? 0.0).toDouble(),
            'review_count': book['review_count'] ?? 0,
            'location': jsonEncode(book['location'] ?? {}),
            'tags': jsonEncode(book['tags'] ?? []),
            'total_copies': book['total_copies'] ?? 0,
            'barcode': book['barcode'] ?? '',
            'rfid': book['rfid'] ?? '',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (reservations != null) {
        await txn.delete('reservations');
        for (var res in reservations) {
          await txn.insert('reservations', {
            'id': res['id'] ?? '',
            'book_id': res['book_id'] ?? '',
            'book_title': res['book_title'] ?? '',
            'reserved_at': res['reserved_at'] ?? '',
            'expires_at': res['expires_at'] ?? '',
            'status': res['status'] ?? 'ACTIVE',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      if (fines != null) {
        await txn.delete('fines');
        for (var f in fines) {
          await txn.insert('fines', {
            'id': f['id'] ?? '',
            'user_id':
                user['id'] ?? '', // Assume helper context is mostly valid
            'amount': (f['amount'] ?? 0.0).toDouble(),
            'reason': f['reason'] ?? '',
            'status': f['status'] ?? 'PENDING',
            'date': f['date'] ?? '',
            'paid_date': f['paid_date'] ?? '',
            'transaction_id': f['transaction_id'] ?? '',
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await txn.insert('sync_meta', {
        'key': 'last_sync',
        'value': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  // Transaction Operations
  Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var t in transactions) {
      batch.insert('transactions', {
        'id': t['id'] ?? '',
        'transaction_id': t['transaction_id'] ?? '',
        'user_id': t['user_id'] ?? '',
        'amount': (t['amount'] ?? 0.0).toDouble(),
        'date': t['date'] ?? '',
        'type': t['type'] ?? '',
        'message': t['message'] ?? '',
        'status': t['status'] ?? 'PENDING',
        'items': t['items'] != null ? jsonEncode(t['items']) : null,
        'qr_payload': t['qr_payload'] != null
            ? jsonEncode(t['qr_payload'])
            : null,
        'due_date': t['due_date'] ?? '',
        'returned_at': t['returned_at'] ?? '',
        'fine_amount': (t['fine_amount'] ?? 0.0).toDouble(),
        'fine_paid': (t['fine_paid'] == true || t['fine_paid'] == 1) ? 1 : 0,
        'created_at': t['created_at'] ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  // Notification Operations
  Future<void> saveNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var n in notifications) {
      batch.insert('notifications', {
        'id': n['id'] ?? '',
        'user_id': n['user_id'] ?? '',
        'message': n['message'] ?? '',
        'read_status': (n['read_status'] == true) ? 1 : 0,
        'created_at': n['created_at'] ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final db = await instance.database;
    return await db.query('notifications', orderBy: 'created_at DESC');
  }

  // Reservation Operations
  Future<void> saveReservations(List<Map<String, dynamic>> reservations) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('reservations');
      for (var res in reservations) {
        await txn.insert('reservations', {
          'id': res['id'] ?? '',
          'book_id': res['book_id'] ?? '',
          'book_title': res['book_title'] ?? '',
          'reserved_at': res['reserved_at'] ?? '',
          'expires_at': res['expires_at'] ?? '',
          'status': res['status'] ?? 'ACTIVE',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getReservations() async {
    final db = await instance.database;
    return await db.query('reservations', orderBy: 'expires_at ASC');
  }

  Future<void> deleteReservation(String id) async {
    final db = await instance.database;
    await db.delete('reservations', where: 'id = ?', whereArgs: [id]);
  }

  // Rental Operations
  Future<void> saveRentals(List<Map<String, dynamic>> rentals) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('rentals');
      for (var rental in rentals) {
        await txn.insert('rentals', {
          'book_id': rental['book_id'] ?? '',
          'book_title': rental['book_title'] ?? '',
          'due_date': rental['due_date'] ?? '',
          'rental_id': rental['rental_id'] ?? '',
          'rfid': rental['rfid'] ?? '',
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getRentals() async {
    final db = await instance.database;
    return await db.query('rentals');
  }

  // OLD getFines (only transations) replaced by NEW getFines (reads fines table)
  Future<List<Map<String, dynamic>>> getFines() async {
    final db = await instance.database;
    return await db.query('fines', orderBy: 'date DESC');
  }

  Future<void> saveFines(List<Map<String, dynamic>> fines) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var f in fines) {
      batch.insert('fines', {
        'id': f['id'] ?? '',
        'user_id':
            f['user_id'] ??
            '', // Will be updated by caller usually, or existing
        'amount': (f['amount'] ?? 0.0).toDouble(),
        'reason': f['reason'] ?? '',
        'status': f['status'] ?? 'PENDING',
        'date': f['date'] ?? '',
        'paid_date': f['paid_date'] ?? '',
        'transaction_id': f['transaction_id'] ?? '',
        'book_id': f['book_id'] ?? '',
        'book_title': f['book_title'] ?? '',
        'author': f['author'] ?? '',
        'rfid': f['rfid'] ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getOverdueRentals() async {
    final db = await instance.database;
    final allRentals = await db.query('rentals');
    final now = DateTime.now();
    return allRentals.where((r) {
      try {
        final dueDateStr = r['due_date'] as String?;
        if (dueDateStr == null) return false;
        final dueDate = DateTime.parse(dueDateStr);
        return now.isAfter(dueDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Sync Operations
  Future<void> setLastSync(String timestamp) async {
    final db = await instance.database;
    await db.insert('sync_meta', {
      'key': 'last_sync',
      'value': timestamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getLastSync() async {
    final db = await instance.database;
    final results = await db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: ['last_sync'],
    );
    if (results.isNotEmpty) return results.first['value'] as String?;
    return null;
  }

  // Cart & Wishlist Operations
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await instance.database;
    return await db.query('cart');
  }

  Future<void> addToCart(
    String bookId, {
    String barcode = "",
    String rfid = "",
  }) async {
    final db = await instance.database;
    await db.insert('cart', {
      'book_id': bookId,
      'barcode': barcode,
      'rfid': rfid,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFromCart(String bookId) async {
    final db = await instance.database;
    await db.delete('cart', where: 'book_id = ?', whereArgs: [bookId]);
  }

  Future<void> clearCart() async {
    final db = await instance.database;
    await db.delete('cart');
  }

  Future<List<String>> getWishlistIds() async {
    final db = await instance.database;
    final results = await db.query('wishlist');
    return results.map((row) => row['book_id'] as String).toList();
  }

  Future<void> addToWishlist(String bookId) async {
    final db = await instance.database;
    await db.insert('wishlist', {
      'book_id': bookId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFromWishlist(String bookId) async {
    final db = await instance.database;
    await db.delete('wishlist', where: 'book_id = ?', whereArgs: [bookId]);
  }

  Future<List<String>> getSelectionIds() async {
    final db = await instance.database;
    final results = await db.query('cart_selection');
    return results.map((row) => row['book_id'] as String).toList();
  }

  Future<void> updateSelection(Set<String> selectedIds) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('cart_selection');
      for (var id in selectedIds) {
        await txn.insert('cart_selection', {'book_id': id});
      }
    });
  }

  // Review Operations
  Future<void> saveReviews(List<Map<String, dynamic>> reviews) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var r in reviews) {
      batch.insert('reviews', {
        'id': r['id'] ?? '',
        'book_id': r['book_id'] ?? '',
        'user_id': r['user_id'] ?? '',
        'user_name': r['user_name'] ?? '',
        'rating': r['rating'] ?? 0,
        'review_text': r['review_text'] ?? '',
        'department': r['department'] ?? '',
        'year': r['year'] ?? '',
        'created_at': r['created_at'] ?? '',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getReviewsForBook(String bookId) async {
    final db = await instance.database;
    return await db.query(
      'reviews',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getUserReviews() async {
    final db = await instance.database;
    return await db.query('reviews', orderBy: 'created_at DESC');
  }

  Future<void> saveInterestTags(List<String> tags) async {
    final db = await instance.database;
    final batch = db.batch();
    final timestamp = DateTime.now().toIso8601String();
    for (var tag in tags) {
      if (tag.isEmpty) continue;
      batch.insert('user_interests', {'tag': tag, 'timestamp': timestamp});
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getRecentInterestTags(int limit) async {
    final db = await instance.database;
    final result = await db.query(
      'user_interests',
      columns: ['tag'],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    final Set<String> uniqueTags = {};
    for (var row in result) {
      if (row['tag'] != null) uniqueTags.add(row['tag'] as String);
    }
    return uniqueTags.toList();
  }

  Future<void> saveRecommendations(List<String> bookIds) async {
    final db = await instance.database;
    final timestamp = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('recommendations');
      for (var id in bookIds) {
        await txn.insert('recommendations', {
          'book_id': id,
          'timestamp': timestamp,
        });
      }
    });
  }

  Future<List<String>> getRecommendations() async {
    final db = await instance.database;
    final results = await db.query('recommendations');
    return results.map((row) => row['book_id'] as String).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
