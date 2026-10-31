'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import { User, Save, KeyRound } from 'lucide-react';

export default function ProfilePage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [displayName, setDisplayName] = useState('');
  const [oldPassword, setOldPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

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
          setDisplayName(resData.user.displayName || '');
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (newPassword || confirmPassword) {
      if (newPassword !== confirmPassword) {
        setToast({ message: 'Mật khẩu mới và Nhập lại mật khẩu mới không trùng khớp!', type: 'error' });
        return;
      }
      if (!oldPassword) {
        setToast({ message: 'Vui lòng nhập Mật Khẩu Hiện Tại để xác nhận đổi mật khẩu', type: 'error' });
        return;
      }
    }

    setSubmitting(true);

    try {
      const res = await fetch('/api/auth/change-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          displayName: displayName.trim(),
          oldPassword: oldPassword ? oldPassword.trim() : undefined,
          newPassword: newPassword ? newPassword.trim() : undefined,
        }),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Cập nhật thất bại');
      }

      setToast({ message: 'Cập nhật thông tin tài khoản thành công!', type: 'success' });
      setOldPassword('');
      setNewPassword('');
      setConfirmPassword('');
      setUser((prev: any) => ({ ...prev, displayName: json.user.displayName }));
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi hệ thống', type: 'error' });
    } finally {
      setSubmitting(false);
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

        <main className="p-6 md:p-8 space-y-6 flex-1 overflow-y-auto max-w-2xl">
          {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

          <div>
            <h1 className="text-2xl font-bold text-white flex items-center gap-2">
              Thông Tin Tài Khoản
              <User className="w-5 h-5 text-cyan-400" />
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Đổi tên hiển thị cá nhân và cập nhật mật khẩu đăng nhập hệ thống
            </p>
          </div>

          <form onSubmit={handleSubmit} className="glass-card p-6 rounded-2xl space-y-5 text-xs">
            <div>
              <label className="block font-semibold text-slate-300 mb-1">Tên Đăng Nhập</label>
              <input
                type="text"
                value={user.username}
                disabled
                className="w-full p-2.5 bg-slate-900/60 border border-slate-800 rounded-xl text-slate-400 font-mono"
              />
            </div>

            <div>
              <label className="block font-semibold text-slate-300 mb-1">Quyền Hạn (Role)</label>
              <span className="px-3 py-1 rounded-lg bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 font-bold inline-block">
                {user.role === 'ADMIN' ? 'SUPER ADMIN' : 'SALE STAFF'}
              </span>
            </div>

            <div>
              <label className="block font-semibold text-slate-300 mb-1">Tên Hiển Thị (Display Name)</label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                required
              />
            </div>

            <div className="pt-4 border-t border-slate-800 space-y-4">
              <h4 className="font-bold text-slate-200 uppercase tracking-wider flex items-center gap-2 text-cyan-400">
                <KeyRound className="w-4 h-4" /> Đổi Mật Khẩu (Để trống nếu không đổi)
              </h4>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Mật Khẩu Hiện Tại</label>
                <input
                  type="password"
                  value={oldPassword}
                  onChange={(e) => setOldPassword(e.target.value)}
                  className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Mật Khẩu Mới</label>
                <input
                  type="password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                />
              </div>

              <div>
                <label className="block font-semibold text-slate-300 mb-1">Nhập Lại Mật Khẩu Mới</label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full p-2.5 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="py-3 px-6 gradient-button text-white font-bold rounded-xl shadow-lg flex items-center gap-2 text-xs"
            >
              <Save className="w-4 h-4" />
              LƯU THAY ĐỔI
            </button>
          </form>
        </main>
      </div>
    </div>
  );
}
