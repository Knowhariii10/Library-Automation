from bson import ObjectId
from datetime import datetime

class NotificationModel:
    def __init__(self, db):
        self.collection = db.notifications
    
    def find_by_user(self, user_id, unread_only=False):
        query = {'user_id': ObjectId(user_id)}
        if unread_only:
            query['read_status'] = False
        return list(self.collection.find(query).sort('created_at', -1))
    
    def create(self, notification_data):
        notification = {
            'user_id': ObjectId(notification_data['user_id']),
            'message': notification_data['message'],
            'read_status': notification_data.get('read_status', False),
            'created_at': datetime.now()
        }
        result = self.collection.insert_one(notification)
        return str(result.inserted_id)
    
    def mark_as_read(self, notification_id):
        self.collection.update_one(
            {'_id': ObjectId(notification_id)},
            {'$set': {'read_status': True}}
        )
    
    def to_dict(self, notification):
        if not notification:
            return None
        return {
            'id': str(notification['_id']),
            'user_id': str(notification.get('user_id', '')),
            'message': notification.get('message', ''),
            'read_status': notification.get('read_status', False),
            'created_at': notification['created_at'].isoformat() if isinstance(notification.get('created_at'), datetime) else notification.get('created_at')
        }
