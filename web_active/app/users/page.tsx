'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import { Users, UserPlus, ShieldCheck, KeyRound, Trash2, Edit3, X } from 'lucide-react';

export default function UsersPage() {
  const router = useRouter();
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [usersList, setUsersList] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Modal State
  const [showModal, setShowModal] = useState(false);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [role, setRole] = useState<'ADMIN' | 'SALE'>('SALE');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    fetch('/api/auth/me')
      .then((res) => {
        if (!res.ok) {
          router.push('/login');
          return null;
        }
        return res.json();
      })
      .then((resData) => {
        if (resData?.user) {
          if (resData.user.role !== 'ADMIN') {
            router.push('/dashboard');
            return;
          }
          setCurrentUser(resData.user);
          loadUsers();
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const loadUsers = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/users');
      if (res.ok) {
        const json = await res.json();
        setUsersList(json.users || []);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!username || !password || !displayName) {
      setToast({ message: 'Vui lòng nhập đầy đủ thông tin', type: 'error' });
      return;
    }

    setSubmitting(true);
    try {
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password, displayName, role }),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Lỗi khi tạo người dùng');
      }

      setToast({ message: 'Tạo tài khoản nhân viên thành công!', type: 'success' });
      setShowModal(false);
      setUsername('');
      setPassword('');
      setDisplayName('');
      loadUsers();
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi hệ thống', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteUser = async (id: string, name: string) => {
    if (!confirm(`Bạn có chắc muốn xóa tài khoản [${name}]?`)) return;

    try {
      const res = await fetch(`/api/users/${id}`, { method: 'DELETE' });
      const json = await res.json();
      if (!res.ok) {
        setToast({ message: json.error || 'Không thể xóa', type: 'error' });
        return;
      }
      setToast({ message: 'Đã xóa tài khoản thành công', type: 'success' });
      loadUsers();
    } catch (e: any) {
      setToast({ message: e.message || 'Có lỗi xảy ra', type: 'error' });
    }
  };

  if (!currentUser) {
    return (
      <div className="min-h-screen bg-[#0b0f19] flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-cyan-500/20 border-t-cyan-500 rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-[#0b0f19]">
      <Sidebar userRole={currentUser.role} />

      <div className="flex-1 flex flex-col min-w-0">
        <Navbar user={currentUser} />

        <main className="p-6 md:p-8 space-y-6 flex-1 overflow-y-auto">
          {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                Quản Lý Tài Khoản Nhân Viên
                <Users className="w-5 h-5 text-cyan-400" />
              </h1>
              <p className="text-xs text-slate-400 mt-1">
                Phân quyền tài khoản Admin Siêu Cấp và Nhân viên CSKH (Sale)
              </p>
            </div>

            <button
              onClick={() => setShowModal(true)}
              className="px-5 py-2.5 gradient-button text-white text-sm font-semibold rounded-xl shadow-lg shadow-cyan-500/20 flex items-center gap-2 self-start sm:self-auto hover:scale-105 transition"
            >
              <UserPlus className="w-4 h-4" />
              TẠO TÀI KHOẢN MỚI
            </button>
          </div>

          {/* Table */}
          <div className="glass-card p-6 rounded-2xl">
            {loading ? (
              <div className="py-12 text-center text-slate-400 text-xs">Đang tải tài khoản...</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-300">
                  <thead className="bg-slate-900/80 uppercase text-slate-400 border-b border-slate-800 text-[11px]">
                    <tr>
                      <th className="py-3.5 px-4">Tên Hiển Thị</th>
                      <th className="py-3.5 px-4">Tên Đăng Nhập</th>
                      <th className="py-3.5 px-4">Quyền Hạn (Role)</th>
                      <th className="py-3.5 px-4">Số Token Đã Tạo</th>
                      <th className="py-3.5 px-4">Ngày Tạo</th>
                      <th className="py-3.5 px-4 text-right">Thao Tác</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {usersList.map((u) => (
                      <tr key={u.id} className="hover:bg-slate-800/30 transition">
                        <td className="py-3.5 px-4 font-bold text-slate-100 flex items-center gap-2">
                          <div className="w-7 h-7 rounded-full bg-slate-800 flex items-center justify-center text-cyan-400 font-bold text-xs">
                            {u.displayName.charAt(0).toUpperCase()}
                          </div>
                          {u.displayName}
                        </td>
                        <td className="py-3.5 px-4 font-mono text-cyan-300 font-semibold">@{u.username}</td>
                        <td className="py-3.5 px-4">
                          <span
                            className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
                              u.role === 'ADMIN'
                                ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                                : 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20'
                            }`}
                          >
                            {u.role === 'ADMIN' ? 'SUPER ADMIN' : 'SALE STAFF'}
                          </span>
                        </td>
                        <td className="py-3.5 px-4 font-semibold text-indigo-300">{u._count?.tokens || 0} tokens</td>
                        <td className="py-3.5 px-4 text-slate-400">
                          {new Date(u.createdAt).toLocaleDateString('vi-VN')}
                        </td>
                        <td className="py-3.5 px-4 text-right">
                          {u.id !== currentUser.userId && (
                            <button
                              onClick={() => handleDeleteUser(u.id, u.displayName)}
                              className="p-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 rounded-lg transition"
                              title="Xóa tài khoản"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Modal Create User */}
          {showModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
              <div className="glass-card w-full max-w-md p-6 rounded-2xl space-y-4 border border-slate-800 relative">
                <button
                  onClick={() => setShowModal(false)}
                  className="absolute top-4 right-4 p-1 text-slate-400 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>

                <h3 className="font-bold text-slate-100 text-base flex items-center gap-2">
                  <UserPlus className="w-5 h-5 text-cyan-400" /> Tạo Tài Khoản Nhân Viên Mới
                </h3>

                <form onSubmit={handleCreateUser} className="space-y-4 text-xs">
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Tên Đăng Nhập</label>
                    <input
                      type="text"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      placeholder="sale2"
                      className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                      required
                    />
                  </div>

                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Tên Hiển Thị (Display Name)</label>
                    <input
                      type="text"
                      value={displayName}
                      onChange={(e) => setDisplayName(e.target.value)}
                      placeholder="Nhân viên CSKH 02"
                      className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                      required
                    />
                  </div>

                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Mật Khẩu</label>
                    <input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                      required
                    />
                  </div>

                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Quyền Hạn (Role)</label>
                    <select
                      value={role}
                      onChange={(e) => setRole(e.target.value as 'ADMIN' | 'SALE')}
                      className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100 font-semibold"
                    >
                      <option value="SALE">SALE (Tạo/Sửa token, Không xóa token)</option>
                      <option value="ADMIN">ADMIN (Toàn quyền quản trị)</option>
                    </select>
                  </div>

                  <button
                    type="submit"
                    disabled={submitting}
                    className="w-full py-3 gradient-button text-white font-bold rounded-xl shadow-lg text-xs mt-2"
                  >
                    {submitting ? 'Đang tạo...' : 'TẠO TÀI KHOẢN'}
                  </button>
                </form>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
