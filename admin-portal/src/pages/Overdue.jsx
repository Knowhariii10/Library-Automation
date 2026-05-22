import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { AlertCircle, Bell, Mail, Search, CheckCircle } from 'lucide-react';
import api from '../services/api';
import './Overdue.css';

const Overdue = () => {
    const navigate = useNavigate();
    const [overdueItems, setOverdueItems] = useState([]);
    const [loading, setLoading] = useState(true);
    const [notifying, setNotifying] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

    const [yearFilter, setYearFilter] = useState('ALL');
    const [deptFilter, setDeptFilter] = useState('ALL');

    useEffect(() => {
        fetchOverdue();
    }, []);

    // Filter constants
    const YEARS = [
        { value: '1', label: '1st Year' },
        { value: '2', label: '2nd Year' },
        { value: '3', label: '3rd Year' },
        { value: '4', label: 'Final Year' }
    ];

    const DEPTS = [
        { value: 'Computer Science', label: 'CSE' },
        { value: 'Mechanical', label: 'MECH' },
        { value: 'Electronics', label: 'ECE' },
        { value: 'Electrical', label: 'EEE' },
        { value: 'Civil', label: 'CIVIL' }
    ];

    const filteredItems = overdueItems.filter(item => {
        const matchesYear = yearFilter === 'ALL' || item.year?.toString() === yearFilter;
        const matchesDept = deptFilter === 'ALL' || item.department === deptFilter;
        const matchesSearch =
            item.user_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.student_id?.toLowerCase().includes(searchTerm.toLowerCase());
        return matchesYear && matchesDept && matchesSearch;
    });

    const fetchOverdue = async () => {
        try {
            const response = await api.get('/admin/overdue');
            if (response.data.success) {
                setOverdueItems(response.data.overdue);
            }
        } catch (error) {
            console.error('Error fetching overdue items:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleNotifyAll = async () => {
        setNotifying(true);
        try {
            const response = await api.post('/admin/notify/overdue');
            if (response.data.success) {
                alert(`Successfully sent notifications to ${response.data.notifications_sent} users.`);
            }
        } catch (error) {
            console.error('Error sending notifications:', error);
            alert('Failed to send notifications');
        } finally {
            setNotifying(false);
        }
    };

    const handleNotifyUser = async (e, userId) => {
        e.stopPropagation(); // Don't navigate when clicking mail icon
        if (!window.confirm('Send urgent overdue email to this user?')) return;

        try {
            const response = await api.post(`/admin/notify/user/${userId}`);
            if (response.data.success) {
                alert(response.data.message);
            }
        } catch (error) {
            console.error('Error notifying user:', error);
            alert(error.response?.data?.error || 'Failed to send notification');
        }
    };

    if (loading) {
        return (
            <div className="overdue-loading">
                <div className="spinner"></div>
                <p>Loading overdue items...</p>
            </div>
        );
    }

    return (
        <div className="overdue-page">
            <div className="overdue-header">
                <div>
                    <h1>Overdue Books</h1>
                    <p className="text-muted">Monitor overdue returns and manage fines</p>
                </div>

                <div className="flex gap-md">
                    {overdueItems.length > 0 && (
                        <button
                            className="btn btn-warning"
                            onClick={handleNotifyAll}
                            disabled={notifying}
                        >
                            <Bell size={18} />
                            {notifying ? 'Sending...' : 'Notify All'}
                        </button>
                    )}
                </div>
            </div>

            <div className="filters-row card">
                <div className="search-box">
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
                    value={yearFilter}
                    onChange={(e) => setYearFilter(e.target.value)}
                >
                    <option value="ALL">All Years</option>
                    {YEARS.map(y => <option key={y.value} value={y.value}>{y.label}</option>)}
                </select>

                <select
                    className="select-box"
                    value={deptFilter}
                    onChange={(e) => setDeptFilter(e.target.value)}
                >
                    <option value="ALL">All Depts</option>
                    {DEPTS.map(d => <option key={d.value} value={d.value}>{d.label}</option>)}
                </select>
            </div>

            <div className="overdue-stats">
                <div className="card stat-mini">
                    <span className="label">Total Overdue</span>
                    <span className="value text-danger">{overdueItems.length}</span>
                </div>
                <div className="card stat-mini">
                    <span className="label">Total Fines</span>
                    <span className="value text-warning">
                        ₹{overdueItems.reduce((acc, item) => acc + item.fine_amount, 0).toFixed(2)}
                    </span>
                </div>
            </div>

            <div className="overdue-list card">
                <table className="overdue-table">
                    <thead>
                        <tr>
                            <th style={{ width: '220px' }}>Student</th>
                            <th style={{ width: '150px' }}>Details</th>
                            <th style={{ width: '200px' }}>Email</th>
                            <th>Book / Author</th>
                            <th style={{ width: '120px' }}>Due Date</th>
                            <th style={{ width: '100px' }}>Overdue</th>
                            <th style={{ width: '100px' }}>Fine</th>
                            <th className="text-right" style={{ width: '100px' }}>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredItems.length === 0 ? (
                            <tr>
                                <td colSpan="8" className="text-center py-4">
                                    <div className="empty-message">
                                        <CheckCircle size={32} className="text-success" />
                                        <p>No overdue books found for this selection.</p>
                                    </div>
                                </td>
                            </tr>
                        ) : (
                            filteredItems.map((item, index) => (
                                <tr key={index} onClick={() => navigate(`/users/${item.user_id}`)} style={{ cursor: 'pointer' }}>
                                    <td>
                                        <div className="user-info">
                                            <span className="user-name">{item.user_name}</span>
                                        </div>
                                    </td>
                                    <td>
                                        <div style={{ fontSize: '0.85em', color: 'var(--text-secondary)' }}>
                                            {item.department && <div>{item.department}</div>}
                                            {item.year && <div>Year: {item.year}</div>}
                                        </div>
                                    </td>
                                    <td><span className="text-muted text-sm">{item.user_email || '-'}</span></td>
                                    <td>
                                        <div style={{ display: 'flex', flexDirection: 'column' }}>
                                            <span style={{ fontWeight: 500 }}>{item.book_title}</span>
                                            <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>by {item.book_author || '-'}</span>
                                        </div>
                                    </td>
                                    <td>{new Date(item.due_date).toLocaleDateString()}</td>
                                    <td>
                                        <span className="days-badge">
                                            {item.days_overdue} days
                                        </span>
                                    </td>
                                    <td className="text-danger font-bold">₹{item.fine_amount.toFixed(2)}</td>
                                    <td className="text-right">
                                        <button
                                            className="btn-icon"
                                            title="Send Specific Notification"
                                            onClick={(e) => handleNotifyUser(e, item.user_id)}
                                        >
                                            <Mail size={16} />
                                        </button>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};


export default Overdue;
