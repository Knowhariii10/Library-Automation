from bson import ObjectId
from datetime import datetime

class BookModel:
    def __init__(self, db):
        self.collection = db.books
    
    def find_all(self, skip=0, limit=50, filters=None):
        """Find all books with pagination and filters"""
        query = filters if filters else {}
        books = self.collection.find(query).skip(skip).limit(limit)
        return list(books)
    
    def find_by_rfid(self, rfid):
        """Find book copy by RFID"""
        return self.collection.find_one({'copies.rfid': rfid})

    def find_by_id(self, book_id):
        """Find book by ID"""
        return self.collection.find_one({'_id': ObjectId(book_id)})
    
    def find_by_barcode(self, barcode):
        """Find book by barcode"""
        # This method might need to be re-evaluated if 'barcode' is only within 'copies'
        # For now, it will search for a top-level barcode field, which is removed in create.
        # A more appropriate search would be {'copies.barcode': barcode}
        return self.collection.find_one({'copies.barcode': barcode})
    
    def create(self, book_data):
        """Create new book with multiple copies"""
        # copies should be a list of {barcode, rfid}
        copies_input = book_data.get('copies', [])
        copies = []
        for c in copies_input:
            copies.append({
                'barcode': c.get('barcode', ''),
                'rfid': str(c.get('rfid', '')),
                'issued_to': None  # Default is None
            })

        book = {
            'title': book_data['title'],
            'author': book_data.get('author', ''),
            'department': book_data.get('department', ''),
            'tags': book_data.get('tags', []),
            'difficulty_level': book_data.get('difficulty_level', 'beginner'),
            'copies': copies,
            'location': book_data.get('location', {'section': '', 'row': 0, 'column': 0}),
            'image_path': book_data.get('image_path', ''),
            'avg_rating': 0,
            'review_count': 0,
            'updated_at': datetime.now(),
            'version': 1
        }
        
        result = self.collection.insert_one(book)
        return result.inserted_id
    
    def update(self, book_id, update_data):
        """Update book details"""
        book = self.find_by_id(book_id)
        if not book:
            return False

        # Remove fields that shouldn't be updated directly via metadata update
        update_data.pop('_id', None)
        update_data.pop('id', None)
        
        update_data['updated_at'] = datetime.now()
        update_data['version'] = book.get('version', 1) + 1
        
        result = self.collection.update_one(
            {'_id': ObjectId(book_id)},
            {'$set': update_data}
        )
        
        return result.modified_count > 0

    def issue_copy(self, book_id, barcode_or_rfid, user_id):
        """Issue a specific copy by barcode or rfid, or first available if None"""
        import logging
        logger = logging.getLogger(__name__)
        
        logger.info(f"issue_copy called: book_id={book_id}, barcode_or_rfid={barcode_or_rfid}, user_id={user_id}")
        
        # If no specific copy identifier, issue first available copy
        if barcode_or_rfid is None:
            logger.info(f"No specific copy identifier, issuing first available copy")
            
            # First, let's check what copies exist
            book = self.collection.find_one({'_id': ObjectId(book_id)})
            if book:
                logger.info(f"Book found: {book.get('title')}, copies: {book.get('copies')}")
            else:
                logger.error(f"Book not found with id: {book_id}")
                return False
            
            result = self.collection.update_one(
                {
                    '_id': ObjectId(book_id),
                    'copies.issued_to': None
                },
                {
                    '$set': {'copies.$.issued_to': ObjectId(user_id), 'updated_at': datetime.now()}
                }
            )
            logger.info(f"Update result: matched={result.matched_count}, modified={result.modified_count}")
            return result.modified_count > 0
        
        # Otherwise, issue specific copy by barcode or rfid
        logger.info(f"Issuing specific copy by barcode/rfid: {barcode_or_rfid}")
        result = self.collection.update_one(
            {
                '_id': ObjectId(book_id),
                'copies': {
                    '$elemMatch': {
                        '$or': [{'barcode': barcode_or_rfid}, {'rfid': barcode_or_rfid}],
                        'issued_to': None
                    }
                }
            },
            {
                '$set': {'copies.$.issued_to': ObjectId(user_id), 'updated_at': datetime.now()}
            }
        )
        logger.info(f"Update result: matched={result.matched_count}, modified={result.modified_count}")
        return result.modified_count > 0

    def return_copy(self, book_id, barcode_or_rfid):
        """Return a specific copy (set issued_to to None)"""
        result = self.collection.update_one(
            {
                '_id': ObjectId(book_id),
                'copies': {
                    '$elemMatch': {
                        '$or': [{'barcode': barcode_or_rfid}, {'rfid': barcode_or_rfid}]
                    }
                }
            },
            {
                '$set': {'copies.$.issued_to': None, 'updated_at': datetime.now()}
            }
        )
        return result.modified_count > 0
    
    def update_image_path(self, book_id, image_path):
        """Update book image path"""
        return self.update(book_id, {'image_path': image_path})
    
    def adjust_availability(self, book_id, increment, user_id=None, barcode=None, rfid=None):
        """
        Adjust book availability by "issuing" or "returning" a specific copy.
        
        Args:
            book_id: Book ID
            increment: -1 to issue, +1 to return
            user_id: User ID for the operation
            barcode: Specific barcode to match (optional)
            rfid: Specific RFID to match (optional, prioritized over barcode)
            
        Returns:
            For issue (increment < 0): Dict with {'success': bool, 'allocated_copy': {...}} or None on failure
            For return (increment > 0): True/False for backward compatibility
        """
        try:
            if not isinstance(book_id, ObjectId):
                book_id = ObjectId(book_id)
            
            # Ensure user_id is ObjectId if provided
            if user_id is not None and not isinstance(user_id, ObjectId):
                user_id = ObjectId(user_id)

            if increment < 0:
                # ISSUE: search for specific barcode/RFID if provided, otherwise first null copy
                filter_query = {'_id': book_id}
                
                if barcode or rfid:
                     # CHANGE: Prioritize RFID if provided. It is more unique than barcode (which might be ISBN).
                     match_conditions = {}
                     if rfid:
                         # DEFENSIVE: Coerce to string as DB stores strings for RFID
                         match_conditions['rfid'] = str(rfid)
                     elif barcode:
                         # DEFENSIVE: Coerce to string
                         match_conditions['barcode'] = str(barcode)
                    
                     if match_conditions:
                         # We need to match a copy that is available OR already issued to this user
                         # This handles cases where a previous attempt failed but left it allocated
                         elem_match = {
                             '$or': [
                                 {'issued_to': None},
                                 {'issued_to': user_id}
                             ]
                         }
                         elem_match.update(match_conditions)
                             
                         filter_query['copies'] = {'$elemMatch': elem_match}
                else:
                    # No specific copy, find first available copy
                    filter_query['copies.issued_to'] = None
            
                print(f"DEBUG: adjust_availability QUERY: {filter_query}")
                print(f"DEBUG: user_id type: {type(user_id)}, value: {str(user_id)}")

                # Note: We use copies.$.issued_to which updates the match from $elemMatch
                result = self.collection.update_one(
                    filter_query,
                    {'$set': {'copies.$.issued_to': user_id, 'updated_at': datetime.now()}}
                )
                print(f"DEBUG: adjust_availability MATCHED: {result.matched_count}, MODIFIED: {result.modified_count}")
                
                # NEW: Return detailed information about the allocated copy
                if result.matched_count > 0: # Even if not modified, it was matched (maybe already allocated to user)
                    # Fetch the updated book to get the allocated copy details
                    updated_book = self.collection.find_one({'_id': book_id})
                    if updated_book:
                        # Find the copy that matches our criteria
                        search_rfid = str(rfid) if rfid else None
                        search_barcode = str(barcode) if barcode else None
                        
                        print(f"DEBUG: Searching for allocated copy. Search RFID: {search_rfid}, Barcode: {search_barcode}")
                        for copy in updated_book.get('copies', []):
                            copy_issued_to = copy.get('issued_to')
                            
                            # Use string comparison for safety
                            if str(copy_issued_to) != str(user_id):
                                continue
                            
                            # Match by RFID or Barcode
                            match_found = False
                            if search_rfid and str(copy.get('rfid', '')).strip() == search_rfid.strip():
                                match_found = True
                            elif search_barcode and str(copy.get('barcode', '')).strip() == search_barcode.strip():
                                match_found = True
                            elif not search_rfid and not search_barcode:
                                match_found = True
                                
                            if match_found:
                                print(f"    FOUND MATCHING COPY! RFID={copy.get('rfid')}")
                                return {
                                    'success': True,
                                    'allocated_copy': {
                                        'barcode': copy.get('barcode', ''),
                                        'rfid': copy.get('rfid', ''),
                                        'issued_to': str(copy_issued_to)
                                    }
                                }
                    
                    # If we get here but matched_count > 0, it means we found it but loop failed
                    print(f"DEBUG: Allocation verification failed for {book_id} user {user_id}")
                    logger.error(f"Allocation verification failed for {book_id} user {user_id}")
                    return None
                else:
                    print(f"DEBUG: matched_count is 0, returning None")
                    return None
            else:
                # RETURN: find first copy matching this user_id (or any if user_id is None)
                filter_q = {'_id': book_id}
                if user_id:
                    filter_q['copies.issued_to'] = user_id
                else:
                    filter_q['copies.issued_to'] = {'$ne': None}

                result = self.collection.update_one(
                    filter_q,
                    {'$set': {'copies.$.issued_to': None, 'updated_at': datetime.now()}}
                )
                return result.modified_count > 0
                
        except Exception as e:
            print(f"Error adjusting availability for {book_id}: {e}")
            return None if increment < 0 else False

    def delete(self, book_id):
        """Delete book"""
        result = self.collection.delete_one({'_id': ObjectId(book_id)})
        return result.deleted_count > 0
    
    def count(self, filters=None):
        """Count books"""
        query = filters if filters else {}
        return self.collection.count_documents(query)
    
    def to_dict(self, book):
        """Convert book document to dictionary with calculated counts"""
        if not book:
            return None
        
        copies = book.get('copies', [])
        total_copies = len(copies)
        available_copies = len([c for c in copies if c.get('issued_to') is None])
        
        return {
            'id': str(book['_id']),
            'title': book['title'],
            'author': book.get('author', ''),
            'department': book.get('department', ''),
            'tags': book.get('tags', []),
            'difficulty_level': book.get('difficulty_level', 'beginner'),
            'available': available_copies > 0,
            'total_copies': total_copies,
            'available_copies': available_copies,
            'copies': [{
                'barcode': c.get('barcode', ''),
                'rfid': c.get('rfid', ''),
                'issued_to': str(c['issued_to']) if c.get('issued_to') else None
            } for c in copies],
            'location': book.get('location', {}),
            'image_path': book.get('image_path', ''),
            'avg_rating': book.get('avg_rating', 0),
            'review_count': book.get('review_count', 0),
            'updated_at': book.get('updated_at', datetime.now()).isoformat()
        }
