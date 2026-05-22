import { NavLink } from 'react-router-dom';
import {
    LayoutDashboard,
    BookOpen,
    ScanLine,
    Calendar,
    AlertCircle,
    DollarSign
} from 'lucide-react';
import './Navbar.css';

const Navbar = () => {
    const navItems = [
        { path: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
        { path: '/books', icon: BookOpen, label: 'Books' },
        { path: '/scanner', icon: ScanLine, label: 'Scanner' },
        { path: '/reservations', icon: Calendar, label: 'Reservations' },
        { path: '/overdue', icon: AlertCircle, label: 'Overdue' },
        { path: '/fines', icon: DollarSign, label: 'Fines' }
    ];

    return (
        <nav className="navbar">
            <div className="navbar-header">
                <BookOpen size={32} className="navbar-logo" />
                <h2>Library Admin</h2>
            </div>

            <ul className="navbar-menu">
                {navItems.map((item) => {
                    const Icon = item.icon;
                    return (
                        <li key={item.path}>
                            <NavLink
                                to={item.path}
                                className={({ isActive }) =>
                                    `navbar-link ${isActive ? 'active' : ''}`
                                }
                            >
                                <Icon size={20} />
                                <span>{item.label}</span>
                            </NavLink>
                        </li>
                    );
                })}
            </ul>
        </nav>
    );
};

export default Navbar;
