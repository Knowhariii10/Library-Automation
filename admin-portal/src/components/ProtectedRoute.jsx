import { Navigate } from 'react-router-dom';
import { authService } from '../services/auth';

const ProtectedRoute = ({ children }) => {
    const isAuth = authService.isAuthenticated();
    console.log('ProtectedRoute: Checking auth...', { isAuth });

    if (!isAuth) {
        console.log('ProtectedRoute: Not authenticated, redirecting to login');
        return <Navigate to="/login" replace />;
    }

    console.log('ProtectedRoute: Authenticated, rendering children');

    return children;
};

export default ProtectedRoute;
