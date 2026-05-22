from flask import Blueprint, request, jsonify
from models.review_model import ReviewModel
from utils.jwt_utils import token_required
import logging

logger = logging.getLogger(__name__)

def init_review_routes(db):
    """Initialize review routes with database connection"""
    review_bp = Blueprint('review', __name__)

    @review_bp.route('/api/reviews', methods=['POST'])
    def submit_review():
        """Submit a new review for a book"""
        # Manual token validation
        from flask import request
        from models.user_model import UserModel
        from bson import ObjectId
        
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'No token provided'}), 401
        
        try:
            # Remove 'Bearer ' prefix if present
            if token.startswith('Bearer '):
                token = token[7:]
            
            from utils.jwt_utils import decode_token
            payload = decode_token(token)
            if not payload:
                return jsonify({'error': 'Invalid token'}), 401
            
            # Get user from database
            user_id = payload.get('user_id')
            if not user_id:
                return jsonify({'error': 'Invalid token'}), 401
            
            user_model = UserModel(db)
            current_user = user_model.find_by_id(user_id)
            if not current_user:
                return jsonify({'error': 'User not found'}), 401
                
        except Exception as e:
            logger.error(f"Token validation error: {str(e)}")
            return jsonify({'error': 'Invalid token'}), 401
        
        try:
            data = request.get_json()
            
            # Validate required fields
            if not data.get('book_id'):
                return jsonify({'error': 'Book ID is required'}), 400
            
            if not data.get('rating') or not isinstance(data.get('rating'), int):
                return jsonify({'error': 'Valid rating (1-5) is required'}), 400
            
            rating = int(data['rating'])
            if rating < 1 or rating > 5:
                return jsonify({'error': 'Rating must be between 1 and 5'}), 400
            
            # Prepare review data
            review_data = {
                'user_id': str(current_user['_id']),
                'user_name': current_user.get('name', 'Anonymous'),
                'book_id': data['book_id'],
                'rating': rating,
                'review_text': data.get('review_text', ''),
                'department': current_user.get('department', ''),
                'year': current_user.get('year', '')
            }
            
            # Create review
            review_model = ReviewModel(db)
            review_id = review_model.create(review_data)
            
            if review_id:
                logger.info(f"Review created: {review_id} for book {data['book_id']} by user {current_user['_id']}")
                return jsonify({
                    'success': True,
                    'message': 'Review submitted successfully',
                    'review_id': str(review_id)
                }), 201
            else:
                return jsonify({'error': 'Failed to create review'}), 500
                
        except Exception as e:
            logger.error(f"Error submitting review: {str(e)}")
            return jsonify({'error': 'Internal server error'}), 500


    @review_bp.route('/api/reviews/book/<book_id>', methods=['GET'])
    def get_book_reviews(book_id):
        """Get all reviews for a specific book"""
        try:
            review_model = ReviewModel(db)
            
            reviews = review_model.find_by_book(book_id)
            reviews_list = [review_model.to_dict(r) for r in reviews]
            
            return jsonify({
                'success': True,
                'reviews': reviews_list,
                'count': len(reviews_list)
            }), 200
            
        except Exception as e:
            logger.error(f"Error fetching book reviews: {str(e)}")
            return jsonify({'error': 'Internal server error'}), 500


    @review_bp.route('/api/reviews/user', methods=['GET'])
    def get_user_reviews():
        """Get all reviews by the authenticated user"""
        # Manual token validation
        from flask import request
        from models.user_model import UserModel
        from bson import ObjectId
        
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'error': 'No token provided'}), 401
        
        try:
            # Remove 'Bearer ' prefix if present
            if token.startswith('Bearer '):
                token = token[7:]
            
            from utils.jwt_utils import decode_token
            payload = decode_token(token)
            if not payload:
                return jsonify({'error': 'Invalid token'}), 401
            
            # Get user from database
            user_id = payload.get('user_id')
            if not user_id:
                return jsonify({'error': 'Invalid token'}), 401
            
            user_model = UserModel(db)
            current_user = user_model.find_by_id(user_id)
            if not current_user:
                return jsonify({'error': 'User not found'}), 401
                
        except Exception as e:
            logger.error(f"Token validation error: {str(e)}")
            return jsonify({'error': 'Invalid token'}), 401
        
        try:
            review_model = ReviewModel(db)
            
            reviews = review_model.find_by_user(str(current_user['_id']))
            reviews_list = [review_model.to_dict(r) for r in reviews]
            
            return jsonify({
                'success': True,
                'reviews': reviews_list,
                'count': len(reviews_list)
            }), 200
            
        except Exception as e:
            logger.error(f"Error fetching user reviews: {str(e)}")
            return jsonify({'error': 'Internal server error'}), 500

    @review_bp.route('/api/reviews/<review_id>', methods=['DELETE'])
    @token_required
    def delete_review(review_id):
        """Delete a review"""
        try:
            # Check if user is authenticated (student)
            if not getattr(request, 'user_id', None):
                 return jsonify({'error': 'Unauthorized'}), 401
                
            review_model = ReviewModel(db)
            success = review_model.delete(review_id, request.user_id)
            
            if success:
                return jsonify({'success': True, 'message': 'Review deleted successfully'}), 200
            else:
                return jsonify({'error': 'Review not found or unauthorized'}), 404
                
        except Exception as e:
            logger.error(f"Error deleting review: {str(e)}")
            return jsonify({'error': 'Internal server error'}), 500

    return review_bp



