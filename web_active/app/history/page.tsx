'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import Link from 'next/link';
import {
  History,
  Search,
  Copy,
  Users,
  Crown,
  ChevronLeft,
  ChevronRight,
  ExternalLink,
  CheckCircle2,
  AlertTriangle,
  Clock,
  Smartphone,
  Server,
  User,
  ShieldAlert,
} from 'lucide-react';

export default function HistoryPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [devices, setDevices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'CUSTOMER' | 'SVIP'>('CUSTOMER');
  const [search, setSearch] = useState('');
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Pagination
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(20);
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0, totalPages: 1 });

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
  };

  useEffect(() => {
    fetch('/api/auth/me')
      .then((res) => {
        if (!res.ok) {
          router.push('/login');
          return null;
        }
        return res.json();
      })
      .then((data) => {
        if (data?.user) {
          setUser(data.user);
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const loadHistory = async (tab = activeTab, p = page, s = search) => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        type: tab,
        page: p.toString(),
        limit: limit.toString(),
        search: s,
      });

      const res = await fetch(`/api/history?${params.toString()}`);
      if (res.ok) {
        const json = await res.json();
        setDevices(json.devices || []);
        if (json.pagination) setPagination(json.pagination);
      } else {
        showToast('Không thể tải lịch sử đăng nhập', 'error');
      }
    } catch {
      showToast('Lỗi mạng khi tải lịch sử', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      loadHistory(activeTab, page, search);
    }
  }, [user, activeTab, page, limit]);

  const handleTabChange = (tab: 'CUSTOMER' | 'SVIP') => {
    setActiveTab(tab);
    setPage(1);
    loadHistory(tab, 1, search);
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    loadHistory(activeTab, 1, search);
  };

  const copyToClipboard = (text: string, label: string = 'Đã sao chép') => {
    navigator.clipboard.writeText(text);
    showToast(label, 'success');
  };

  // Format relative time: "x phút trước", "x giờ trước"...
  const formatRelativeTime = (dateStr: string) => {
    if (!dateStr) return 'N/A';
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHours = Math.floor(diffMin / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffSec < 60) return 'Vừa xong';
    if (diffMin < 60) return `${diffMin} phút trước`;
    if (diffHours < 24) return `${diffHours} giờ ${diffMin % 60}p trước`;
    if (diffDays < 7) return `${diffDays} ngày trước`;
    return date.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-100 font-sans">
      <Sidebar userRole={user?.role} />
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

      <div className="flex-1 flex flex-col min-w-0">
        <Navbar user={user} />

        <main className="flex-1 p-6 md:p-8 space-y-6 max-w-7xl mx-auto w-full">
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h1 className="text-2xl font-black text-white flex items-center gap-2.5">
                <History className="w-7 h-7 text-indigo-400 drop-shadow" />
                Lịch Sử Đăng Nhập Thiết Bị (Device History)
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                Theo dõi nhật ký đăng nhập thực tế theo mã máy • Nhận diện nhân vật & server cuối cùng • Chống phình dữ liệu
              </p>
            </div>
          </div>

          {/* 2-Tab Switcher: Customer vs SVIP */}
          <div className="flex items-center gap-2 p-1.5 bg-slate-900 border border-slate-800 rounded-2xl w-fit shadow-md">
            <button
              onClick={() => handleTabChange('CUSTOMER')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all ${
                activeTab === 'CUSTOMER'
                  ? 'bg-gradient-to-r from-sky-600 to-indigo-600 text-white shadow-lg shadow-sky-500/25'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              <Users className="w-4 h-4" />
              <span>Thiết Bị Customer</span>
            </button>
            <button
              onClick={() => handleTabChange('SVIP')}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all ${
                activeTab === 'SVIP'
                  ? 'bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 shadow-lg shadow-amber-500/25'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
              }`}
            >
              <Crown className="w-4 h-4 text-slate-950" />
              <span>Thiết Bị SVIP (Client)</span>
            </button>
          </div>

          {/* Search Box */}
          <div className="glass-panel p-4 rounded-2xl border border-slate-800">
            <form onSubmit={handleSearchSubmit} className="relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Tìm kiếm theo Mã Máy MD5, Tên nhân vật, Server, UID..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-10 pr-24 py-2.5 bg-slate-900 border border-slate-700/80 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500"
              />
              <button
                type="submit"
                className="absolute right-2 top-1/2 -translate-y-1/2 px-4 py-1.5 rounded-lg text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white transition"
              >
                Tìm kiếm
              </button>
            </form>
          </div>

          {/* Device Table */}
          <div className="glass-panel rounded-2xl border border-slate-800 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-sm">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-900/60 text-slate-400 text-xs uppercase tracking-wider">
                    <th className="py-3.5 px-4 font-semibold">Mã Thiết Bị (MD5)</th>
                    <th className="py-3.5 px-4 font-semibold">Nhân Vật Gần Nhất</th>
                    <th className="py-3.5 px-4 font-semibold">Server Gần Nhất</th>
                    <th className="py-3.5 px-4 font-semibold">Thời Gian Last Login</th>
                    <th className="py-3.5 px-4 font-semibold">Lượt Login</th>
                    <th className="py-3.5 px-4 font-semibold">Trạng Thái</th>
                    <th className="py-3.5 px-4 font-semibold text-right">Chi Tiết</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {loading ? (
                    <tr>
                      <td colSpan={7} className="py-12 text-center text-slate-400">
                        <div className="animate-spin w-6 h-6 border-2 border-indigo-500 border-t-transparent rounded-full mx-auto mb-2" />
                        Đang tải lịch sử thiết bị...
                      </td>
                    </tr>
                  ) : devices.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-12 text-center text-slate-400">
                        Chưa có lịch sử đăng nhập nào cho loại thiết bị này
                      </td>
                    </tr>
                  ) : (
                    devices.map((d) => (
                      <tr key={d.deviceSnMd5} className="hover:bg-slate-900/40 transition">
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-xs text-sky-400 bg-sky-950/40 px-2 py-1 rounded border border-sky-800/30">
                              {d.deviceSnMd5.slice(0, 16)}...
                            </span>
                            <button
                              onClick={() => copyToClipboard(d.deviceSnMd5, 'Đã copy Mã Thiết Bị')}
                              title="Copy Mã Máy"
                              className="text-slate-500 hover:text-white p-1"
                            >
                              <Copy className="w-3.5 h-3.5" />
                            </button>
                          </div>
                          {d.tokenInfo && (
                            <div className="text-[11px] text-slate-400 mt-1 flex items-center gap-1.5">
                              <span>Hạn token:</span>
                              <span className="text-emerald-400 font-semibold">
                                {new Date(d.tokenInfo.expireAt).toLocaleDateString('vi-VN')}
                              </span>
                              {d.tokenInfo.isTest && (
                                <span className="px-1 text-[9px] font-bold bg-amber-500/20 text-amber-300 rounded border border-amber-500/30">
                                  TEST
                                </span>
                              )}
                            </div>
                          )}
                        </td>
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-1.5">
                            <User className="w-3.5 h-3.5 text-amber-400" />
                            <span className="font-bold text-amber-300">{d.characterName}</span>
                          </div>
                          <div className="text-[11px] text-slate-400 font-mono mt-0.5">UID: {d.characterUid}</div>
                        </td>
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-1.5 text-slate-200">
                            <Server className="w-3.5 h-3.5 text-cyan-400" />
                            <span className="font-medium">{d.serverName}</span>
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <div className="flex items-center gap-1.5 text-slate-200 font-semibold text-xs">
                            <Clock className="w-3.5 h-3.5 text-indigo-400" />
                            <span>{formatRelativeTime(d.lastLogin)}</span>
                          </div>
                          <div className="text-[10px] text-slate-500 mt-0.5">
                            {new Date(d.lastLogin).toLocaleString('vi-VN')}
                          </div>
                        </td>
                        <td className="py-3.5 px-4">
                          <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-slate-800 text-slate-200 border border-slate-700">
                            {d.totalLogins} lần
                          </span>
                        </td>
                        <td className="py-3.5 px-4">
                          {d.lastStatus === 'SUCCESS' ? (
                            <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 flex items-center gap-1 w-fit">
                              <CheckCircle2 className="w-3 h-3" /> Thành công
                            </span>
                          ) : (
                            <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/30 flex items-center gap-1 w-fit">
                              <ShieldAlert className="w-3 h-3" /> Thất bại
                            </span>
                          )}
                        </td>
                        <td className="py-3.5 px-4 text-right">
                          <Link
                            href={`/history/${encodeURIComponent(d.deviceSnMd5)}`}
                            className="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-bold text-indigo-300 hover:text-white transition"
                          >
                            <span>Lịch Sử</span>
                            <ExternalLink className="w-3.5 h-3.5" />
                          </Link>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {pagination.totalPages > 1 && (
              <div className="p-4 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
                <div>
                  Tổng cộng: <strong className="text-white">{pagination.total}</strong> thiết bị
                </div>
                <div className="flex items-center gap-2">
                  <button
                    disabled={page <= 1}
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    className="p-1.5 rounded-lg bg-slate-900 border border-slate-800 disabled:opacity-40 hover:bg-slate-800"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>
                  <span>
                    Trang {page} / {pagination.totalPages}
                  </span>
                  <button
                    disabled={page >= pagination.totalPages}
                    onClick={() => setPage((p) => Math.min(pagination.totalPages, p + 1))}
                    className="p-1.5 rounded-lg bg-slate-900 border border-slate-800 disabled:opacity-40 hover:bg-slate-800"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
