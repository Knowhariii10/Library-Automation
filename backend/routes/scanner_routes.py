from flask import Blueprint, request, jsonify
from utils.jwt_utils import token_required
from utils.qr_handler import handle_qr_scan

scanner_bp = Blueprint('scanner', __name__, url_prefix='/admin/scanner')

def init_scanner_routes(db, guest_db=None):
    """Initialize scanner routes with database"""
    
    @scanner_bp.route('/scan_qr', methods=['POST'])
    @token_required
    def scan_qr():
        """Handle QR code scanning with multi-purpose detection"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'No QR data provided'}), 400
            
            print(f"DEBUG: scan_qr received data: {data}")

            # Add admin ID to QR data for logging
            if isinstance(data, dict):
                data['admin_id'] = request.admin_id
            else:
                print(f"DEBUG: Expected dict but got {type(data)}")
            
            # Handle QR scan
            result = handle_qr_scan(data, db, guest_db)
            
            if result['success']:
                return jsonify(result), 200
            else:
                print(f"DEBUG: scan_qr failed with: {result}")
                return jsonify(result), 400
            
        except Exception as e:
            return jsonify({
                'success': False,
                'purpose': 'ERROR',
                'message': f'Error processing QR code: {str(e)}'
            }), 500
            
    @scanner_bp.route('/send_attendance_email', methods=['POST'])
    @token_required
    def send_attendance_email():
        """Send attendance success email to user"""
        try:
            data = request.get_json()
            user_id = data.get('user_id')
            status = data.get('status') # boolean: True for in, False for out
            
            if not user_id:
                return jsonify({'error': 'User ID is required'}), 400
            
            from utils.notification_service import send_attendance_success_email
            
            success = send_attendance_success_email(db, user_id, status)
            
            if success:
                return jsonify({'success': True, 'message': 'Email sent successfully'}), 200
            else:
                return jsonify({'success': False, 'message': 'Failed to send email or user has no email'}), 400
                
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    return scanner_bp
