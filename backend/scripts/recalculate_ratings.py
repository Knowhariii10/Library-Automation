
import os
import sys
from pymongo import MongoClient

# Add parent directory to path to import config and models
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import Config
from models.review_model import ReviewModel
from dotenv import load_dotenv

load_dotenv()

def recalculate():
    try:
        mongo_uri = os.getenv('MONGO_URI', Config.MONGO_URI)
        db_name = os.getenv('DB_NAME', Config.DB_NAME)
        
        client = MongoClient(mongo_uri)
        db = client[db_name]
        
        print(f"Connected to database: {db_name}")
        
        review_model = ReviewModel(db)
        
        # Get all books
        books = list(db.books.find({}, {'_id': 1, 'title': 1}))
        print(f"Found {len(books)} books to check.")
        
        count = 0
        for book in books:
            book_id = book['_id']
            # update_book_rating queries reviews and updates the book document
            review_model.update_book_rating(book_id)
            count += 1
            if count % 10 == 0:
                print(f"Processed {count} books...")
                
        print(f"Recalculation complete! Processed {count} books.")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    recalculate()
