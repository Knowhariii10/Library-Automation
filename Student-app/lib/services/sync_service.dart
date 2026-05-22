import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';
import '../providers/book_provider.dart';
import '../providers/rental_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/fine_provider.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/file_service.dart';

class SyncService {
  final ApiService _apiService = ApiService();
  final FileService _fileService = FileService.instance;
  Timer? _syncTimer;

  static final StreamController<String> _notificationStreamController =
      StreamController<String>.broadcast();
  static Stream<String> get notificationStream =>
      _notificationStreamController.stream;

  Future<String?> syncData(
    UserProvider userProvider,
    BookProvider? bookProvider, {
    RentalProvider? rentalProvider,
    TransactionProvider? txProvider,
    ReservationProvider? resProvider,
    NotificationProvider? notifProvider,
    FineProvider? fineProvider,
  }) async {
    String? newNotificationMessage;
    // 1. Sync Books (Public Data)
    if (bookProvider != null) {
      await bookProvider.syncBooks();

      // 1.1 Sync Images (Only on Mobile)
      if (!kIsWeb) {
        _syncImages(bookProvider);
      }
    }

    if (!userProvider.isAuthenticated) return null;

    try {
      final token = userProvider.token!;
      String? lastSync;

      if (!kIsWeb) {
        lastSync = await DatabaseHelper.instance.getLastSync();
      }

      print(
        'DEBUG: SyncService.syncData starting for user-specific data... lastSync: $lastSync',
      );

      // 2. Sync Protected Data (Transactions, Notifications, User)
      final result = await _apiService.syncData(token, lastSync);

      if (result != null && result['success'] == true) {
        if (!kIsWeb) {
          if (result['transactions'] != null) {
            await DatabaseHelper.instance.saveTransactions(
              List<Map<String, dynamic>>.from(result['transactions']),
            );
            txProvider?.loadTransactions();
          }
          if (result['notifications'] != null) {
            final notifications = List<Map<String, dynamic>>.from(
              result['notifications'],
            );
            if (notifications.isNotEmpty) {
              newNotificationMessage = notifications.first['message'];
              if (newNotificationMessage != null) {
                _notificationStreamController.add(newNotificationMessage);
              }
            }
            await DatabaseHelper.instance.saveNotifications(notifications);
            notifProvider?.loadNotifications();
          }

          if (result['reservations'] != null) {
            final resList = List<Map<String, dynamic>>.from(
              result['reservations'],
            );
            print('DEBUG: SyncService received ${resList.length} reservations');
            await DatabaseHelper.instance.saveReservations(resList);
            resProvider?.loadReservations();
          }

          if (result['rentals'] != null) {
            final rentalList = List<Map<String, dynamic>>.from(
              result['rentals'],
            );
            print('DEBUG: SyncService received ${rentalList.length} rentals');
            await DatabaseHelper.instance.saveRentals(rentalList);
            rentalProvider?.loadRentals();
          }

          if (result['fines'] != null) {
            final finesList = List<Map<String, dynamic>>.from(result['fines']);
            print('DEBUG: SyncService received ${finesList.length} fines');
            await DatabaseHelper.instance.saveFines(finesList);
            fineProvider?.loadFines();
          }

          // Sync reviews for all books
          if (bookProvider != null) {
            final books = await DatabaseHelper.instance.getBooks();
            for (var bookData in books) {
              final bookId = bookData['id'] as String?;
              if (bookId != null && bookId.isNotEmpty) {
                try {
                  final reviews = await _apiService.getBookReviews(bookId);
                  if (reviews.isNotEmpty) {
                    await DatabaseHelper.instance.saveReviews(
                      reviews.map((r) => r as Map<String, dynamic>).toList(),
                    );
                  }
                } catch (e) {
                  print('DEBUG: Failed to sync reviews for book $bookId: $e');
                }
              }
            }
          }

          final serverTime =
              result['server_time'] ?? DateTime.now().toIso8601String();
          await DatabaseHelper.instance.setLastSync(serverTime);
          print('DEBUG: SyncService data sync success at $serverTime');
        } else {
          print(
            'DEBUG: SyncService data sync success (Web - local save skipped)',
          );
        }
      }

      print('DEBUG: SyncService.syncData completed');
      return newNotificationMessage;
    } catch (e) {
      print('DEBUG: SyncService.syncData failure: $e');
      return null;
    }
  }

  Future<void> _syncImages(BookProvider bookProvider) async {
    if (kIsWeb) return;

    final books = await DatabaseHelper.instance.getBooks();
    for (var bookData in books) {
      final imagePath = bookData['image_path'] as String?;
      final localImagePath = bookData['local_image_path'] as String?;

      if (imagePath != null &&
          imagePath.isNotEmpty &&
          (localImagePath == null || localImagePath.isEmpty)) {
        final imageUrl = ApiService.getImageUrl(imagePath);
        final fileName = imagePath.split('/').last;

        final savedPath = await _fileService.downloadAndSaveImage(
          imageUrl,
          fileName,
        );
        if (savedPath != null) {
          // Update SQLite with local path
          final updatedBook = Map<String, dynamic>.from(bookData);
          updatedBook['local_image_path'] = savedPath;
          await DatabaseHelper.instance.saveBooks([updatedBook]);
        }
      }
    }
  }

  void startPeriodicSync(
    UserProvider userProvider,
    BookProvider bookProvider, {
    RentalProvider? rentalProvider,
    TransactionProvider? txProvider,
    ReservationProvider? resProvider,
    NotificationProvider? notifProvider,
    FineProvider? fineProvider,
  }) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      syncData(
        userProvider,
        bookProvider,
        rentalProvider: rentalProvider,
        txProvider: txProvider,
        resProvider: resProvider,
        notifProvider: notifProvider,
        fineProvider: fineProvider,
      );
    });
    // Run once immediately
    syncData(
      userProvider,
      bookProvider,
      rentalProvider: rentalProvider,
      txProvider: txProvider,
      resProvider: resProvider,
      notifProvider: notifProvider,
      fineProvider: fineProvider,
    );
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
