import { Outlet, useNavigate } from 'react-router-dom';
import { LogOut, User } from 'lucide-react';
import Navbar from './Navbar';
import authService from '../services/auth';
import './Layout.css';

const Layout = () => {
    const navigate = useNavigate();
    const admin = authService.getCurrentUser();

    const handleLogout = () => {
        authService.logout();
        navigate('/login');
    };

    if (!authService.isAuthenticated()) {
        navigate('/login');
        return null;
    }

    return (
        <div className="layout">
            <Navbar />
            <div className="layout-main">
                <header className="layout-header glass">
                    <div className="header-content">
                        <div className="header-admin">
                            <div className="admin-avatar">
                                <User size={18} />
                            </div>
                            <div className="admin-info">
                                <span className="admin-name">Super Admin</span>
                                <span className="admin-role">Library Operations</span>
                            </div>
                        </div>

                        <button className="logout-btn" onClick={handleLogout}>
                            <LogOut size={16} />
                            <span>Sign Out</span>
                        </button>
                    </div>
                </header>

                <main className="layout-content">
                    <div className="content-container">
                        <Outlet />
                    </div>
                </main>
            </div>
        </div>
    );
};

export default Layout;
