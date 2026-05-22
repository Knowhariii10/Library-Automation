import { useState, useEffect, useRef } from 'react';
import BarcodeScannerComponent from 'react-qr-barcode-scanner';
import { useNavigate } from 'react-router-dom';
import {
    CheckCircle, XCircle, AlertCircle,
    UserCheck, BookOpen, RotateCcw,
    ArrowLeft, Maximize2, Info,
    User, DollarSign, Calendar,
    Scan, RefreshCw, Moon, Sun
} from 'lucide-react';
import api from '../services/api';
import './Scanner.css';

const Scanner = () => {
    const navigate = useNavigate();
    const [scanResult, setScanResult] = useState(null);
    const [scanning, setScanning] = useState(true);
    const [isAnalyzing, setIsAnalyzing] = useState(false);
    const [sendingEmail, setSendingEmail] = useState(false);
    const [inverseMode, setInverseMode] = useState(false);
    const lastErrorText = useRef(null);
    const lastScannedQR = useRef(null); // Track last scanned QR text
    const lastScanTime = useRef(0); // Track last scan timestamp
    const [countdown, setCountdown] = useState(0);
    const timerRef = useRef(null);

    const speak = (msg) => {
        if ('speechSynthesis' in window) {
            // Cancel previous utterances to speak the new one immediately
            window.speechSynthesis.cancel();
            const utterance = new SpeechSynthesisUtterance(msg);
            utterance.rate = 1;
            window.speechSynthesis.speak(utterance);
        }
    };

    const handleScan = async (err, result) => {
        if (result && scanning && !isAnalyzing) {
            console.log("Raw QR Scanned:", result.text);

            // CRITICAL: Prevent duplicate scans of the same QR within 2 seconds
            const now = Date.now();
            const timeSinceLastScan = now - lastScanTime.current;

            if (lastScannedQR.current === result.text && timeSinceLastScan < 2000) {
                console.log(`Duplicate scan ignored (${timeSinceLastScan}ms since last scan)`);
                return; // Ignore duplicate scan
            }

            // Update tracking
            lastScannedQR.current = result.text;
            lastScanTime.current = now;

            setIsAnalyzing(true);
            try {
                let qrData;
                try {
                    qrData = JSON.parse(result.text);
                    // Robustness: Handle double-encoded string (stringified JSON inside QR)
                    if (typeof qrData === 'string') {
                        try {
                            qrData = JSON.parse(qrData);
                        } catch (e2) {
                            // If re-parsing fails, assume it's just a raw ID string
                            qrData = { user_id: qrData };
                        }
                    }
                } catch (e) {
                    qrData = { user_id: result.text };
                }

                const response = await api.post('/admin/scanner/scan_qr', qrData);
                const resData = response.data;

                console.log('Backend Response:', resData);
                console.log('User Data:', resData.data);

                if (resData.success) {
                    // Reset error tracking on success
                    lastErrorText.current = null;

                    setScanning(false);
                    const resultData = {
                        success: true,
                        purpose: resData.purpose,
                        message: resData.message,
                        data: resData.data
                    };

                    console.log('Setting scanResult with data:', resultData);
                    console.log('User data received:', resData.data);
                    setScanResult(resultData);

                    // Detailed Voice Feedback
                    let voiceMsg = `Action successful: ${resData.purpose}`;

                    if (resData.purpose === 'ATTENDANCE') {
                        const action = resData.data.is_inside ? 'Welcome in' : 'See you later';
                        voiceMsg = `Attendance marked for ${resData.data.user_name}. ${action}.`;
                    } else if (resData.purpose === 'RENTING') {
                        const date = new Date(resData.data.due_date).toLocaleDateString();
                        // Extract count from message if possible, or just Say "Renting successful"
                        // resData.message usually says "Successfully rented X book(s)"
                        voiceMsg = `${resData.message}. Due date: ${date}.`;
                    } else if (resData.purpose === 'RETURNING') {
                        voiceMsg = `${resData.message}.`;
                        if (resData.data.total_fine > 0) {
                            voiceMsg += ` Total fine is ${resData.data.total_fine} rupees.`;
                        } else {
                            voiceMsg += ` No fine.`;
                        }
                    } else if (resData.purpose === 'TRANSACTION') {
                        voiceMsg = `${resData.message}. Transaction verified.`;
                    }

                    speak(voiceMsg);
                } else {
                    setScanning(false);
                    setScanResult({
                        success: false,
                        purpose: 'INVALID',
                        message: resData.message
                    });

                    // Only speak if this is a new error content or enough time passed? 
                    // User requested: "one time invalid qr voice is enought dont say more than 1 time"
                    // We assume this means per continuous scan session of the same invalid code.
                    if (lastErrorText.current !== result.text) {
                        speak(`Invalid scan`);
                        lastErrorText.current = result.text;
                    }
                }
            } catch (error) {
                setScanning(false);
                const msg = error.response?.data?.message || 'Invalid QR. Please scan a valid library QR code.';
                setScanResult({
                    success: false,
                    purpose: 'INVALID',
                    message: msg
                });

                if (lastErrorText.current !== result.text) {
                    speak(`Invalid scan`);
                    lastErrorText.current = result.text;
                }
            } finally {
                setIsAnalyzing(false);
            }
        }
    };

    const handleOk = () => {
        if (timerRef.current) clearInterval(timerRef.current);
        setScanResult(null);
        setScanning(true);
        setCountdown(0);
        // Reset tracking to allow immediate rescan
        lastScannedQR.current = null;
        lastScanTime.current = 0;
    };

    useEffect(() => {
        if (scanResult) {
            setCountdown(5);
            timerRef.current = setInterval(() => {
                setCountdown(prev => {
                    if (prev <= 1) {
                        handleOk();
                        return 0;
                    }
                    return prev - 1;
                });
            }, 1000);
        }
        return () => {
            if (timerRef.current) clearInterval(timerRef.current);
        };
    }, [scanResult]);

    const toggleInverse = () => {
        setInverseMode(!inverseMode);
    };

    return (
        <div className="scanner-layout-container">


            <div className="scanner-nav">
                <button className="nav-back" onClick={() => navigate(-1)}>
                    <ArrowLeft size={20} />
                    <span>Back</span>
                </button>
                <div className="nav-title">UNIVERSAL QR SCANNER</div>
                <div className="nav-status-indicator">
                    <div className={`pulse-dot ${scanning ? 'active' : 'idle'}`}></div>
                    <span>{scanning ? 'READY' : 'PROCESSING'}</span>
                </div>
            </div>

            <main className="scanner-main-content">
                <section className="panel panel-left">


                    <div className="scanner-view-port">
                        <div className={`camera-container ${inverseMode ? 'inverse-active' : ''}`}>
                            <div className="scan-overlay">
                                <div className="scan-frame"></div>
                                <div className="scan-laser"></div>
                            </div>
                            <BarcodeScannerComponent
                                width={'100%'}
                                height={'100%'}
                                onUpdate={handleScan}
                                facingMode="environment"
                                delay={50}
                                videoConstraints={{
                                    width: { min: 1280, ideal: 1280, max: 1920 },
                                    height: { min: 720, ideal: 720, max: 1080 },
                                    aspectRatio: { ideal: 1.7777777778 }
                                }}
                            />
                        </div>

                        <div className="scanner-controls">
                            <button className={`control-btn ${inverseMode ? 'active' : ''}`} onClick={toggleInverse}>
                                {inverseMode ? <Sun size={18} /> : <Moon size={18} />}
                                <span>{inverseMode ? 'Normal Mode' : 'Inverse Mode'}</span>
                            </button>
                            <button className="control-btn" onClick={handleOk}>
                                <RefreshCw size={18} />
                                <span>Retry Scan</span>
                            </button>
                        </div>
                    </div>
                </section>

                <section className="panel panel-right">
                    <div className="data-area">
                        <div className="welcome-banner">
                            Welcome 😊
                        </div>
                        {isAnalyzing && (
                            <div className="mini-loader-overlay">
                                <div className="spinner"></div>
                                <span>Analyzing...</span>
                            </div>
                        )}

                        {scanResult ? (
                            <div className={`result-card ${scanResult.success ? 'success' : 'error'}`}>
                                <div className="status-banner">
                                    {scanResult.success ? 'RECOGNIZED' : 'ERROR'}
                                </div>
                                <div className="result-header">
                                    {scanResult.success ?
                                        <CheckCircle size={60} color="#10b981" /> :
                                        <XCircle size={60} color="#ef4444" />
                                    }
                                    <h1 className="purpose-label">{scanResult.purpose}</h1>
                                    <p className="main-msg">{scanResult.message}</p>
                                </div>

                                <div className="result-body">
                                    {scanResult.success && (
                                        <div className="dynamic-info-box">
                                            {/* User Info Section - Always Prominent */}
                                            {scanResult.data && (
                                                <div className="user-info-section">
                                                    <div className="section-title">USER INFORMATION</div>
                                                    <div className="user-details-grid">
                                                        <div className="detail-item">
                                                            <span className="label">Name:</span>
                                                            <span className="value">{scanResult.data.user_name && scanResult.data.user_name !== 'N/A' ? scanResult.data.user_name : 'N/A'}</span>
                                                        </div>
                                                        {scanResult.data.student_id && scanResult.data.student_id !== 'N/A' && scanResult.data.student_id !== '' && (
                                                            <div className="detail-item">
                                                                <span className="label">Student ID:</span>
                                                                <span className="value">{scanResult.data.student_id}</span>
                                                            </div>
                                                        )}
                                                        <div className="detail-item">
                                                            <span className="label">Dept:</span>
                                                            <span className="value">{scanResult.data.dept && scanResult.data.dept !== 'N/A' && scanResult.data.dept !== '' ? scanResult.data.dept : 'N/A'}</span>
                                                        </div>
                                                        <div className="detail-item">
                                                            <span className="label">Year:</span>
                                                            <span className="value">{scanResult.data.year && scanResult.data.year !== 'N/A' && scanResult.data.year !== '' ? scanResult.data.year : 'N/A'}</span>
                                                        </div>
                                                    </div>
                                                </div>
                                            )}

                                            {/* Action/Status Section */}
                                            <div className="action-details-section">
                                                {scanResult.purpose === 'ATTENDANCE' && (
                                                    <div className="attendance-status-box">
                                                        <div className={`status-pill ${scanResult.data.is_inside ? 'in' : 'out'}`}>
                                                            {scanResult.data.is_inside ? 'STATUS: ENTERED' : 'STATUS: EXITED'}
                                                        </div>
                                                        {scanResult.data.scan_time && (
                                                            <div className="time-display">
                                                                Time: {new Date(scanResult.data.scan_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                            </div>
                                                        )}

                                                    </div>
                                                )}

                                                {(scanResult.purpose === 'RENTING' || scanResult.purpose === 'TRANSACTION') && (
                                                    <div className="rental-info">
                                                        {scanResult.purpose === 'TRANSACTION' && (
                                                            <div className={`status-pill ${scanResult.data.status?.toLowerCase() || 'pending'}`}>
                                                                STATUS: {scanResult.data.status || 'PENDING'}
                                                            </div>
                                                        )}
                                                        <p className="due-date-display">Due: <strong>{new Date(scanResult.data.due_date).toLocaleDateString()}</strong></p>
                                                    </div>
                                                )}

                                                {scanResult.purpose === 'RETURNING' && (
                                                    <div className="return-details">
                                                        <div className="fine-display compact">
                                                            <span>Total Fine:</span>
                                                            <span className="amtSmall">₹{scanResult.data.total_fine}</span>
                                                        </div>
                                                        {scanResult.data.all_returned && <p className="all-clear">All books returned!</p>}
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    )}
                                    <div className="auto-refresh-notice">
                                        <div className="countdown-timer">
                                            Rescanning in <span>{countdown}</span>s...
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ) : (
                            <div className="idle-state">
                                <div className="idle-loader">
                                    <div className="loader-bar b1"></div>
                                    <div className="loader-bar b2"></div>
                                    <div className="loader-bar b3"></div>
                                </div>
                                <h3>Scan Any Library QR</h3>
                                <p>Hold steady for automatic recognition</p>
                                <div className="instructions">
                                    <div className="inst-step"><span>1</span> Attendance Cards</div>
                                    <div className="inst-step"><span>2</span> Book Rental Bundles</div>
                                    <div className="inst-step"><span>3</span> Book Return Bundles</div>
                                    <div className="inst-step"><span>4</span> Online Transactions</div>
                                </div>
                            </div>
                        )}
                    </div>
                </section>
            </main>
        </div>
    );
};

export default Scanner;
