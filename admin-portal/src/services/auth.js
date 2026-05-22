import api from './api';

export const authService = {
    // Login
    async login(email, password) {
        const response = await api.post('/auth/admin/login', { email, password });
        if (response.data.success) {
            localStorage.setItem('token', response.data.token);
            localStorage.setItem('admin', JSON.stringify(response.data.admin));
        }
        return response.data;
    },

    // Logout
    async logout() {
        try {
            await api.post('/auth/admin/logout');
        } catch (error) {
            console.error('Logout error:', error);
        } finally {
            localStorage.removeItem('token');
            localStorage.removeItem('admin');
        }
    },

    // Validate token
    async validate() {
        const response = await api.get('/auth/admin/validate');
        return response.data;
    },

    // Check if user is authenticated
    isAuthenticated() {
        return !!localStorage.getItem('token');
    },

    // Get current admin
    getCurrentAdmin() {
        const admin = localStorage.getItem('admin');
        return admin ? JSON.parse(admin) : null;
    },

    getCurrentUser() {
        return this.getCurrentAdmin();
    }
};

export default authService;
