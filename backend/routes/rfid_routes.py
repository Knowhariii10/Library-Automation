from flask import Blueprint, jsonify
from bson import ObjectId
from models.book_model import BookModel

rfid_bp = Blueprint('rfid', __name__, url_prefix='/rfid')

def init_rfid_routes(db):
    book_model = BookModel(db)
    
    @rfid_bp.route('/check/<rfid>', methods=['GET'])
    def check_rfid(rfid):
        """
        Check if a book with this RFID is currently rented.
        Returns book info and rental status.
        Used by RFID gate security system to trigger alarm for unauthorized exits.
        """
        try:
            # Find book by RFID
            book = book_model.find_by_rfid(rfid)
            
            if not book:
                return jsonify({
                    'success': False,
                    'error': 'RFID not found in system'
                }), 404
            
            # Find the specific copy with this RFID
            specific_copy = next(
                (c for c in book.get('copies', []) if c.get('rfid') == rfid),
                None
            )
            
            if not specific_copy:
                return jsonify({
                    'success': False,
                    'error': 'Copy not found'
                }), 404
            
            # Check if this copy is currently issued (rented)
            is_rented = specific_copy.get('issued_to') is not None
            
            # If rented, get user details
            rented_to = None
            if is_rented:
                user_id = specific_copy.get('issued_to')
                user = db.users.find_one({'_id': ObjectId(user_id)})
                if user:
                    rented_to = user.get('name', 'Unknown User')
            
            return jsonify({
                'success': True,
                'rfid': rfid,
                'book_id': str(book['_id']),
                'book_title': book.get('title', 'Unknown'),
                'book_author': book.get('author', 'Unknown'),
                'is_rented': is_rented,
                'rented_to': rented_to,
                'barcode': specific_copy.get('barcode', ''),
                'message': 'Authorized exit' if is_rented else 'UNAUTHORIZED - Book not rented!'
            }), 200
            
        except Exception as e:
            print(f"Error checking RFID: {str(e)}")
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    
    return rfid_bp
