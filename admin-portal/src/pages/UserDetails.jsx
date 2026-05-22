import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { User, Calendar, BookOpen, AlertCircle, Clock } from 'lucide-react';
import api from '../services/api';
import './UserDetails.css';

const UserDetails = () => {
    const { userId } = useParams();
    const navigate = useNavigate();
    const [user, setUser] = useState(null);
    const [activity, setActivity] = useState({
        reservations: [],
        history: [],
        overdue: []
    });
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState('overview');

    const [activityLoading, setActivityLoading] = useState(true);
    const [activityError, setActivityError] = useState(null);

    useEffect(() => {
        if (userId) {
            fetchUserProfile();
            fetchUserActivity();
        }
    }, [userId]);

    const fetchUserProfile = async () => {
        setLoading(true);
        try {
            const response = await api.get(`/admin/users/${userId}`);
            if (response.data.success) {
                setUser(response.data.user);
            }
        } catch (error) {
            console.error('Error fetching user profile:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchUserActivity = async () => {
        setActivityLoading(true);
        setActivityError(null);
        try {
            const response = await api.get(`/admin/users/${userId}/activity`);
            if (response.data.success) {
                setActivity(response.data.activity);
            }
        } catch (error) {
            console.error('Error fetching user activity:', error);
            setActivityError('Failed to load activity data');
        } finally {
            setActivityLoading(false);
        }
    };

    if (loading) return <div className="loading">Loading user profile...</div>;
    if (!user) return <div className="error">User not found</div>;

    return (
        <div className="user-details-page">
            <div className="user-header card">
                <div className="user-profile-icon">
                    <User size={48} />
                </div>
                <div className="user-info">
                    <h1>{user.name}</h1>
                    <p className="text-muted">{user.email}</p>
                    <div className="user-meta">
                        <span className="badge">{user.department}</span>
                        <span className="badge">{user.year} Year</span>
                        <span className="text-sm text-muted">Joined {new Date(user.joined_at).toLocaleDateString()}</span>
                    </div>
                </div>
            </div>

            <div className="user-tabs">
                <button
                    className={`tab-btn ${activeTab === 'overview' ? 'active' : ''}`}
                    onClick={() => setActiveTab('overview')}
                >
                    <BookOpen size={16} /> Overview
                </button>
                <button
                    className={`tab-btn ${activeTab === 'reservations' ? 'active' : ''}`}
                    onClick={() => setActiveTab('reservations')}
                >
                    <Calendar size={16} /> Reservations ({activity.reservations.length})
                </button>
                <button
                    className={`tab-btn ${activeTab === 'history' ? 'active' : ''}`}
                    onClick={() => setActiveTab('history')}
                >
                    <Clock size={16} /> History
                </button>
                <button
                    className={`tab-btn ${activeTab === 'fines' ? 'active' : ''}`}
                    onClick={() => setActiveTab('fines')}
                >
                    <AlertCircle size={16} /> Fines ({activity.fines?.length || 0})
                </button>
                <button
                    className={`tab-btn ${activeTab === 'transactions' ? 'active' : ''}`}
                    onClick={() => setActiveTab('transactions')}
                >
                    <Clock size={16} /> Transactions ({activity.transactions?.length || 0})
                </button>
            </div>

            <div className="tab-content">
                {activeTab === 'overview' && (
                    <div className="overview-grid">
                        {activityLoading ? (
                            <div className="overview-card"><h3>Loading statistics...</h3></div>
                        ) : activityError ? (
                            <div className="overview-card"><h3 className="text-danger">Error</h3><p>{activityError}</p></div>
                        ) : (
                            <>
                                <div className="overview-card">
                                    <h3>Currently Overdue</h3>
                                    <div className="stat-big text-danger">{activity.overdue?.length || 0}</div>
                                    <p>Active overdue items</p>
                                </div>
                                <div className="overview-card">
                                    <h3>Active Reservations</h3>
                                    <div className="stat-big text-success">{activity.reservations?.length || 0}</div>
                                    <p>Reserved books awaiting pickup</p>
                                </div>
                                <div className="overview-card">
                                    <h3>Total Borrowed</h3>
                                    <div className="stat-big text-info">{activity.history?.length || 0}</div>
                                    <p>Total lifetime rentals</p>
                                </div>
                            </>
                        )}
                    </div>
                )}

                {activeTab === 'reservations' && (
                    <div className="card">
                        <h3>Reservations</h3>
                        {activityLoading ? (
                            <p>Loading reservations...</p>
                        ) : activityError ? (
                            <p className="text-danger">{activityError}</p>
                        ) : (
                            <table className="table">
                                <thead>
                                    <tr>
                                        <th>Book</th>
                                        <th>Reserved At</th>
                                        <th>Expires At</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {activity.reservations.map(res => (
                                        <tr key={res.id}>
                                            <td>{res.book_title}</td>
                                            <td>{new Date(res.reserved_at).toLocaleDateString()}</td>
                                            <td>{new Date(res.expires_at).toLocaleDateString()}</td>
                                            <td><span className={`badge badge-${res.status.toLowerCase()}`}>{res.status}</span></td>
                                        </tr>
                                    ))}
                                    {activity.reservations.length === 0 && (
                                        <tr><td colSpan="4" className="text-center">No active reservations</td></tr>
                                    )}
                                </tbody>
                            </table>
                        )}
                    </div>
                )}

                {activeTab === 'history' && (
                    <div className="card">
                        <h3>Rental History</h3>
                        {activityLoading ? (
                            <p>Loading history...</p>
                        ) : activityError ? (
                            <p className="text-danger">{activityError}</p>
                        ) : (
                            <table className="table">
                                <thead>
                                    <tr>
                                        <th>Book</th>
                                        <th>Borrowed</th>
                                        <th>Due Date</th>
                                        <th>Status</th>
                                        <th>Fines</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {activity.history.map((item, idx) => (
                                        <tr key={idx}>
                                            <td>{item.book_title}</td>
                                            <td>{new Date(item.borrowed_at).toLocaleDateString()}</td>
                                            <td>{new Date(item.due_date).toLocaleDateString()}</td>
                                            <td>
                                                {item.returned ? (
                                                    <span className="badge badge-success">Returned</span>
                                                ) : (
                                                    <span className={`badge ${item.is_overdue ? 'badge-danger' : 'badge-warning'}`}>
                                                        {item.is_overdue ? `Overdue (${item.days_overdue} days)` : 'Active'}
                                                    </span>
                                                )}
                                            </td>
                                            <td>{item.fine > 0 ? `₹${item.fine}` : '-'}</td>
                                        </tr>
                                    ))}
                                    {activity.history.length === 0 && (
                                        <tr><td colSpan="5" className="text-center">No rental history</td></tr>
                                    )}
                                </tbody>
                            </table>
                        )}
                    </div>
                )}
                {activeTab === 'fines' && (
                    <div className="card">
                        <h3>Fines History</h3>
                        {activityLoading ? (
                            <p>Loading fines...</p>
                        ) : activityError ? (
                            <p className="text-danger">{activityError}</p>
                        ) : (
                            <table className="table">
                                <thead>
                                    <tr>
                                        <th>Reason</th>
                                        <th>Amount</th>
                                        <th>Issued At</th>
                                        <th>Status</th>
                                        <th>Paid At</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {activity.fines?.map((fine, idx) => (
                                        <tr key={idx}>
                                            <td>{fine.reason}</td>
                                            <td className="font-bold">₹{fine.amount.toFixed(2)}</td>
                                            <td>{new Date(fine.issued_date).toLocaleDateString()}</td>
                                            <td>
                                                <span className={`badge badge-${fine.status.toLowerCase()}`}>
                                                    {fine.status}
                                                </span>
                                            </td>
                                            <td>{fine.paid_date ? new Date(fine.paid_date).toLocaleDateString() : '-'}</td>
                                        </tr>
                                    ))}
                                    {(!activity.fines || activity.fines.length === 0) && (
                                        <tr><td colSpan="5" className="text-center">No fines recorded</td></tr>
                                    )}
                                </tbody>
                            </table>
                        )}
                    </div>
                )}
                {activeTab === 'transactions' && (
                    <div className="card">
                        <h3>Transaction History</h3>
                        {activityLoading ? (
                            <p>Loading transactions...</p>
                        ) : activityError ? (
                            <p className="text-danger">{activityError}</p>
                        ) : (
                            <table className="table">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Date</th>
                                        <th>Type</th>
                                        <th>Status</th>
                                        <th>Items</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {activity.transactions?.map((tx, idx) => (
                                        <tr key={idx}>
                                            <td className="font-bold">{tx.transaction_id}</td>
                                            <td>{new Date(tx.date).toLocaleDateString()}</td>
                                            <td>{tx.type}</td>
                                            <td>
                                                <span className={`badge badge-${tx.status.toLowerCase()}`}>
                                                    {tx.status}
                                                </span>
                                            </td>
                                            <td>{tx.items?.length || 0} books</td>
                                        </tr>
                                    ))}
                                    {(!activity.transactions || activity.transactions.length === 0) && (
                                        <tr><td colSpan="5" className="text-center">No transactions recorded</td></tr>
                                    )}
                                </tbody>
                            </table>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
};

export default UserDetails;
