import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Books from './pages/Books';
import Scanner from './pages/Scanner';
import Reservations from './pages/Reservations';
import Overdue from './pages/Overdue';
import Fines from './pages/Fines';
import UserDetails from './pages/UserDetails';

function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />

      {/* Protected Routes */}
      <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/books" element={<Books />} />
        <Route path="/reservations" element={<Reservations />} />
        <Route path="/overdue" element={<Overdue />} />
        <Route path="/fines" element={<Fines />} />
        <Route path="/users/:userId" element={<UserDetails />} />
      </Route>

      {/* Scanner is protected but outside standard layout (fullscreen) */}
      <Route
        path="/scanner"
        element={
          <ProtectedRoute>
            <Scanner />
          </ProtectedRoute>
        }
      />

      {/* Catch all */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}

export default App;
