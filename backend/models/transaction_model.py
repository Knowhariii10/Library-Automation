from bson import ObjectId
from datetime import datetime

class TransactionModel:
    def __init__(self, db):
        self.collection = db.transactions
    
    def find_by_user(self, user_id):
        return list(self.collection.find({'user_id': ObjectId(user_id)}))

    def find_by_id(self, transaction_id):
        return self.collection.find_one({'transaction_id': transaction_id})
    
    def create(self, transaction_data):
        transactionId = transaction_data.get('transaction_id') or self.generate_txn_id()
        
        transaction = {
            'transaction_id': transactionId,
            'user_id': ObjectId(transaction_data['user_id']),
            'items': transaction_data.get('items', []),
            'amount': transaction_data.get('amount', 0.0),
            'date': transaction_data.get('date', datetime.now()),
            'type': transaction_data.get('type', 'RENTAL'), 
            'message': transaction_data.get('message', ''),
            'status': transaction_data.get('status', 'PENDING'),
            'qr_payload': transaction_data.get('qr_payload', {}),
            'created_at': datetime.now(),
            'modified_at': datetime.now(),
            'approved_at': transaction_data.get('approved_at'),
            'due_date': transaction_data.get('due_date'),
            'returned_at': None,
            'fine_amount': transaction_data.get('fine_amount', 0.0),
            'fine_paid': transaction_data.get('fine_paid', False)
        }
        result = self.collection.insert_one(transaction)
        return str(result.inserted_id), transactionId

    def generate_txn_id(self):
        """Generate a unique transaction ID like TXN-2026-000012"""
        import random
        year = datetime.now().year
        # In a real app, this should be an auto-incrementing counter from DB
        # For this prototype, we'll use a random number for uniqueness
        rand_num = random.randint(1000, 999999)
        return f"TXN-{year}-{rand_num:06d}"

    def update_status(self, transaction_id, status, approval_data=None):
        update_doc = {'status': status, 'modified_at': datetime.now()}
        if approval_data:
            update_doc.update(approval_data)
        
        return self.collection.update_one(
            {'transaction_id': transaction_id},
            {'$set': update_doc}
        )
    
    def to_dict(self, transaction):
        if not transaction:
            return None
        return {
            'id': str(transaction['_id']),
            'transaction_id': transaction.get('transaction_id', ''),
            'user_id': str(transaction['user_id']),
            'amount': transaction.get('amount', 0.0),
            'date': transaction['date'].isoformat() if isinstance(transaction['date'], datetime) else transaction['date'],
            'type': transaction.get('type', ''),
            'message': transaction.get('message', ''),
            'status': transaction.get('status', 'PENDING'),
            'items': transaction.get('items', []),
            'qr_payload': transaction.get('qr_payload', {}),
            'created_at': transaction['created_at'].isoformat() if isinstance(transaction['created_at'], datetime) else transaction['created_at'],
            'modified_at': transaction.get('modified_at', transaction['created_at']).isoformat() if isinstance(transaction.get('modified_at', transaction['created_at']), datetime) else transaction.get('modified_at', transaction['created_at']),
            'due_date': transaction['due_date'].isoformat() if isinstance(transaction.get('due_date'), datetime) else transaction.get('due_date'),
            'returned_at': transaction['returned_at'].isoformat() if isinstance(transaction.get('returned_at'), datetime) else transaction.get('returned_at'),
            'fine_amount': transaction.get('fine_amount', 0.0),
            'fine_paid': transaction.get('fine_paid', False)
        }
