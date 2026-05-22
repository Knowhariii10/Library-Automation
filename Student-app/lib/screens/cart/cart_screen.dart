import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/book_image.dart';
import '../../widgets/login_required_widget.dart';
import '../../theme/app_colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

import '../../widgets/premium_app_bar.dart';
import 'premium_scanner_screen.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int _activeCount = 0;
  bool _isLoadingLimits = true;
  bool _isSelectionMode = false;
  Set<String> _reservedBookIds = {};

  @override
  void initState() {
    super.initState();
    _loadLimits();
    // Auto-restore selection mode if items are already selected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      if (cart.selectedIds.isNotEmpty && mounted) {
        setState(() => _isSelectionMode = true);
      }
    });
  }

  Future<void> _loadLimits() async {
    final rentals = await DatabaseHelper.instance.getRentals();
    final reservations = await DatabaseHelper.instance.getReservations();
    final activeReservations = reservations
        .where((r) => r['status'] == 'ACTIVE')
        .toList();

    int count = 0;
    for (var r in rentals) {
      count += (r['books'] as List).where((b) => b['returned'] == false).length;
    }
    count += activeReservations.length;

    if (mounted) {
      setState(() {
        _activeCount = count;
        _reservedBookIds = activeReservations
            .map((r) => r['book_id'].toString())
            .toSet();
        _isLoadingLimits = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isStudent) {
          return Scaffold(
            appBar: AppBar(title: const Text('Your Vault')),
            body: LoginRequiredWidget(
              message: userProvider.isAuthenticated
                  ? 'Guests cannot view cart. Please login as a student.'
                  : 'Login to access your vault and make reserves',
            ),
          );
        }

        return Consumer<CartProvider>(
          builder: (context, cart, child) {
            final totalPotential = _activeCount + cart.selectedIds.length;
            final canSelectMore = totalPotential < 3;

            return PopScope(
              canPop: !_isSelectionMode,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = false;
                    cart.clearSelection();
                  });
                }
              },
              child: Scaffold(
                extendBody: true,
                appBar: _isSelectionMode
                    ? AppBar(
                        title: Text('${cart.selectedIds.length} selected'),
                        leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = false;
                              cart.clearSelection();
                            });
                          },
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.select_all),
                            onPressed: () {
                              for (var item in cart.items) {
                                if (!cart.isSelected(item.id)) {
                                  cart.toggleSelection(item.id);
                                }
                              }
                            },
                          ),
                        ],
                      )
                    : const PremiumAppBar(),
                // New FAB for Scanner
                floatingActionButton: _isSelectionMode
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(
                          bottom: 100,
                        ), // 100px above bottom (nav + gap)
                        child: FloatingActionButton(
                          onPressed: () => _scanBarcode(context),
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkAccent
                              : AppColors
                                    .lightAccent, // Match bottom nav yellow
                          elevation: 6,
                          child: Icon(
                            Icons.qr_code_scanner,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : const Color(
                                    0xFF2C3E50,
                                  ), // Dark grey for contrast
                            size: 28,
                          ),
                        ),
                      ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
                body: Column(
                  children: [
                    if (cart.items.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Scan the barcode to manage your vault',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      if (_isLoadingLimits)
                        const LinearProgressIndicator()
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: AppColors.info.withOpacity(0.1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Limit: 3 books total (Rentals + Reservations). '
                                  'Currently active: $_activeCount. '
                                  'Selected: ${cart.selectedIds.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: 120,
                          ), // Global Scroll Padding
                          itemCount: cart.itemCount,
                          itemBuilder: (context, index) {
                            return _buildCartItem(
                              context,
                              cart.items[index],
                              cart,
                              canSelectMore,
                            );
                          },
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                          bottom: 80,
                        ), // Space for floating bottom nav
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Selected: ${cart.selectedIds.length} items',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Total in Vault: ${cart.itemCount}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: cart.selectedIds.isEmpty
                                    ? Colors.grey
                                    : null,
                              ),
                              onPressed: cart.selectedIds.isEmpty
                                  ? null
                                  : () async {
                                      if (!_validateSelection(context, cart)) {
                                        return;
                                      }

                                      final userProvider =
                                          Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          );
                                      if (!userProvider.isAuthenticated) return;

                                      setState(() => _isLoadingLimits = true);
                                      try {
                                        final rentalItems = cart.selectedItems
                                            .map(
                                              (item) => {
                                                'book_id': item.id,
                                                'barcode': item.barcode,
                                                'rfid': item.rfid,
                                              },
                                            )
                                            .toList();

                                        if (rentalItems.isEmpty) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No items selected or valid for rental',
                                                ),
                                              ),
                                            );
                                          }
                                          return;
                                        }

                                        final apiService = ApiService();
                                        final result = await apiService
                                            .rentBooks(
                                              userProvider.token!,
                                              rentalItems,
                                            );

                                        if (result?['success'] == true &&
                                            result?['data'] != null) {
                                          try {
                                            final txData =
                                                result!['data']
                                                    as Map<String, dynamic>;
                                            await DatabaseHelper.instance
                                                .saveTransactions([txData]);
                                          } catch (e) {
                                            print(
                                              'Error saving local transaction: $e',
                                            );
                                          }

                                          final rentedIds = List<String>.from(
                                            cart.selectedIds,
                                          );
                                          await cart.removeItems(rentedIds);
                                          cart.clearSelection();

                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Rental request submitted! Check history for QR.',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );

                                            final bookProvider =
                                                Provider.of<BookProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                            SyncService().syncData(
                                              userProvider,
                                              bookProvider,
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  result?['error'] ??
                                                      'Failed to rent books',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _cleanErrorMessage(e),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted)
                                          setState(
                                            () => _isLoadingLimits = false,
                                          );
                                      }
                                    },
                              child: const Text('PROCEED TO CHECKOUT'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                side: BorderSide(
                                  color: cart.selectedIds.isEmpty
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                ),
                                foregroundColor: cart.selectedIds.isEmpty
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                              ),
                              onPressed: cart.selectedIds.isEmpty
                                  ? null
                                  : () {
                                      if (!_validateSelection(context, cart)) {
                                        return;
                                      }

                                      final userProvider =
                                          Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          );
                                      _showOfflineQrDialog(
                                        context,
                                        cart,
                                        userProvider,
                                      );
                                    },
                              child: const Text(
                                'PROCEED TO RENTAL (OFFLINE)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    Book book,
    CartProvider cartProvider,
    bool canSelectMore,
  ) {
    final isSelected = cartProvider.isSelected(book.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() => _isSelectionMode = true);
            cartProvider.toggleSelection(book.id);
          }
        },
        onTap: () {
          if (_isSelectionMode) {
            if (_reservedBookIds.contains(book.id)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '"${book.title}" is already reserved. Please cancel the reservation first.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            if (!isSelected && !canSelectMore) {
              _showLimitSnackBar(context);
              return;
            }
            cartProvider.toggleSelection(book.id);
            if (cartProvider.selectedIds.isEmpty) {
              setState(() => _isSelectionMode = false);
            }
          } else {
            // Optional: Navigate to book details
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      if (value == true) {
                        if (_reservedBookIds.contains(book.id)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"${book.title}" is already reserved. Please cancel the reservation first.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        if (!canSelectMore && !isSelected) {
                          _showLimitSnackBar(context);
                          return;
                        }
                      }
                      cartProvider.toggleSelection(book.id);
                      if (cartProvider.selectedIds.isEmpty) {
                        setState(() => _isSelectionMode = false);
                      }
                    },
                  ),
                ),
              BookImage(
                imagePath: book.imagePath,
                localImagePath: book.localImagePath,
                width: 50,
                height: 70,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'by ${book.author}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      'Available: ${book.availableCopies > 0 ? 'Yes' : 'No'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: book.availableCopies > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (book.rfid.isNotEmpty)
                      Text(
                        'RFID: ${book.rfid}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (_reservedBookIds.contains(book.id))
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.bookmark,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () {
                    cartProvider.removeItem(book.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item removed from vault')),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineQrDialog(
    BuildContext context,
    CartProvider cart,
    UserProvider user,
  ) {
    if (!user.isAuthenticated) return;

    final payload = {
      'purpose': 'RENTING',
      'user_id': user.user?.id,
      'items': cart.selectedItems
          .map(
            (item) => {
              'book_id': item.id,
              'barcode': item.barcode,
              'rfid': item.rfid,
            },
          )
          .toList(),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Offline Rental QR',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show this QR to the librarian to complete your rental offline.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: QrImageView(
                data: jsonEncode(payload),
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Selected Items: ${cart.selectedIds.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally clear selection after showing QR
              // cart.clearSelection();
            },
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear selection and items in batch as if they were rented
              final rentedIds = List<String>.from(cart.selectedIds);
              await cart.removeItems(rentedIds);
              cart.clearSelection();
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Items moved to processing. Scan QR to finish.',
                  ),
                  backgroundColor: Colors.blue,
                  duration: AppTheme.snackBarDuration,
                ),
              );
            },
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _showLimitSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Limit reached! You can only have 3 active books (including rentals and reservations).',
        ),
        backgroundColor: Colors.orange,
        duration: AppTheme.snackBarDuration,
      ),
    );
  }

  String _cleanErrorMessage(Object error) {
    String message = error.toString();
    if (message.startsWith('Exception: ')) {
      message = message.substring(11);
    }
    return message;
  }

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      // Navigate to premium scanner screen
      final barcode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumScannerScreen(),
          fullscreenDialog: true,
        ),
      );

      if (barcode == null || barcode.isEmpty) {
        return; // User cancelled
      }

      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading book details...')));

      // Fetch book details by barcode
      final apiService = ApiService();
      final response = await apiService.getBookByBarcode(barcode);

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        final bookData = response['book'];
        final scannedCopy = bookData['scanned_copy'];

        // Check if copy is available
        if (scannedCopy['is_available'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This copy is already issued'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Add to cart with copy details
        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        // Check if this barcode is already in cart
        if (cartProvider.hasBarcode(barcode)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This book is already in your cart'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Check if this book is already reserved by the user
        if (_reservedBookIds.contains(bookData['id'].toString())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You already have an active reservation for "${bookData['title']}". Please cancel it first.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        // Create book object with copy details
        final book = Book(
          id: bookData['id'],
          title: bookData['title'],
          author: bookData['author'],
          department: bookData['department'] ?? '',
          tags: List<String>.from(bookData['tags'] ?? []),
          difficultyLevel: bookData['difficulty_level'] ?? 'beginner',
          availableCopies: bookData['available_copies'] ?? 0,
          totalCopies: bookData['total_copies'] ?? 0,
          imagePath: bookData['image_path'] ?? '',
          avgRating: (bookData['avg_rating'] ?? 0).toDouble(),
          reviewCount: bookData['review_count'] ?? 0,
          barcode: scannedCopy['barcode'],
          rfid: scannedCopy['rfid'],
          location: bookData['location'] ?? {},
        );

        if (scannedCopy['rfid'] == null ||
            scannedCopy['rfid'].toString().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Warning: This book copy has no RFID tag in the system!',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }

        cartProvider.addItemWithCopy(book, barcode, scannedCopy['rfid'] ?? "");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added "${bookData['title']}" to cart (RFID: ${scannedCopy['rfid']})',
            ),
            backgroundColor: Colors.green,
            duration: AppTheme.snackBarDuration,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['error'] ?? 'Book not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanErrorMessage(e)), // Cleaned message
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateSelection(BuildContext context, CartProvider cart) {
    final reservedInSelection = cart.selectedItems
        .where((item) => _reservedBookIds.contains(item.id))
        .toList();

    if (reservedInSelection.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot rent "${reservedInSelection.first.title}" because it is already reserved. Please cancel the reservation first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }
    return true;
  }
}
