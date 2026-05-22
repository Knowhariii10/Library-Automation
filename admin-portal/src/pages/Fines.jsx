import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { CheckCircle, AlertCircle, DollarSign, Filter, Search } from 'lucide-react';
import api from '../services/api';
import './Overdue.css';
import './Fines.css';

const Fines = () => {
    const navigate = useNavigate();
    const [fines, setFines] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('ALL');
    const [searchTerm, setSearchTerm] = useState('');

    // Add Fine Modal State
    const [showAddModal, setShowAddModal] = useState(false);
    const [users, setUsers] = useState([]);
    const [selectedUser, setSelectedUser] = useState('');
    const [userRentals, setUserRentals] = useState([]);
    const [selectedBook, setSelectedBook] = useState('');
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        fetchFines();
    }, []);

    const fetchFines = async () => {
        try {
            const response = await api.get('/admin/fines');
            if (response.data.success) {
                setFines(response.data.fines);
            }
        } catch (error) {
            console.error('Error fetching fines:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchUsers = async () => {
        try {
            const response = await api.get('/admin/users');
            if (response.data.success) {
                setUsers(response.data.users);
            }
        } catch (error) {
            console.error('Error fetching users:', error);
        }
    };

    const fetchUserRentals = async (userId) => {
        if (!userId) return;
        try {
            const response = await api.get(`/admin/users/${userId}/activity`);
            if (response.data.success) {
                // Filter for active (not returned) books from history
                const active = response.data.activity.history.filter(h => !h.returned);
                setUserRentals(active);
            }
        } catch (error) {
            console.error('Error fetching user rentals:', error);
            setUserRentals([]);
        }
    };

    const handleUserChange = (userId) => {
        setSelectedUser(userId);
        setSelectedBook('');
        setUserRentals([]);
        if (userId) {
            fetchUserRentals(userId);
        }
    };

    const handleAddFine = async (e) => {
        e.preventDefault();
        if (!selectedUser || !selectedBook) {
            alert('Please select a user and a book');
            return;
        }

        setSubmitting(true);
        try {
            const response = await api.post('/admin/fines/add', {
                user_id: selectedUser,
                book_id: selectedBook,
                amount: 100,
                reason: 'Damaged Book'
            });

            if (response.data.success) {
                alert('Fine added successfully');
                setShowAddModal(false);
                setSelectedUser('');
                setSelectedBook('');
                fetchFines(); // Refresh list
            }
        } catch (error) {
            console.error('Error adding fine:', error);
            alert(error.response?.data?.error || 'Failed to add fine');
        } finally {
            setSubmitting(false);
        }
    };

    const handlePayFine = async (e, fineId) => {
        e.stopPropagation();
        if (!window.confirm('Mark this fine as paid?')) return;

        try {
            const response = await api.post(`/admin/fines/pay/${fineId}`);
            if (response.data.success) {
                alert('Fine marked as paid');
                fetchFines();
            }
        } catch (error) {
            console.error('Error paying fine:', error);
            alert('Failed to process payment');
        }
    };

    const filteredFines = fines.filter(fine => {
        const matchesFilter = filter === 'ALL' || fine.status === filter;
        const matchesSearch =
            (fine.user_name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
            (fine.user_email || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
            (fine.user_id && fine.user_id.toLowerCase().includes(searchTerm.toLowerCase()));

        return matchesFilter && matchesSearch;
    });

    const getStatusBadge = (status) => {
        switch (status) {
            case 'PAID':
                return <span className="badge badge-success">Paid</span>;
            case 'WAIVED':
                return <span className="badge badge-secondary">Waived</span>;
            case 'PENDING':
                return <span className="badge badge-danger">Pending</span>;
            default:
                return <span className="badge">{status}</span>;
        }
    };

    if (loading) {
        return (
            <div className="overdue-loading">
                <div className="spinner"></div>
                <p>Loading payment history...</p>
            </div>
        );
    }

    return (
        <div className="overdue-page">
            <div className="overdue-header">
                <div>
                    <h1>Fines & Payment History</h1>
                    <p className="text-muted">Track all fines, payments, and waivers</p>
                </div>
                <button
                    className="btn btn-primary"
                    onClick={() => {
                        setShowAddModal(true);
                        fetchUsers();
                    }}
                >
                    <AlertCircle size={18} />
                    Add Damage Fine
                </button>
            </div>

            <div className="overdue-stats">
                <div className="card stat-mini">
                    <span className="label">Total Collected</span>
                    <span className="value text-success">
                        ₹{fines.filter(f => f.status === 'PAID').reduce((acc, f) => acc + f.amount, 0).toFixed(2)}
                    </span>
                </div>
                <div className="card stat-mini">
                    <span className="label">Pending Fines</span>
                    <span className="value text-danger">
                        ₹{fines.filter(f => f.status === 'PENDING').reduce((acc, f) => acc + f.amount, 0).toFixed(2)}
                    </span>
                </div>
                <div className="card stat-mini">
                    <span className="label">Waived Amount</span>
                    <span className="value text-blue">
                        ₹{fines.filter(f => f.status === 'WAIVED').reduce((acc, f) => acc + f.amount, 0).toFixed(2)}
                    </span>
                </div>
            </div>

            <div className="filters-row card">
                <div className="search-box fines-search-box">
                    <Search className="icon" size={18} />
                    <input
                        type="text"
                        placeholder="Search student by name or ID..."
                        className="input"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>

                <select
                    className="select-box"
                    value={filter}
                    onChange={(e) => setFilter(e.target.value)}
                >
                    <option value="ALL">All Status</option>
                    <option value="PENDING">Pending Only</option>
                    <option value="PAID">Paid Only</option>
                    <option value="WAIVED">Waived Only</option>
                </select>
            </div>

            <div className="overdue-list card">
                <table className="overdue-table">
                    <thead>
                        <tr>
                            <th style={{ width: '220px' }}>Student</th>
                            <th>Email</th>
                            <th>Reason</th>
                            <th style={{ width: '120px' }}>Date</th>
                            <th style={{ width: '150px' }}>Transaction</th>
                            <th style={{ width: '120px' }}>Amount</th>
                            <th style={{ width: '120px' }}>Status</th>
                            <th className="text-right" style={{ width: '120px' }}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredFines.length === 0 ? (
                            <tr>
                                <td colSpan="8" className="text-center py-4">
                                    <div className="empty-message">
                                        <CheckCircle size={32} className="text-muted" />
                                        <p>No records found matching your filters.</p>
                                    </div>
                                </td>
                            </tr>
                        ) : (
                            filteredFines.map((fine) => (
                                <tr key={fine.id} onClick={() => navigate(`/users/${fine.user_id}`)} style={{ cursor: 'pointer' }}>
                                    <td>
                                        <div className="user-info">
                                            <span className="user-name">{fine.user_name}</span>
                                        </div>
                                    </td>
                                    <td><span className="text-muted text-sm">{fine.user_email}</span></td>
                                    <td>
                                        <span className="reason-text">
                                            {fine.reason.toLowerCase().includes('damage') ? 'Damage' :
                                                fine.reason.toLowerCase().includes('overdue') ? 'Overdue' : fine.reason}
                                        </span>
                                    </td>
                                    <td>{new Date(fine.issued_date).toLocaleDateString()}</td>
                                    <td>
                                        <span className="transaction-id">
                                            {fine.transaction_id || '-'}
                                        </span>
                                    </td>
                                    <td className="amount-cell">₹{fine.amount.toFixed(2)}</td>
                                    <td>{getStatusBadge(fine.status)}</td>
                                    <td className="text-right">
                                        {fine.status === 'PENDING' && (
                                            <button
                                                className="btn btn-primary btn-sm"
                                                onClick={(e) => handlePayFine(e, fine.id)}
                                                style={{ padding: '6px 12px', fontSize: '0.8125rem' }}
                                            >
                                                Pay Fine
                                            </button>
                                        )}
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {showAddModal && (
                <div className="modal-overlay">
                    <div className="modal-content">
                        <h2>Add Damage Fine</h2>
                        <form onSubmit={handleAddFine}>
                            <div className="form-group">
                                <label>Student</label>
                                <select
                                    className="input"
                                    value={selectedUser}
                                    onChange={(e) => handleUserChange(e.target.value)}
                                    required
                                >
                                    <option value="">Select Student</option>
                                    {users.map(u => (
                                        <option key={u.id} value={u.id}>{u.name} ({u.student_id})</option>
                                    ))}
                                </select>
                            </div>

                            <div className="form-group">
                                <label>Damaged Book (Rental)</label>
                                <select
                                    className="input"
                                    value={selectedBook}
                                    onChange={(e) => setSelectedBook(e.target.value)}
                                    required
                                    disabled={!selectedUser}
                                >
                                    <option value="">Select Book</option>
                                    {userRentals.map(r => (
                                        <option key={r.book_id} value={r.book_id}>
                                            {r.book_title} (Due: {new Date(r.due_date).toLocaleDateString()})
                                        </option>
                                    ))}
                                </select>
                            </div>

                            <div className="form-group">
                                <label>Fine Amount</label>
                                <div className="input-group">
                                    <span className="input-prefix">₹</span>
                                    <input type="number" className="input" value="100" disabled />
                                </div>
                                <small className="text-muted">Fixed amount for book damage</small>
                            </div>

                            <div className="modal-actions">
                                <button type="button" className="btn btn-secondary" onClick={() => setShowAddModal(false)}>Cancel</button>
                                <button type="submit" className="btn btn-primary" disabled={submitting}>
                                    {submitting ? 'Adding...' : 'Add Fine'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div >
    );
};

export default Fines;
