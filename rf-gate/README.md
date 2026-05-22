# RFID Gate Security System

## Overview
This is an RFID-based security system for library exit control. It prevents unauthorized removal of books by triggering an alarm when someone tries to exit with a book that hasn't been properly rented.

## How It Works

### System Logic
1. **User enters 4-digit RFID** at the exit gate
2. **System checks backend** to see if the book is currently rented
3. **Decision:**
   - ✅ **Book IS rented** → Authorized exit (no alarm)
   - 🚨 **Book NOT rented** → ALARM! Unauthorized exit attempt

### Features
- **4-Digit RFID Input**: Easy-to-use interface with auto-advancing input fields
- **Visual Alarm**: Red flashing screen overlay when alarm is triggered
- **Audio Alarm**: Beep sound plays for unauthorized exits
- **Book Information Display**: Shows book title, author, and rental status
- **Activity Log**: Tracks all scans with timestamps
- **Auto-Reset**: Automatically resets after each scan

## Setup Instructions

### 1. Backend Setup
The backend endpoint is already configured in `app.py`:
- **Endpoint**: `GET /rfid/check/<rfid>`
- **Example**: `http://localhost:5001/rfid/check/1234`

### 2. Open the HTML File
Simply open `index.html` in a web browser:
```bash
cd rf-gate
# Open index.html in your browser (double-click or use a local server)
```

### 3. Test the System

#### Test Case 1: Authorized Exit (Book is Rented)
1. Find a book that is currently rented (has `issued_to` in database)
2. Get its RFID from the database
3. Enter the 4-digit RFID in the gate system
4. **Expected**: ✅ Green "Authorized Exit" message, no alarm

#### Test Case 2: Unauthorized Exit (Book NOT Rented)
1. Find a book that is NOT rented (`issued_to` is `null`)
2. Get its RFID from the database
3. Enter the 4-digit RFID in the gate system
4. **Expected**: 🚨 Red "UNAUTHORIZED EXIT" message, alarm sound + flashing screen

## API Response Format

### Success Response (Book Found)
```json
{
  "success": true,
  "rfid": "1234",
  "book_id": "507f1f77bcf86cd799439011",
  "book_title": "Introduction to Algorithms",
  "book_author": "Thomas H. Cormen",
  "is_rented": true,
  "rented_to": "John Doe",
  "barcode": "BOOK001",
  "message": "Authorized exit"
}
```

### Error Response (RFID Not Found)
```json
{
  "success": false,
  "error": "RFID not found in system"
}
```

## Configuration

### Change Backend URL
Edit line 212 in `index.html`:
```javascript
const API_BASE_URL = 'http://localhost:5001';
```

### Customize Alarm Duration
Edit line 335 in `index.html`:
```javascript
setTimeout(() => {
    alarmAnimation.classList.remove('active');
    alarmSound.pause();
    resetForm();
}, 5000); // Change 5000 to desired milliseconds
```

## Files Structure
```
rf-gate/
├── index.html          # Main RFID gate interface
└── README.md          # This file
```

## Backend Files
```
backend/
└── routes/
    └── rfid_routes.py  # RFID validation endpoint
```

## Usage Flow
1. **Library Exit**: Person approaches exit gate with book
2. **RFID Scan**: System reads RFID tag (or person enters it manually)
3. **Validation**: System checks if book is rented
4. **Action**:
   - If rented → Gate opens, person exits
   - If NOT rented → Alarm sounds, security alerted

## Security Features
- Real-time database validation
- Visual and audio alerts
- Activity logging with timestamps
- Automatic reset to prevent bypass
- Connection error handling

## Troubleshooting

### Issue: "Connection Error"
- **Solution**: Make sure backend is running on `http://localhost:5001`
- Check if `python app.py` is running in the backend folder

### Issue: "RFID Not Found"
- **Solution**: Verify the RFID exists in the database
- Check the `copies.rfid` field in the books collection

### Issue: No Sound
- **Solution**: Browser may block autoplay audio
- Click anywhere on the page first to enable audio
- Check browser console for audio errors

## Database Schema Reference

### Book Document
```javascript
{
  "_id": ObjectId("..."),
  "title": "Book Title",
  "author": "Author Name",
  "copies": [
    {
      "rfid": "1234",           // 4-digit RFID
      "barcode": "BOOK001",
      "issued_to": ObjectId("...") // null if not rented
    }
  ]
}
```

## Future Enhancements
- [ ] Automatic RFID scanner integration (hardware)
- [ ] Email/SMS alerts to security
- [ ] Dashboard for monitoring all gate activities
- [ ] Multiple gate support
- [ ] Offline mode with local caching
