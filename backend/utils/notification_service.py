import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from bson import ObjectId
from config import Config

def send_email(to_email, subject, body):
    """
    Send an email using SMTP
    """
    try:
        msg = MIMEMultipart()
        msg['From'] = f"{Config.EMAIL_FROM_NAME} <{Config.SMTP_USER}>"
        msg['To'] = to_email
        msg['Subject'] = subject

        msg.attach(MIMEText(body, 'plain', 'utf-8'))

        server = smtplib.SMTP(Config.SMTP_SERVER, Config.SMTP_PORT)
        server.starttls()
        server.login(Config.SMTP_USER, Config.SMTP_PASSWORD)
        text = msg.as_string()
        server.sendmail(Config.SMTP_USER, to_email, text)
        server.quit()
        return True
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error sending email: {e}")
        return False

def create_notification(db, user_id, title, message, notification_type='SYSTEM'):
    """
    Create a notification for a user
    
    Args:
        db: MongoDB database instance
        user_id: ObjectId or string
        title: str
        message: str
        notification_type: str (OVERDUE, RESERVATION, FINE, SYSTEM)
    
    Returns:
        ObjectId: notification ID
    """
    notification = {
        'user_id': ObjectId(user_id) if isinstance(user_id, str) else user_id,
        'title': title,
        'message': message,
        'type': notification_type,
        'created_at': datetime.now(),
        'read': False
    }
    
    result = db.notifications.insert_one(notification)
    return result.inserted_id

def send_overdue_notifications(db):
    """
    Send notifications to users with overdue books
    
    Returns:
        dict: {
            'notifications_sent': int,
            'users_notified': list
        }
    """
    from utils.fine_calculator import calculate_fine
    
    notifications_sent = 0
    users_notified = []
    
    # Find all active rentals
    active_rentals = db.renting.find({'status': 'ACTIVE'})
    
    for rental in active_rentals:
        user = db.users.find_one({'_id': rental['user_id']})
        if not user:
            continue
            
        overdue_books = []
        
        for book in rental['books']:
            if not book.get('returned', False):
                fine_info = calculate_fine(book['due_date'])
                
                if fine_info['is_overdue']:
                    overdue_books.append({
                        'title': book['title'],
                        'days_overdue': fine_info['days_overdue'],
                        'fine': fine_info['fine_amount']
                    })
        
        if overdue_books:
            # Create in-app notification
            book_list = ', '.join([f"{b['title']} ({b['days_overdue']} days)" for b in overdue_books])
            total_fine = sum([b['fine'] for b in overdue_books])
            
            message = f"You have {len(overdue_books)} overdue book(s): {book_list}. Total fine: Rs.{total_fine}"
            
            create_notification(
                db,
                rental['user_id'],
                'Overdue Books Reminder',
                message,
                'OVERDUE'
            )
            
            # Send email notification
            if user.get('email'):
                email_body = f"Hello {user.get('name', 'User')},\n\n This is a reminder that you have {len(overdue_books)} overdue book(s):\n\n"
                for b in overdue_books:
                    email_body += f"- {b['title']}: {b['days_overdue']} days overdue (Fine: Rs.{b['fine']})\n"
                email_body += f"\nTotal Fine: Rs.{total_fine}\n\nPlease return the books at the earliest to avoid further fines.\n\nRegards,\n{Config.EMAIL_FROM_NAME}"
                
                send_email(user['email'], 'Overdue Books Reminder', email_body)
            
            notifications_sent += 1
            users_notified.append(str(rental['user_id']))
    
    return {
        'notifications_sent': notifications_sent,
        'users_notified': users_notified
    }

def send_single_overdue_notification(db, user_id):
    """Send overdue notification to a single user"""
    from utils.fine_calculator import calculate_fine
    
    user = db.users.find_one({'_id': ObjectId(user_id)})
    if not user:
        return {'success': False, 'error': 'User not found'}
        
    rental = db.renting.find_one({'user_id': ObjectId(user_id), 'status': 'ACTIVE'})
    if not rental:
        return {'success': False, 'error': 'No active rentals for this user'}
        
    overdue_books = []
    for book in rental['books']:
        if not book.get('returned', False):
            fine_info = calculate_fine(book['due_date'])
            if fine_info['is_overdue']:
                overdue_books.append({
                    'title': book['title'],
                    'days_overdue': fine_info['days_overdue'],
                    'fine': fine_info['fine_amount']
                })
                
    if not overdue_books:
        return {'success': False, 'error': 'No overdue books for this user'}
        
    book_list = ', '.join([f"{b['title']} ({b['days_overdue']} days)" for b in overdue_books])
    total_fine = sum([b['fine'] for b in overdue_books])
    message = f"URGENT: You have {len(overdue_books)} overdue book(s): {book_list}. Total fine: Rs.{total_fine}"
    
    create_notification(db, user_id, 'Urgent Overdue Reminder', message, 'OVERDUE')
    
    if user.get('email'):
        email_body = f"Hello {user.get('name', 'User')},\n\n This is an URGENT reminder that you have {len(overdue_books)} overdue book(s):\n\n"
        for b in overdue_books:
            email_body += f"- {b['title']}: {b['days_overdue']} days overdue (Fine: Rs.{b['fine']})\n"
        email_body += f"\nTotal Fine: Rs.{total_fine}\n\nPlease return the books immediately.\n\nRegards,\n{Config.EMAIL_FROM_NAME}"
        
        email_success = send_email(user['email'], 'URGENT: Overdue Books Reminder', email_body)
        if not email_success:
            return {'success': False, 'error': 'Failed to send email. Check backend logs.'}
            
        print(f"DEBUG: Email sent successfully to {user['email']}")
        return {'success': True, 'message': f"Notification sent to {user['email']}"}
    else:
        print(f"DEBUG: User {user.get('name')} has no email address")
        return {'success': True, 'message': 'In-app notification sent (User has no email address)'}

def send_reservation_notification(db, user_id, book_title):
    """Send notification when a reserved book becomes available"""
    message = f'Your reserved book "{book_title}" is now available for pickup. Please collect it within 24 hours.'
    
    create_notification(
        db,
        user_id,
        'Reserved Book Available',
        message,
        'RESERVATION'
    )

def send_fine_notification(db, user_id, fine_amount, reason):
    """Send notification about a new fine"""
    message = f'A fine of Rs.{fine_amount} has been issued for {reason}. Please pay at the earliest.'
    
    create_notification(
        db,
        user_id,
        'Fine Issued',
        message,
        'FINE'
    )
