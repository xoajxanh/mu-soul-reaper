'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import Link from 'next/link';
import {
  ArrowLeft,
  Smartphone,
  Copy,
  Clock,
  User,
  Server,
  CheckCircle2,
  ShieldAlert,
  Crown,
  Users,
  Calendar,
} from 'lucide-react';

export default function DeviceHistoryDetailPage({ params }: { params: { md5: string } }) {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const cleanMd5 = decodeURIComponent(params.md5);

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
      .then((resData) => {
        if (resData?.user) {
          setUser(resData.user);
          loadDetail();
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const loadDetail = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/history/${encodeURIComponent(cleanMd5)}`);
      if (res.ok) {
        const json = await res.json();
        setData(json);
      } else {
        showToast('Không thể tải chi tiết lịch sử thiết bị', 'error');
      }
    } catch {
      showToast('Lỗi mạng khi tải chi tiết lịch sử', 'error');
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text: string, label: string = 'Đã sao chép') => {
    navigator.clipboard.writeText(text);
    showToast(label, 'success');
  };

  return (
    <div className="flex min-h-screen bg-slate-950 text-slate-100 font-sans">
      <Sidebar userRole={user?.role} />
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

      <div className="flex-1 flex flex-col min-w-0">
        <Navbar user={user} />

        <main className="flex-1 p-6 md:p-8 space-y-6 max-w-6xl mx-auto w-full">
          {/* Back button */}
          <Link
            href="/history"
            className="inline-flex items-center gap-2 text-xs font-semibold text-slate-400 hover:text-white transition group"
          >
            <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition" />
            Quay lại Danh Sách Thiết Bị
          </Link>

          {/* Device Header Card */}
          <div className="glass-panel p-6 rounded-2xl border border-slate-800 space-y-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <div className="text-xs uppercase tracking-wider text-slate-400 font-bold flex items-center gap-1.5 mb-1">
                  <Smartphone className="w-4 h-4 text-indigo-400" />
                  Chi Tiết Thiết Bị (Device MD5)
                </div>
                <div className="flex items-center gap-3">
                  <span className="font-mono text-base md:text-lg font-bold text-white bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-700">
                    {cleanMd5}
                  </span>
                  <button
                    onClick={() => copyToClipboard(cleanMd5, 'Đã copy Mã Thiết Bị MD5')}
                    className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-sky-400 transition"
                    title="Copy Mã Máy"
                  >
                    <Copy className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="flex items-center gap-3 text-xs">
                <div className="p-3 rounded-xl bg-slate-900/90 border border-slate-800 text-center">
                  <div className="text-slate-400">Tổng Số Lượt Login</div>
                  <div className="text-lg font-black text-indigo-400 mt-0.5">
                    {data?.totalRecords || 0}
                  </div>
                </div>
              </div>
            </div>

            {/* Linked Tokens */}
            {data?.tokens && data.tokens.length > 0 && (
              <div className="pt-3 border-t border-slate-800/80">
                <div className="text-xs font-semibold text-slate-400 mb-2">Token Bản Quyền Gán Với Thiết Bị Này:</div>
                <div className="flex flex-wrap gap-2">
                  {data.tokens.map((t: any) => (
                    <div
                      key={t.id}
                      className="p-2.5 rounded-xl bg-slate-900 border border-slate-800 text-xs flex items-center gap-3"
                    >
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        t.type === 'SVIP' ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' : 'bg-sky-500/20 text-sky-300 border border-sky-500/30'
                      }`}>
                        {t.type}
                      </span>
                      <span>UID: <strong className="text-white">{t.characterUid}</strong></span>
                      <span>Hết hạn: <strong className="text-emerald-400">{new Date(t.expireAt).toLocaleDateString('vi-VN')}</strong></span>
                      {t.customerName && <span className="text-slate-400">({t.customerName})</span>}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Timeline Table */}
          <div className="glass-panel rounded-2xl border border-slate-800 overflow-hidden">
            <div className="p-4 border-b border-slate-800 bg-slate-900/40 flex items-center justify-between">
              <h2 className="text-sm font-bold text-white flex items-center gap-2">
                <Clock className="w-4 h-4 text-indigo-400" />
                Dòng Thời Gian Đăng Nhập (Tối đa 100 lần gần nhất)
              </h2>
              <span className="text-xs text-slate-400">
                * Chỉ lưu sự kiện khi Mở Game / Login nhân vật (Không lưu heartbeat 1p)
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-sm">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-900/60 text-slate-400 text-xs uppercase tracking-wider">
                    <th className="py-3 px-4 font-semibold">Thời Gian</th>
                    <th className="py-3 px-4 font-semibold">Loại Bản Quyền</th>
                    <th className="py-3 px-4 font-semibold">Tên Nhân Vật</th>
                    <th className="py-3 px-4 font-semibold">UID Nhân Vật</th>
                    <th className="py-3 px-4 font-semibold">Server</th>
                    <th className="py-3 px-4 font-semibold">Kết Quả Xác Thực</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60 text-xs">
                  {loading ? (
                    <tr>
                      <td colSpan={6} className="py-12 text-center text-slate-400">
                        <div className="animate-spin w-6 h-6 border-2 border-indigo-500 border-t-transparent rounded-full mx-auto mb-2" />
                        Đang tải lịch sử đăng nhập...
                      </td>
                    </tr>
                  ) : !data?.history || data.history.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="py-12 text-center text-slate-400">
                        Chưa có dữ liệu đăng nhập cho thiết bị này
                      </td>
                    </tr>
                  ) : (
                    data.history.map((item: any) => (
                      <tr key={item.id} className="hover:bg-slate-900/40 transition">
                        <td className="py-3 px-4 text-slate-300 font-medium">
                          {new Date(item.createdAt).toLocaleString('vi-VN', {
                            day: '2-digit',
                            month: '2-digit',
                            year: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                            second: '2-digit',
                          })}
                        </td>
                        <td className="py-3 px-4">
                          <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            item.type === 'SVIP' ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' : 'bg-sky-500/20 text-sky-300 border border-sky-500/30'
                          }`}>
                            {item.type || 'CUSTOMER'}
                          </span>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-1.5 font-bold text-amber-300">
                            <User className="w-3.5 h-3.5 text-amber-400" />
                            <span>{item.characterName || 'N/A'}</span>
                          </div>
                        </td>
                        <td className="py-3 px-4 font-mono text-slate-300">
                          {item.characterUid}
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-1.5 text-slate-200">
                            <Server className="w-3.5 h-3.5 text-cyan-400" />
                            <span>{item.serverName || 'N/A'}</span>
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          {item.status === 'SUCCESS' ? (
                            <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 flex items-center gap-1 w-fit">
                              <CheckCircle2 className="w-3 h-3" /> Thành công
                            </span>
                          ) : (
                            <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/30 flex items-center gap-1 w-fit">
                              <ShieldAlert className="w-3 h-3" /> Thất bại / Hết hạn
                            </span>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
