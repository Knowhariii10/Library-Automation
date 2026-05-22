from bson import ObjectId
from datetime import datetime

class ReviewModel:
    def __init__(self, db):
        self.collection = db.reviews
        self.books_collection = db.books
    
    def create(self, review_data):
        """Create a new review and update book's avg_rating and review_count"""
        review = {
            'user_id': ObjectId(review_data['user_id']),
            'user_name': review_data['user_name'],
            'book_id': ObjectId(review_data['book_id']),
            'rating': int(review_data['rating']),  # 1-5
            'review_text': review_data.get('review_text', ''),
            'department': review_data.get('department', ''),
            'year': review_data.get('year', ''),
            'created_at': datetime.now()
        }
        
        # Insert the review
        result = self.collection.insert_one(review)
        
        # Update book's avg_rating and review_count
        if result.inserted_id:
            self.update_book_rating(review_data['book_id'])
        
        return result.inserted_id
    
    def find_by_book(self, book_id):
        """Get all reviews for a specific book"""
        reviews = self.collection.find({
            'book_id': ObjectId(book_id)
        }).sort('created_at', -1)
        return list(reviews)
    
    def find_by_user(self, user_id):
        """Get all reviews by a specific user"""
        reviews = self.collection.find({
            'user_id': ObjectId(user_id)
        }).sort('created_at', -1)
        return list(reviews)
    
    def update_book_rating(self, book_id):
        """Recalculate and update book's average rating and review count"""
        # Get all reviews for this book
        reviews = list(self.collection.find({'book_id': ObjectId(book_id)}))
        
        if not reviews:
            # No reviews, set to 0
            self.books_collection.update_one(
                {'_id': ObjectId(book_id)},
                {'$set': {'avg_rating': 0, 'review_count': 0}}
            )
            return
        
        # Calculate average rating
        total_rating = sum(r['rating'] for r in reviews)
        avg_rating = total_rating / len(reviews)
        
        # Update book document
        self.books_collection.update_one(
            {'_id': ObjectId(book_id)},
            {'$set': {
                'avg_rating': round(avg_rating, 2),
                'review_count': len(reviews)
            }}
        )

    def delete(self, review_id, user_id):
        """Delete a review and update book rating"""
        # Find the review first to get book_id
        review = self.collection.find_one({
            '_id': ObjectId(review_id),
            'user_id': ObjectId(user_id)
        })
        
        if not review:
            return False
            
        # Delete review
        result = self.collection.delete_one({'_id': ObjectId(review_id)})
        
        if result.deleted_count > 0:
            # Update book rating
            self.update_book_rating(review['book_id'])
            return True
            
        return False
    
    def to_dict(self, review):
        """Convert review document to dictionary"""
        if not review:
            return None
        
        return {
            'id': str(review['_id']),
            'user_id': str(review['user_id']),
            'user_name': review['user_name'],
            'book_id': str(review['book_id']),
            'rating': review['rating'],
            'review_text': review.get('review_text', ''),
            'department': review.get('department', ''),
            'year': review.get('year', ''),
            'created_at': review['created_at'].isoformat()
        }
