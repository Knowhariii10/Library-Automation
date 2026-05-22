import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { BookOpen, Users, AlertCircle, Calendar, TrendingUp, UserCheck, X, Search } from 'lucide-react';
import api from '../services/api';
import './Dashboard.css';

const Dashboard = () => {
    const navigate = useNavigate();
    const [stats, setStats] = useState({
        total_books: 0,
        rented_books: 0,
        overdue_books: 0,
        active_reservations: 0,
        today_attendance: 0,
        total_users: 0
    });
    const [loading, setLoading] = useState(true);
    const [attendanceHistory, setAttendanceHistory] = useState([]);
    const [selectedDay, setSelectedDay] = useState(null);
    const [dayDetails, setDayDetails] = useState(null);
    const [loadingDetails, setLoadingDetails] = useState(false);
    const [modalSearchTerm, setModalSearchTerm] = useState('');

    // User Directory State
    const [isUserModalOpen, setIsUserModalOpen] = useState(false);
    const [usersList, setUsersList] = useState([]);
    const [loadingUsers, setLoadingUsers] = useState(false);
    const [userSearchTerm, setUserSearchTerm] = useState('');

    // Rental Modal State
    const [isRentalModalOpen, setIsRentalModalOpen] = useState(false);
    const [rentalDetails, setRentalDetails] = useState([]);
    const [loadingRentals, setLoadingRentals] = useState(false);
    const [rentalSearchTerm, setRentalSearchTerm] = useState('');

    useEffect(() => {
        fetchStats();
        fetchAttendanceHistory();
    }, []);

    const fetchStats = async () => {
        try {
            const response = await api.get('/admin/dashboard/stats');
            if (response.data.success) {
                setStats(response.data.stats);
            }
        } catch (error) {
            console.error('Error fetching stats:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchAttendanceHistory = async () => {
        try {
            const response = await api.get('/admin/attendance/history');
            if (response.data.success) {
                setAttendanceHistory(response.data.history);
            }
        } catch (error) {
            console.error('Error fetching attendance history:', error);
        }
    };

    const fetchDayDetails = async (date) => {
        setLoadingDetails(true);
        try {
            const response = await api.get(`/admin/attendance/details?date=${date}`);
            if (response.data.success) {
                setDayDetails(response.data.details);
            }
        } catch (error) {
            console.error('Error fetching day details:', error);
        } finally {
            setLoadingDetails(false);
        }
    };

    const fetchUsers = async () => {
        setLoadingUsers(true);
        try {
            const response = await api.get('/admin/users');
            if (response.data.success) {
                setUsersList(response.data.users);
            }
        } catch (error) {
            console.error('Error fetching users:', error);
        } finally {
            setLoadingUsers(false);
        }
    };

    const fetchRentalDetails = async () => {
        setLoadingRentals(true);
        try {
            const response = await api.get('/admin/rental/details?active_only=true');
            if (response.data.success) {
                setRentalDetails(response.data.rentals);
            }
        } catch (error) {
            console.error('Error fetching rental details:', error);
        } finally {
            setLoadingRentals(false);
        }
    };

    const handleBarClick = (day) => {
        setSelectedDay(day);
        fetchDayDetails(day.date);
    };

    const handleUserStatClick = () => {
        setIsUserModalOpen(true);
        fetchUsers();
    };

    const handleRentalClick = () => {
        setIsRentalModalOpen(true);
        fetchRentalDetails();
    };

    const closeModal = () => {
        setSelectedDay(null);
        setDayDetails(null);
        setModalSearchTerm('');

        setIsUserModalOpen(false);
        setUserSearchTerm('');

        setIsRentalModalOpen(false);
        setRentalDetails([]);
        setRentalSearchTerm('');
    };

    const statCards = [
        {
            title: 'Total Books',
            value: stats.total_books,
            icon: BookOpen,
            color: 'primary',
            trend: '+12%',
            path: '/books'
        },
        {
            title: 'Currently Rented',
            value: stats.rented_books + stats.overdue_books,
            icon: TrendingUp,
            color: 'info',
            trend: '+5%',
            path: '/books'
        },
        {
            title: 'Overdue Books',
            value: stats.overdue_books,
            icon: AlertCircle,
            color: 'danger',
            trend: '-3%',
            path: '/overdue'
        },
        {
            title: 'Active Reservations',
            value: stats.active_reservations,
            icon: Calendar,
            color: 'warning',
            trend: '+8%',
            path: '/reservations'
        },
        {
            title: "Today's Attendance",
            value: stats.today_attendance,
            icon: Users,
            color: 'success',
            trend: '+15%',
            path: '/scanner'
        },
        {
            title: 'User Details',
            value: stats.total_users,
            icon: UserCheck,
            color: 'primary',
            trend: '+10%',
            path: '/users'
        }
    ];

    // Calculate overdue percentage for pie chart
    const totalRentedAndOverdue = stats.rented_books + stats.overdue_books;
    const overduePercentage = totalRentedAndOverdue > 0
        ? Math.round((stats.overdue_books / totalRentedAndOverdue) * 100)
        : 0;

    if (loading) {
        return (
            <div className="dashboard-loading">
                <div className="spinner"></div>
                <p>Loading dashboard...</p>
            </div>
        );
    }

    return (
        <div className="dashboard">
            <div className="dashboard-header">
                <h1>Dashboard</h1>
                <p>Monitor library activity and manage resources from a central hub.</p>
            </div>

            <div className="stats-grid">
                {statCards.map((stat, index) => {
                    const Icon = stat.icon;
                    return (
                        <div
                            key={index}
                            className={`stat-card card fade-in`}
                            style={{ animationDelay: `${index * 0.1}s` }}
                            onClick={() => {
                                if (stat.title === 'User Details') {
                                    handleUserStatClick();
                                } else if (stat.title === 'Currently Rented') {
                                    handleRentalClick();
                                } else if (stat.title === "Today's Attendance") {
                                    const today = new Date().toISOString().split('T')[0];
                                    handleBarClick({ date: today, label: 'Today' });
                                } else {
                                    navigate(stat.path);
                                }
                            }}
                        >
                            <div className="stat-header">
                                <div className={`stat-icon stat-icon-${stat.color}`}>
                                    <Icon size={20} />
                                </div>
                                <span className={`stat-trend ${stat.trend.startsWith('+') ? 'trend-up' : 'trend-down'}`}>
                                    {stat.trend}
                                </span>
                            </div>

                            <div className="stat-content">
                                <p className="stat-title text-muted">{stat.title}</p>
                                <h3 className="stat-value">{stat.value}</h3>
                            </div>
                        </div>
                    );
                })}
            </div>

            {/* Charts Row */}
            <div className="charts-row">
                {/* Overdue Analytics Section */}
                <div className="overdue-analytics card fade-in" style={{ animationDelay: '0.5s' }}>
                    <h3>Overdue Analytics</h3>
                    <div className="analytics-content">
                        <div className="pie-chart-container">
                            <svg viewBox="0 0 100 100" className="pie-chart">
                                <circle
                                    cx="50"
                                    cy="50"
                                    r="40"
                                    fill="none"
                                    stroke="var(--success)"
                                    strokeWidth="20"
                                    className="pie-segment"
                                />
                                <circle
                                    cx="50"
                                    cy="50"
                                    r="40"
                                    fill="none"
                                    stroke="var(--danger)"
                                    strokeWidth="20"
                                    strokeDasharray={`${overduePercentage * 2.51} 251`}
                                    strokeDashoffset="0"
                                    transform="rotate(-90 50 50)"
                                    className="pie-segment"
                                />
                                <text x="50" y="44" textAnchor="middle" className="pie-percentage">
                                    {overduePercentage}%
                                </text>
                                <text x="50" y="56" textAnchor="middle" className="pie-label">
                                    OVERDUE
                                </text>
                            </svg>
                        </div>
                        <div className="analytics-legend">
                            <div className="legend-item">
                                <span className="legend-dot legend-dot-danger"></span>
                                <span className="legend-text">Overdue ({stats.overdue_books} books)</span>
                            </div>
                            <div className="legend-item">
                                <span className="legend-dot legend-dot-success"></span>
                                <span className="legend-text">On Time ({stats.rented_books} books)</span>
                            </div>
                            <div className="legend-summary">
                                <p>Total Active Rentals: <strong>{totalRentedAndOverdue}</strong></p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Attendance History Bar Chart */}
                <div className="attendance-chart card fade-in" style={{ animationDelay: '0.6s' }}>
                    <h3>Attendance - Last 10 Days</h3>
                    <div className="bar-chart-container">
                        {attendanceHistory.length > 0 ? (
                            <div className="bar-chart">
                                {attendanceHistory.map((day, index) => {
                                    const maxCount = Math.max(...attendanceHistory.map(d => d.count), 1);
                                    const heightPercent = (day.count / maxCount) * 100;
                                    return (
                                        <div
                                            key={index}
                                            className="bar-item"
                                            onClick={() => handleBarClick(day)}
                                        >
                                            <div className="bar-wrapper">
                                                <span className="bar-value">{day.count}</span>
                                                <div
                                                    className={`bar ${day.count === 0 ? 'bar-zero' : ''}`}
                                                    style={{ height: day.count === 0 ? '4px' : `${heightPercent}%` }}
                                                ></div>
                                            </div>
                                            <span className="bar-label">{day.label.replace(' ', '\n')}</span>
                                        </div>
                                    );
                                })}
                            </div>
                        ) : (
                            <p className="no-data">No attendance data available</p>
                        )}
                    </div>
                </div>
            </div>

            {/* Attendance Details Modal */}
            {selectedDay && (
                <div className="modal-overlay full-view" onClick={closeModal}>
                    <div className="user-directory-modal" onClick={(e) => e.stopPropagation()}>
                        <div className="directory-header">
                            <div className="header-content">
                                <div className="title-group">
                                    <Users className="header-icon" />
                                    <div>
                                        <h2>Attendance Details</h2>
                                        <p>{selectedDay.label}</p>
                                    </div>
                                </div>
                                <div className="directory-controls">
                                    <div className="search-wrapper modern">
                                        <Search size={18} />
                                        <input
                                            type="text"
                                            placeholder="Search student..."
                                            value={modalSearchTerm}
                                            onChange={(e) => setModalSearchTerm(e.target.value)}
                                        />
                                    </div>
                                    <button className="close-btn-round" onClick={closeModal}>
                                        <X size={20} />
                                    </button>
                                </div>
                            </div>

                            <div className="directory-stats">
                                <div className="quick-stat">
                                    <span className="stat-label">Total Entries</span>
                                    <span className="stat-value">{dayDetails?.length || 0}</span>
                                </div>
                            </div>
                        </div>

                        <div className="directory-body">
                            {loadingDetails ? (
                                <div className="loading-state">
                                    <div className="spinner-modern"></div>
                                    <p>Loading attendance details...</p>
                                </div>
                            ) : dayDetails ? (
                                <div className="user-table-wrapper">
                                    <table className="modern-directory-table">
                                        <thead>
                                            <tr>
                                                <th>Student Name</th>
                                                <th>Year</th>
                                                <th>Dept</th>
                                                <th>In Time</th>
                                                <th>Out Time</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {dayDetails
                                                .filter(u => u.user_name?.toLowerCase().includes(modalSearchTerm.toLowerCase()))
                                                .map((user, idx) => (
                                                    <tr key={idx}>
                                                        <td className="user-info-cell">
                                                            <div className="avatar-mini">
                                                                {user.user_name?.charAt(0)}
                                                            </div>
                                                            <span
                                                                className="clickable-name"
                                                                onClick={() => !user.is_guest && navigate(`/users/${user.user_id}`)}
                                                            >
                                                                {user.user_name} {user.is_guest && <span className="text-secondary">(Guest)</span>}
                                                            </span>
                                                        </td>
                                                        <td>{user.year}</td>
                                                        <td>{user.department}</td>
                                                        <td>
                                                            {user.in_time ? new Date(user.in_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '---'}
                                                        </td>
                                                        <td>
                                                            {user.out_time ? new Date(user.out_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '---'}
                                                        </td>
                                                        <td>
                                                            {user.is_active ? (
                                                                <span className="badge-active">Still Active</span>
                                                            ) : (
                                                                <span className="badge-out">Out</span>
                                                            )}
                                                        </td>
                                                    </tr>
                                                ))}
                                        </tbody>
                                    </table>
                                </div>
                            ) : (
                                <div className="no-contents">
                                    <p>No data available for this day</p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {/* Rental Details Modal */}
            {
                isRentalModalOpen && (
                    <div className="modal-overlay full-view" onClick={closeModal}>
                        <div className="user-directory-modal" onClick={(e) => e.stopPropagation()}>
                            <div className="directory-header">
                                <div className="header-content">
                                    <div className="title-group">
                                        <BookOpen className="header-icon" />
                                        <div>
                                            <h2>Active Rentals</h2>
                                            <p>Currently rented books and their status</p>
                                        </div>
                                    </div>
                                    <div className="directory-controls">
                                        <div className="search-wrapper modern">
                                            <Search size={18} />
                                            <input
                                                type="text"
                                                placeholder="Search by book, renter, or ID..."
                                                value={rentalSearchTerm}
                                                onChange={(e) => setRentalSearchTerm(e.target.value)}
                                            />
                                        </div>
                                        <button className="close-btn-round" onClick={closeModal}>
                                            <X size={20} />
                                        </button>
                                    </div>
                                </div>

                                <div className="directory-stats">
                                    <div className="quick-stat">
                                        <span className="stat-label">Active Rentals</span>
                                        <span className="stat-value">{rentalDetails.length}</span>
                                    </div>
                                    <div className="quick-stat">
                                        <span className="stat-label">Overdue</span>
                                        <span className="stat-value">
                                            {rentalDetails.filter(r => r.status === 'OVERDUE').length}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <div className="directory-body">
                                {loadingRentals ? (
                                    <div className="loading-state">
                                        <div className="spinner-modern"></div>
                                        <p>Loading rental details...</p>
                                    </div>
                                ) : (
                                    <div className="user-table-wrapper">
                                        <table className="modern-directory-table">
                                            <thead>
                                                <tr>
                                                    <th>Book Name</th>
                                                    <th>Student Name</th>
                                                    <th>Student ID</th>
                                                    <th>Rented On</th>
                                                    <th>Due Date</th>
                                                    <th>Status</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {rentalDetails
                                                    .filter(r =>
                                                        r.book_title?.toLowerCase().includes(rentalSearchTerm.toLowerCase()) ||
                                                        r.renter_name?.toLowerCase().includes(rentalSearchTerm.toLowerCase()) ||
                                                        r.renter_id?.toLowerCase().includes(rentalSearchTerm.toLowerCase())
                                                    )
                                                    .map((rental, idx) => (
                                                        <tr key={rental.rental_id || idx}>
                                                            <td className="book-info-cell">
                                                                <div className="book-info-wrapper">
                                                                    <div className="book-cover-mini">
                                                                        {rental.book_id ? (
                                                                            <img
                                                                                src={`http://10.42.99.143:5001/books_img/${rental.book_id}.jpg`}
                                                                                alt="cover"
                                                                                onError={(e) => {
                                                                                    e.target.style.display = 'none';
                                                                                    e.target.parentElement.innerHTML = `<div class="placeholder-cover">${rental.book_title?.charAt(0)}</div>`;
                                                                                }}
                                                                            />
                                                                        ) : (
                                                                            <div className="placeholder-cover">{rental.book_title?.charAt(0)}</div>
                                                                        )}
                                                                    </div>
                                                                    <div className="book-details-text">
                                                                        <span className="font-medium book-title-link" title={rental.book_title}>
                                                                            {rental.book_title}
                                                                        </span>
                                                                        <span className="text-small text-muted">{rental.book_author}</span>
                                                                    </div>
                                                                </div>
                                                            </td>
                                                            <td>
                                                                <span
                                                                    className="clickable-name"
                                                                    onClick={() => navigate(`/users/${rental.user_id}`)}
                                                                >
                                                                    {rental.renter_name}
                                                                </span>
                                                            </td>
                                                            <td className="text-muted font-medium">
                                                                {rental.renter_id}
                                                            </td>
                                                            <td>
                                                                {new Date(rental.rented_at).toLocaleDateString()}
                                                                <span className="text-small text-muted block">
                                                                    {new Date(rental.rented_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                                </span>
                                                            </td>
                                                            <td>{new Date(rental.due_date).toLocaleDateString()}</td>
                                                            <td>
                                                                {rental.status === 'OVERDUE' ? (
                                                                    <span className="badge-error">Overdue ({rental.days_overdue} days)</span>
                                                                ) : (
                                                                    <span className="badge-active">Active</span>
                                                                )}
                                                            </td>
                                                        </tr>
                                                    ))}
                                            </tbody>
                                        </table>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                )
            }

            {/* User Directory Modal */}
            {
                isUserModalOpen && (
                    <div className="modal-overlay full-view" onClick={closeModal}>
                        <div className="user-directory-modal" onClick={(e) => e.stopPropagation()}>
                            <div className="directory-header">
                                <div className="header-content">
                                    <div className="title-group">
                                        <Users className="header-icon" />
                                        <div>
                                            <h2>Member Directory</h2>
                                            <p>Manage and explore all library users in one place</p>
                                        </div>
                                    </div>
                                    <div className="directory-controls">
                                        <div className="search-wrapper modern">
                                            <Search size={18} />
                                            <input
                                                type="text"
                                                placeholder="Search by name, student ID, or department..."
                                                value={userSearchTerm}
                                                onChange={(e) => setUserSearchTerm(e.target.value)}
                                            />
                                        </div>
                                        <button className="close-btn-round" onClick={closeModal}>
                                            <X size={20} />
                                        </button>
                                    </div>
                                </div>

                                <div className="directory-stats">
                                    <div className="quick-stat">
                                        <span className="stat-label">Total Users</span>
                                        <span className="stat-value">{usersList.length}</span>
                                    </div>
                                </div>
                            </div>

                            <div className="directory-body">
                                {loadingUsers ? (
                                    <div className="loading-state">
                                        <div className="spinner-modern"></div>
                                        <p>Loading member directory...</p>
                                    </div>
                                ) : (
                                    <div className="user-table-wrapper">
                                        <table className="modern-directory-table">
                                            <thead>
                                                <tr>
                                                    <th>Member Name</th>
                                                    <th>Student ID</th>
                                                    <th>Email Address</th>
                                                    <th>Department</th>
                                                    <th>Year</th>
                                                    <th>Contact</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                {usersList
                                                    .filter(u =>
                                                        u.name?.toLowerCase().includes(userSearchTerm.toLowerCase()) ||
                                                        u.student_id?.toLowerCase().includes(userSearchTerm.toLowerCase()) ||
                                                        u.department?.toLowerCase().includes(userSearchTerm.toLowerCase())
                                                    )
                                                    .map((user, idx) => (
                                                        <tr key={user.id || idx}>
                                                            <td className="user-info-cell">
                                                                <div className="user-info-wrapper">
                                                                    <div className="avatar-mini">
                                                                        {user.name?.charAt(0)}
                                                                    </div>
                                                                    <span
                                                                        className="clickable-name"
                                                                        onClick={() => navigate(`/users/${user.id}`)}
                                                                    >
                                                                        {user.name}
                                                                    </span>
                                                                </div>
                                                            </td>
                                                            <td className="id-cell">{user.student_id}</td>
                                                            <td className="text-muted email-cell">{user.email || '--'}</td>
                                                            <td>{user.department}</td>
                                                            <td>{user.year} yr</td>
                                                            <td className="text-muted">{user.phone || '--'}</td>
                                                        </tr>
                                                    ))}
                                            </tbody>
                                        </table>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                )
            }
        </div >
    );
};

export default Dashboard;
