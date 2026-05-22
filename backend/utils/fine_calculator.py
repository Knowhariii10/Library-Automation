from datetime import datetime, timedelta
from config import Config

def calculate_fine(due_date, return_date=None):
    """
    Calculate fine based on days overdue
    
    Args:
        due_date: datetime object or ISO string
        return_date: datetime object or ISO string (defaults to now)
    
    Returns:
        dict: {
            'days_overdue': int,
            'fine_amount': float,
            'is_overdue': bool
        }
    """
    # Convert to datetime if string
    if isinstance(due_date, str):
        due_date = datetime.fromisoformat(due_date.replace('Z', '+00:00'))
    
    if return_date is None:
        return_date = datetime.now()
    elif isinstance(return_date, str):
        return_date = datetime.fromisoformat(return_date.replace('Z', '+00:00'))
    
    # Calculate days overdue
    if return_date > due_date:
        days_overdue = (return_date - due_date).days
        fine_amount = days_overdue * Config.FINE_PER_DAY
        is_overdue = True
    else:
        days_overdue = 0
        fine_amount = 0.0
        is_overdue = False
    
    return {
        'days_overdue': days_overdue,
        'fine_amount': fine_amount,
        'is_overdue': is_overdue
    }

def calculate_rental_due_date(rental_date=None, duration_days=None):
    """
    Calculate due date for a rental
    
    Args:
        rental_date: datetime object (defaults to now)
        duration_days: int (defaults to Config.RENTAL_DURATION_DAYS)
    
    Returns:
        datetime: due date
    """
    if rental_date is None:
        rental_date = datetime.now()
    
    if duration_days is None:
        duration_days = Config.RENTAL_DURATION_DAYS
    
    return rental_date + timedelta(days=duration_days)
