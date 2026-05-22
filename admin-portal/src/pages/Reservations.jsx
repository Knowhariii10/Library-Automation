import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Calendar, Trash2, CheckCircle, AlertOctagon } from 'lucide-react';
import api from '../services/api';
import './Reservations.css';

const Reservations = () => {
    const [reservations, setReservations] = useState([]);
    const [loading, setLoading] = useState(true);
    const [cancelling, setCancelling] = useState(null);

    useEffect(() => {
        fetchReservations();
    }, []);

    const fetchReservations = async () => {
        try {
            const response = await api.get('/admin/reservations');
            if (response.data.success) {
                setReservations(response.data.reservations);
            }
        } catch (error) {
            console.error('Error fetching reservations:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleCancel = async (id) => {
        if (!window.confirm('Are you sure you want to cancel this reservation?')) return;

        setCancelling(id);
        try {
            await api.delete(`/admin/reservations/cancel/${id}`);
            setReservations(reservations.filter(res => res.id !== id));
        } catch (error) {
            console.error('Error cancelling reservation:', error);
            alert('Failed to cancel reservation');
        } finally {
            setCancelling(null);
        }
    };

    // Force update every minute to keep time relative
    const [_, setTick] = useState(0);

    useEffect(() => {
        const timer = setInterval(() => {
            setTick(t => t + 1);
        }, 60000);
        return () => clearInterval(timer);
    }, []);

    const calculateTimeLeft = (expiresAt) => {
        const now = new Date();
        const expiry = new Date(expiresAt);
        const diffMs = expiry - now;

        if (diffMs <= 0) return 'Expired';

        const diffHrs = Math.floor(diffMs / (1000 * 60 * 60));
        const diffMins = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

        if (diffHrs > 0) {
            return `${diffHrs}h ${diffMins}m left`;
        }
        return `${diffMins} mins left`;
    };

    if (loading) {
        return (
            <div className="reservations-loading">
                <div className="spinner"></div>
                <p>Loading reservations...</p>
            </div>
        );
    }

    return (
        <div className="reservations-page">
            <div className="reservations-header">
                <h1>Active Reservations</h1>
                <p className="text-muted">Manage book reservations and pickup status</p>
            </div>

            {reservations.length === 0 ? (
                <div className="empty-state card">
                    <Calendar size={48} />
                    <h3>No Active Reservations</h3>
                    <p className="text-muted">There are no books currently reserved.</p>
                </div>
            ) : (
                <div className="reservations-grid">
                    {reservations.map((res) => (
                        <div key={res.id} className="reservation-card card">
                            <div className="reservation-status">
                                <span className={`status-badge ${res.status.toLowerCase()}`}>
                                    {res.status}
                                </span>
                                <span className="expiry-time text-muted">
                                    {calculateTimeLeft(res.expires_at)}
                                </span>
                            </div>

                            <div className="reservation-details">
                                <h3>{res.book_title}</h3>
                                <p className="text-secondary">Reserved by <strong>
                                    {res.user_id ? (
                                        <Link to={`/users/${res.user_id}`} className="hover:text-primary transition-colors">
                                            {res.user_name}
                                        </Link>
                                    ) : (
                                        res.user_name
                                    )}
                                </strong></p>
                                <p className="text-muted text-sm">Book Barcode: {res.barcode}</p>
                                <p className="text-secondary text-sm mt-1">
                                    Current Stock: <span className={res.available_copies > 0 ? 'text-success' : 'text-danger'}>
                                        {res.available_copies} of {res.total_copies} units available
                                    </span>
                                </p>
                            </div>

                            <div className="reservation-meta">
                                <div className="meta-item">
                                    <span className="label">Reserved:</span>
                                    <span className="value">{new Date(res.reserved_at).toLocaleDateString()}</span>
                                </div>
                                <div className="meta-item">
                                    <span className="label">Expires:</span>
                                    <span className="value">{new Date(res.expires_at).toLocaleString()}</span>
                                </div>
                            </div>

                            <div className="reservation-actions">
                                <button
                                    className="btn btn-danger btn-sm"
                                    onClick={() => handleCancel(res.id)}
                                    disabled={cancelling === res.id}
                                >
                                    <Trash2 size={16} />
                                    {cancelling === res.id ? 'Cancelling...' : 'Cancel Reservation'}
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Reservations;
