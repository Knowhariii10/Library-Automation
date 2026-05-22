import 'package:flutter/material.dart';
import 'book_provider.dart';
import '../services/database_helper.dart';

class CartProvider with ChangeNotifier {
  final List<Book> _items = [];
  final Set<String> _wishlist = {};
  final Set<String> _selectedIds = {};

  List<Book> get items => [..._items];
  int get itemCount => _items.length;
  Set<String> get wishlist => _wishlist;
  Set<String> get selectedIds => _selectedIds;

  List<Book> get selectedItems {
    return _items.where((item) => _selectedIds.contains(item.id)).toList();
  }

  bool isInWishlist(String bookId) => _wishlist.contains(bookId);
  bool isSelected(String bookId) => _selectedIds.contains(bookId);

  // Initialize from local database
  Future<void> init(List<Book> allBooks) async {
    final cartRaw = await DatabaseHelper.instance.getCartItems();
    final wishlistIds = await DatabaseHelper.instance.getWishlistIds();
    final selectionIds = await DatabaseHelper.instance.getSelectionIds();

    _items.clear();
    for (var row in cartRaw) {
      final id = row['book_id'] as String;
      final barcode = row['barcode'] as String? ?? "";
      final rfid = row['rfid'] as String? ?? "";

      try {
        final base = allBooks.firstWhere((b) => b.id == id);
        // Reconstruct book with specific barcode if we found a match
        final book = Book(
          id: base.id,
          title: base.title,
          author: base.author,
          availableCopies: base.availableCopies,
          imagePath: base.imagePath,
          localImagePath: base.localImagePath,
          department: base.department,
          tags: base.tags,
          difficultyLevel: base.difficultyLevel,
          avgRating: base.avgRating,
          reviewCount: base.reviewCount,
          totalCopies: base.totalCopies,
          location: base.location,
          barcode: barcode,
          rfid: rfid.isNotEmpty ? rfid : base.rfid,
        );
        _items.add(book);
      } catch (e) {
        print('Cart init: Book $id not found in allBooks');
      }
    }

    // ...

    _wishlist.clear();
    _wishlist.addAll(wishlistIds);

    _selectedIds.clear();
    _selectedIds.addAll(selectionIds);

    notifyListeners();
  }

  void addItem(Book book) {
    if (_items.any((item) => item.id == book.id)) return;
    _items.add(book);
    DatabaseHelper.instance.addToCart(book.id, rfid: book.rfid);
    notifyListeners();
  }

  void addItemWithCopy(Book book, String barcode, String rfid) {
    print('DEBUG: addItemWithCopy called');
    print('DEBUG: book.id = "${book.id}"');
    print('DEBUG: book.title = "${book.title}"');
    print('DEBUG: barcode = "$barcode"');
    print('DEBUG: rfid = "$rfid"');

    // Check if this specific barcode is already in cart
    if (_items.any((item) => item.barcode == barcode)) {
      print('DEBUG: Barcode already in cart, skipping');
      return;
    }

    _items.add(book);
    print('DEBUG: Added book to _items, new count = ${_items.length}');

    // BUG FIX: Save barcode AND RFID to local cart
    DatabaseHelper.instance.addToCart(book.id, barcode: barcode, rfid: rfid);
    notifyListeners();
  }

  bool hasBarcode(String barcode) {
    return _items.any((item) => item.barcode == barcode);
  }

  Future<void> removeItems(List<String> bookIds) async {
    print('DEBUG: CartProvider.removeItems called for $bookIds');
    for (var bookId in bookIds) {
      _items.removeWhere((item) => item.id == bookId);
      _selectedIds.remove(bookId);
      await DatabaseHelper.instance.removeFromCart(bookId);
    }
    await DatabaseHelper.instance.updateSelection(_selectedIds);
    notifyListeners();
  }

  void removeItem(String bookId) {
    _items.removeWhere((item) => item.id == bookId);
    _selectedIds.remove(bookId);
    DatabaseHelper.instance.removeFromCart(bookId);
    DatabaseHelper.instance.updateSelection(_selectedIds);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedIds.clear();
    DatabaseHelper.instance.clearCart();
    DatabaseHelper.instance.updateSelection(_selectedIds);
    notifyListeners();
  }

  void toggleWishlist(String bookId) {
    if (_wishlist.contains(bookId)) {
      _wishlist.remove(bookId);
    } else {
      _wishlist.add(bookId);
    }
    // TODO: Implement updateWishlist in DatabaseHelper if needed
    notifyListeners();
  }

  void toggleSelection(String bookId) {
    print('DEBUG: toggleSelection called with bookId="$bookId"');
    print('DEBUG: Current _selectedIds before toggle: $_selectedIds');

    if (_selectedIds.contains(bookId)) {
      print('DEBUG: Removing bookId from selection');
      _selectedIds.remove(bookId);
    } else {
      print('DEBUG: Adding bookId to selection');
      _selectedIds.add(bookId);
    }

    print('DEBUG: Current _selectedIds after toggle: $_selectedIds');
    DatabaseHelper.instance.updateSelection(_selectedIds);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    DatabaseHelper.instance.updateSelection(_selectedIds);
    notifyListeners();
  }
}
