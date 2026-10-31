'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import { Send, Plus, Edit2, Trash2, X, ShieldCheck } from 'lucide-react';

export default function TelegramsPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [telegrams, setTelegrams] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Modal state
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [username, setUsername] = useState('');
  const [name, setName] = useState('');
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
          setUser(resData.user);
          loadTelegrams();
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const loadTelegrams = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/telegrams');
      if (res.ok) {
        const json = await res.json();
        setTelegrams(json.telegrams || []);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (contact?: any) => {
    if (contact) {
      setEditingId(contact.id);
      setUsername(contact.username);
      setName(contact.name);
    } else {
      setEditingId(null);
      setUsername('@');
      setName('');
    }
    setShowModal(true);
  };

  const handleSaveContact = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    try {
      const payload = {
        username: username.trim(),
        name: name.trim(),
      };

      const url = editingId ? `/api/telegrams/${editingId}` : '/api/telegrams';
      const method = editingId ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Lỗi khi lưu Telegram Contact');
      }

      setToast({ message: 'Lưu thông tin Telegram CSKH thành công!', type: 'success' });
      setShowModal(false);
      loadTelegrams();
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi hệ thống', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteContact = async (id: string, uname: string) => {
    if (!confirm(`Bạn có chắc muốn xóa Telegram CSKH [${uname}]?`)) return;

    try {
      const res = await fetch(`/api/telegrams/${id}`, { method: 'DELETE' });
      const json = await res.json();
      if (!res.ok) {
        setToast({ message: json.error || 'Không thể xóa', type: 'error' });
        return;
      }
      setToast({ message: 'Đã xóa Telegram Contact', type: 'success' });
      loadTelegrams();
    } catch (e: any) {
      setToast({ message: e.message || 'Lỗi khi xóa', type: 'error' });
    }
  };

  if (!user) {
    return (
      <div className="min-h-screen bg-[#0b0f19] flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-cyan-500/20 border-t-cyan-500 rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-[#0b0f19]">
      <Sidebar userRole={user.role} />

      <div className="flex-1 flex flex-col min-w-0">
        <Navbar user={user} />

        <main className="p-6 md:p-8 space-y-6 flex-1 overflow-y-auto">
          {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                Quản Lý Telegram CSKH / Admin
                <Send className="w-5 h-5 text-cyan-400" />
              </h1>
              <p className="text-xs text-slate-400 mt-1">
                Danh sách tài khoản Telegram hỗ trợ. Khi tạo token cho khách sẽ chọn tối đa 2 tài khoản trong danh sách này
              </p>
            </div>

            {user.role === 'ADMIN' && (
              <button
                onClick={() => handleOpenModal()}
                className="px-5 py-2.5 gradient-button text-white text-sm font-semibold rounded-xl shadow-lg shadow-cyan-500/20 flex items-center gap-2 self-start sm:self-auto hover:scale-105 transition"
              >
                <Plus className="w-4 h-4" />
                THÊM TELEGRAM MỚI
              </button>
            )}
          </div>

          {/* Table */}
          <div className="glass-card p-6 rounded-2xl">
            {loading ? (
              <div className="py-12 text-center text-slate-400 text-xs">Đang tải danh sách Telegram...</div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs text-slate-300">
                  <thead className="bg-slate-900/80 uppercase text-slate-400 border-b border-slate-800 text-[11px]">
                    <tr>
                      <th className="py-3.5 px-4">Tên Mô Tả / Admin</th>
                      <th className="py-3.5 px-4">Username Telegram</th>
                      <th className="py-3.5 px-4">Trạng Thái</th>
                      <th className="py-3.5 px-4">Ngày Tạo</th>
                      <th className="py-3.5 px-4 text-right">Thao Tác</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {telegrams.map((contact) => (
                      <tr key={contact.id} className="hover:bg-slate-800/30 transition">
                        <td className="py-3.5 px-4 font-bold text-slate-100 flex items-center gap-2">
                          <Send className="w-4 h-4 text-cyan-400" />
                          {contact.name}
                        </td>
                        <td className="py-3.5 px-4 font-mono font-bold text-cyan-300">
                          {contact.username}
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                            ĐANG HOẠT ĐỘNG
                          </span>
                        </td>
                        <td className="py-3.5 px-4 text-slate-400">
                          {new Date(contact.createdAt).toLocaleDateString('vi-VN')}
                        </td>
                        <td className="py-3.5 px-4 text-right space-x-1">
                          {user.role === 'ADMIN' && (
                            <>
                              <button
                                onClick={() => handleOpenModal(contact)}
                                className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg transition"
                                title="Sửa Telegram"
                              >
                                <Edit2 className="w-3.5 h-3.5" />
                              </button>
                              <button
                                onClick={() => handleDeleteContact(contact.id, contact.username)}
                                className="p-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 rounded-lg transition"
                                title="Xóa Telegram"
                              >
                                <Trash2 className="w-3.5 h-3.5" />
                              </button>
                            </>
                          )}
                        </td>
                      </tr>
                    ))}

                    {telegrams.length === 0 && (
                      <tr>
                        <td colSpan={5} className="py-8 text-center text-slate-500 italic">
                          Chưa có tài khoản Telegram nào trong danh sách
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Modal Add/Edit */}
          {showModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm">
              <div className="glass-card w-full max-w-md p-6 rounded-2xl space-y-4 border border-slate-800 relative">
                <button
                  onClick={() => setShowModal(false)}
                  className="absolute top-4 right-4 p-1 text-slate-400 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>

                <h3 className="font-bold text-slate-100 text-base">
                  {editingId ? 'Cập Nhật Telegram CSKH' : 'Thêm Telegram CSKH Mới'}
                </h3>

                <form onSubmit={handleSaveContact} className="space-y-4 text-xs">
                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Username Telegram</label>
                    <input
                      type="text"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      placeholder="@xoajxanh"
                      className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-cyan-300 font-mono"
                      required
                    />
                  </div>

                  <div>
                    <label className="block font-semibold text-slate-300 mb-1">Tên Mô Tả / Admin Hiển Thị</label>
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="Admin Xoài CSKH"
                      className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                      required
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={submitting}
                    className="w-full py-3 gradient-button text-white font-bold rounded-xl shadow-lg text-xs mt-2"
                  >
                    {submitting ? 'Đang lưu...' : 'LƯU TELEGRAM CONTACT'}
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
