import { Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { MessagesPage } from './pages/MessagesPage';

export function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Navigate to="/messages" replace />} />
        <Route path="/messages" element={<MessagesPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
