from flask import Flask, jsonify
from flask_cors import CORS
from flask_mail import Mail
from pymongo import MongoClient
from config import Config
from routes.auth_routes import init_auth_routes
from routes.admin_routes import init_admin_routes
from routes.scanner_routes import init_scanner_routes
from utils.scheduler import init_scheduler
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("backend_debug.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Config)

# Enable CORS
CORS(app, resources={r"/*": {"origins": "*"}})

# Initialize Flask-Mail
mail = Mail(app)

# Initialize configuration
Config.init_app()

# Connect to MongoDB
try:
    client = MongoClient(Config.MONGO_URI)
    db = client[Config.DB_NAME]
    guest_db = client[Config.GUEST_DB_NAME]
    logger.info(f"Connected to MongoDB: {Config.DB_NAME} and {Config.GUEST_DB_NAME}")
except Exception as e:
    logger.error(f"Failed to connect to MongoDB: {str(e)}")
    raise

# Register blueprints
app.register_blueprint(init_auth_routes(db, mail, guest_db))
app.register_blueprint(init_admin_routes(db, guest_db))
app.register_blueprint(init_scanner_routes(db, guest_db))

from routes.user_routes import init_user_routes
app.register_blueprint(init_user_routes(db))

from routes.rfid_routes import init_rfid_routes
app.register_blueprint(init_rfid_routes(db))

from routes.review_routes import init_review_routes
app.register_blueprint(init_review_routes(db))

# Initialize scheduler for cron jobs
scheduler = init_scheduler(db)

from flask import send_from_directory

@app.route('/books_img/<path:filename>')
def serve_book_image(filename):
    # Handle redundant prefix if it exists in the URL
    if filename.startswith('books_img/'):
        filename = filename.replace('books_img/', '', 1)
    return send_from_directory(Config.UPLOAD_FOLDER, filename)

# Root endpoint
@app.route('/')
def index():
    return jsonify({
        'message': 'Library Management System API',
        'version': '1.0.0',
        'status': 'running'
    })

# Health check endpoint
@app.route('/health')
def health():
    try:
        # Check MongoDB connection
        db.command('ping')
        return jsonify({
            'status': 'healthy',
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'database': 'disconnected',
            'error': str(e)
        }), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(Exception)
def handle_exception(error):
    logger.error(f"Unhandled exception: {str(error)}")
    return jsonify({'error': 'An unexpected error occurred'}), 500

if __name__ == '__main__':
    print("\n" + "="*50)
    print(f"BACKEND STARTING ON: http://{Config.HOST}:{Config.PORT}")
    print("="*50 + "\n")
    logger.info(f"Starting Flask server on {Config.HOST}:{Config.PORT}")
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=False,
        use_reloader=False 
    )
