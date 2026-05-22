from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_scheduler(db):
    """Initialize APScheduler with cron jobs"""
    scheduler = BackgroundScheduler()
    
    # Add job to check overdue books daily at 10 AM
    scheduler.add_job(
        func=check_overdue_books,
        trigger='cron',
        hour=11,
        minute=0,
        args=[db],
        id='overdue_check',
        name='Check overdue books and send notifications',
        replace_existing=True
    )
    
    # Add job to expire reservations every hour
    scheduler.add_job(
        func=expire_reservations,
        trigger='cron',
        minute=0,
        args=[db],
        id='reservation_expiry',
        name='Expire old reservations',
        replace_existing=True
    )
    
    scheduler.start()
    logger.info('Scheduler started successfully')
    
    return scheduler

def check_overdue_books(db):
    """Cron job to check overdue books and send notifications"""
    from utils.notification_service import send_overdue_notifications
    
    logger.info('Running overdue books check...')
    
    try:
        result = send_overdue_notifications(db)
        logger.info(f"Sent {result['notifications_sent']} overdue notifications")
    except Exception as e:
        logger.error(f"Error checking overdue books: {str(e)}")

def expire_reservations(db):
    """Cron job to expire old reservations and restore book availability"""
    logger.info('Running reservation expiry check...')
    
    try:
        # Find expired reservations that are still ACTIVE
        now = datetime.now()
        expired_reservations = list(db.reservations.find({
            'status': 'ACTIVE',
            'expires_at': {'$lt': now}
        }))
        
        from models.book_model import BookModel
        from models.notification_model import NotificationModel
        book_model = BookModel(db)
        notification_model = NotificationModel(db)
        
        for res in expired_reservations:
            # Update reservation status
            db.reservations.update_one(
                {'_id': res['_id']},
                {'$set': {'status': 'EXPIRED'}}
            )
            
            # Restore book availability safely using centralized helper
            book_model.adjust_availability(res['book_id'], 1)
            
            # Create notification for the student
            try:
                notification_model.create({
                    'user_id': str(res['user_id']),
                    'message': f"Your reservation for '{res.get('book_title', 'Unknown Book')}' has expired."
                })
            except Exception as notify_err:
                logger.error(f"Error creating expiry notification: {str(notify_err)}")

            logger.info(f"Expired reservation {res['_id']} for book {res['book_id']}")
            
        if expired_reservations:
            logger.info(f"Expired {len(expired_reservations)} reservations total")
            
    except Exception as e:
        logger.error(f"Error expiring reservations: {str(e)}")
