'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import {
  Crown,
  PlusCircle,
  Search,
  Copy,
  Trash2,
  Edit,
  CheckCircle2,
  AlertTriangle,
  Clock,
  RotateCcw,
  Ban,
  ChevronLeft,
  ChevronRight,
  ShieldCheck,
  Smartphone,
  Calendar,
  Layers,
  Sparkles,
  Flame,
  Info,
} from 'lucide-react';

export default function SvipTokensPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  // =========================================================================
  // [MOD FEATURE]: KHỞI TẠO BỘ LỌC TỪ URL SEARCH PARAMS CHO SVIP TOKENS
  // Mô tả: Hỗ trợ nhận createdBy, search và action từ Dashboard chuyển sang
  // =========================================================================
  const urlParams = typeof window !== 'undefined' ? new URLSearchParams(window.location.search) : null;
  const initialCreatedBy = urlParams?.get('createdBy') || 'ALL';
  const initialSearch = urlParams?.get('search') || '';
  const initialStatus = initialSearch ? 'ALL' : 'ACTIVE';

  const [tokens, setTokens] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState(initialSearch);
  const [statusFilter, setStatusFilter] = useState(initialStatus);
  const [createdByFilter, setCreatedByFilter] = useState(initialCreatedBy);
  const [usersList, setUsersList] = useState<any[]>([]);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Pagination State
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(20);
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0, totalPages: 1 });

  // Modal State (Create / Edit)
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingToken, setEditingToken] = useState<any>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form Fields
  const [formData, setFormData] = useState({
    deviceSnMd5: '',
    characterUid: '',
    isAllUid: false,
    customerName: '',
    durationDays: 30,
    startDate: '',
    mainTier: 8,
    subTier: 7,
    price: 0,
    isTest: false,
    notes: '',
  });

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
          if (resData.user.role === 'ADMIN') {
            fetch('/api/users')
              .then((r) => r.json())
              .then((d) => {
                if (d?.users) setUsersList(d.users);
              })
              .catch(() => {});
          }
        }
      })
      .catch(() => {});
  }, [router]);

  const loadTokens = async () => {
    setLoading(true);
    try {
      const query = new URLSearchParams({
        page: page.toString(),
        limit: limit.toString(),
        search,
        status: statusFilter,
        createdBy: createdByFilter,
      });

      const res = await fetch(`/api/svip-tokens?${query.toString()}`);
      if (res.ok) {
        const data = await res.json();
        setTokens(data.tokens || []);
        if (data.pagination) setPagination(data.pagination);
      } else {
        showToast('Không thể tải danh sách Token SVIP', 'error');
      }
    } catch {
      showToast('Lỗi mạng khi tải Token SVIP', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user) {
      loadTokens();
    }
  }, [page, limit, statusFilter, createdByFilter, user]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    loadTokens();
  };

  const copyToClipboard = (text: string, label: string = 'Đã sao chép') => {
    navigator.clipboard.writeText(text);
    showToast(label, 'success');
  };

  const openCreateModal = () => {
    const now = new Date();
    const nowLocal = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    setEditingToken(null);
    setFormData({
      deviceSnMd5: '',
      characterUid: '',
      isAllUid: false,
      customerName: '',
      durationDays: 30,
      startDate: nowLocal,
      mainTier: 8,
      subTier: 7,
      price: 0,
      isTest: false,
      notes: '',
    });
    setIsModalOpen(true);
  };

  const openEditModal = (token: any) => {
    setEditingToken(token);
    let origStart: Date;
    if (token.expireAt && token.durationDays) {
      origStart = new Date(new Date(token.expireAt).getTime() - Number(token.durationDays) * 86400 * 1000);
    } else if (token.createdAt) {
      origStart = new Date(token.createdAt);
    } else {
      origStart = new Date();
    }
    const startDateFormatted = new Date(origStart.getTime() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 16);

    const isAll = (token.characterUid || '').toUpperCase() === 'ALL';
    setFormData({
      deviceSnMd5: token.deviceSnMd5 || '',
      characterUid: token.characterUid || '',
      isAllUid: isAll,
      customerName: token.customerName || '',
      durationDays: token.durationDays || 30,
      startDate: startDateFormatted,
      mainTier: token.characterReincarnation || 8,
      subTier: token.characterReincarnationSecondary || 7,
      price: token.price || 0,
      isTest: Boolean(token.isTest),
      notes: '',
    });
    setIsModalOpen(true);
  };

  // =========================================================================
  // [MOD FEATURE]: TỰ ĐỘNG MỞ MODAL XEM CHI TIẾT HOẶC TẠO MỚI TOKEN SVIP TỪ URL
  // Mô tả: Hỗ trợ query ?action=create và ?edit={tokenId} từ Dashboard
  // =========================================================================
  useEffect(() => {
    const params = typeof window !== 'undefined' ? new URLSearchParams(window.location.search) : null;
    if (!params) return;

    const action = params.get('action');
    if (action === 'create') {
      openCreateModal();
    }

    const editId = params.get('edit');
    if (editId) {
      fetch(`/api/svip-tokens/${editId}`)
        .then((res) => {
          if (res.ok) return res.json();
          return null;
        })
        .then((data) => {
          if (data?.token) {
            openEditModal(data.token);
          }
        })
        .catch((e) => console.error('Failed to load token for edit:', e));
    }
  }, []);

  // Tính Ngày hết hạn dự kiến theo startDate + durationDays
  const calculateExpirePreview = () => {
    const start = formData.startDate ? new Date(formData.startDate) : new Date();
    const dur = Number(formData.durationDays) || 0;
    const exp = new Date(start.getTime() + dur * 86400 * 1000);
    if (isNaN(exp.getTime())) return 'N/A';
    return exp.toLocaleString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.deviceSnMd5.trim()) {
      showToast('Vui lòng nhập Mã Thiết Bị (MD5)', 'error');
      return;
    }

    const finalUid = formData.isAllUid ? 'ALL' : formData.characterUid.trim();
    if (!finalUid) {
      showToast('Vui lòng nhập UID Nhân vật hoặc chọn ALL', 'error');
      return;
    }

    if (finalUid.toUpperCase() === 'ALL' && user?.role !== 'ADMIN') {
      showToast('Chỉ Quản trị viên (Admin) mới có quyền tạo Token SVIP cho tất cả UID (ALL)!', 'error');
      return;
    }

    setIsSubmitting(true);
    try {
      const payload = {
        deviceSnMd5: formData.deviceSnMd5.trim(),
        characterUid: finalUid,
        customerName: formData.customerName.trim(),
        durationDays: Number(formData.durationDays),
        startDate: formData.startDate ? new Date(formData.startDate).toISOString() : new Date().toISOString(),
        mainTier: Number(formData.mainTier),
        subTier: Number(formData.subTier),
        price: formData.isTest ? 0 : Number(formData.price),
        isTest: Boolean(formData.isTest),
        notes: formData.notes.trim(),
      };

      const url = editingToken ? `/api/svip-tokens/${editingToken.id}` : '/api/svip-tokens';
      const method = editingToken ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const resData = await res.json();
      if (res.ok) {
        showToast(editingToken ? 'Cập nhật Token SVIP thành công!' : 'Tạo Token SVIP thành công!');
        setIsModalOpen(false);
        loadTokens();
      } else {
        showToast(resData.error || 'Có lỗi xảy ra', 'error');
      }
    } catch {
      showToast('Lỗi mạng khi lưu Token SVIP', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteToken = async (id: string, isDeleted: boolean) => {
    const action = isDeleted ? 'restore' : 'soft';
    const confirmMsg = isDeleted
      ? 'Khôi phục Token SVIP này?'
      : 'Thu hồi (Xóa mềm) Token SVIP này? Client sẽ không thể đăng nhập!';

    if (!confirm(confirmMsg)) return;

    try {
      const res = await fetch(`/api/svip-tokens/${id}?action=${action}`, { method: 'DELETE' });
      if (res.ok) {
        showToast(isDeleted ? 'Đã khôi phục Token SVIP' : 'Đã thu hồi Token SVIP');
        loadTokens();
      } else {
        showToast('Thao tác thất bại', 'error');
      }
    } catch {
      showToast('Lỗi mạng khi xóa Token', 'error');
    }
  };

  const getStatusBadge = (t: any) => {
    if (t.isDeleted) {
      return (
        <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/30 flex items-center gap-1 w-fit">
          <Ban className="w-3 h-3" /> Đã thu hồi
        </span>
      );
    }
    const isExpired = new Date(t.expireAt) < new Date();
    const threeDaysLater = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
    const isExpiringSoon = !isExpired && new Date(t.expireAt) <= threeDaysLater;

    if (isExpired) {
      return (
        <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-slate-700/50 text-slate-400 border border-slate-600 flex items-center gap-1 w-fit">
          <Clock className="w-3 h-3" /> Hết hạn
        </span>
      );
    }
    if (isExpiringSoon) {
      return (
        <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/30 flex items-center gap-1 w-fit">
          <AlertTriangle className="w-3 h-3" /> Sắp hết hạn
        </span>
      );
    }
    return (
      <span className="px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 flex items-center gap-1 w-fit">
        <CheckCircle2 className="w-3 h-3" /> Hoạt động
      </span>
    );
  };

  const renderLastOnline = (tok: any) => {
    if (!tok.lastOnline) {
      return <span className="text-slate-500 italic text-[11px]">Chưa online</span>;
    }
    const diffMs = Date.now() - new Date(tok.lastOnline).getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const isOnline = diffMins <= 2;

    const charInfo = tok.lastCharacterName ? (
      <span className="text-slate-300 font-semibold text-[11px] block truncate max-w-[130px]" title={`${tok.lastCharacterName} (${tok.lastServerName || 'N/A'})`}>
        {tok.lastCharacterName} {tok.lastServerName ? `(${tok.lastServerName})` : ''}
      </span>
    ) : null;

    if (isOnline) {
      return (
        <div className="flex flex-col">
          <span className="inline-flex items-center gap-1.5 text-emerald-400 font-bold text-[11px]">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Online
          </span>
          {charInfo}
        </div>
      );
    }

    let timeStr = '';
    if (diffMins < 60) {
      timeStr = `${diffMins}p trước`;
    } else if (diffMins < 1440) {
      timeStr = `${Math.floor(diffMins / 60)}h trước`;
    } else {
      timeStr = new Date(tok.lastOnline).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
    }

    return (
      <div className="flex flex-col">
        <span className="text-slate-400 text-[11px]">{timeStr}</span>
        {charInfo}
      </div>
    );
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
                <Crown className="w-7 h-7 text-amber-400 drop-shadow" />
                Quản Lý Token SVIP (Bản Client)
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                Kích hoạt trực tuyến cho Client Dev/Admin • Sinh mã chuẩn Keygen • Phân quyền ALL chặt chẽ
              </p>
            </div>
            <button
              onClick={openCreateModal}
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 shadow-lg shadow-amber-500/20 transition-all hover:scale-[1.02] active:scale-[0.98]"
            >
              <PlusCircle className="w-4 h-4" />
              Tạo Token SVIP Mới
            </button>
          </div>

          {/* Filter Bar */}
          <div className="glass-panel p-4 rounded-2xl border border-slate-800 space-y-4">
            <div className="flex flex-col md:flex-row gap-3">
              <form onSubmit={handleSearchSubmit} className="flex-1 relative">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Tìm theo Mã Thiết Bị (MD5), UID nhân vật, Khách hàng..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-700/80 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:border-amber-500"
                />
              </form>

              {user?.role === 'ADMIN' && (
                <div className="w-full md:w-56">
                  <select
                    value={createdByFilter}
                    onChange={(e) => {
                      setCreatedByFilter(e.target.value);
                      setPage(1);
                    }}
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700/80 rounded-xl text-sm text-white focus:outline-none focus:border-amber-500"
                  >
                    <option value="ALL">Tất cả nhân viên Sale</option>
                    {usersList.map((u) => (
                      <option key={u.id} value={u.id}>
                        {u.displayName} (@{u.username})
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {/* Filter Tabs */}
            <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs">
              {[
                { label: 'Tất cả', val: 'ALL' },
                { label: 'Đang hoạt động', val: 'ACTIVE' },
                { label: 'Sắp hết hạn', val: 'EXPIRING_SOON' },
                { label: 'Đã hết hạn', val: 'EXPIRED' },
                { label: 'Dùng thử (Test)', val: 'TEST' },
                { label: 'Đã thu hồi', val: 'DELETED' },
              ].map((tab) => (
                <button
                  key={tab.val}
                  onClick={() => {
                    setStatusFilter(tab.val);
                    setPage(1);
                  }}
                  className={`px-3 py-1.5 rounded-lg font-medium transition whitespace-nowrap ${
                    statusFilter === tab.val
                      ? 'bg-amber-500 text-slate-950 font-bold shadow'
                      : 'bg-slate-900 text-slate-400 hover:text-white hover:bg-slate-800'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          {/* Tokens Table */}
          <div className="glass-panel rounded-2xl border border-slate-800 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-sm">
                <thead>
                  <tr className="border-b border-slate-800 bg-slate-900/60 text-slate-400 text-xs uppercase tracking-wider">
                    <th className="py-3.5 px-4 font-semibold">Mã Thiết Bị (MD5)</th>
                    <th className="py-3.5 px-4 font-semibold">UID Nhân Vật</th>
                    <th className="py-3.5 px-4 font-semibold">Cấp Chuyển</th>
                    <th className="py-3.5 px-4 font-semibold">Thời Hạn</th>
                    <th className="py-3.5 px-4 font-semibold">Hết Hạn</th>
                    <th className="py-3.5 px-4 font-semibold">Online Gần Nhất</th>
                    <th className="py-3.5 px-4 font-semibold">Trạng Thái</th>
                    <th className="py-3.5 px-4 font-semibold">Người Tạo</th>
                    <th className="py-3.5 px-4 font-semibold text-right">Thao Tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {loading ? (
                    <tr>
                      <td colSpan={9} className="py-12 text-center text-slate-400">
                        <div className="animate-spin w-6 h-6 border-2 border-amber-500 border-t-transparent rounded-full mx-auto mb-2" />
                        Đang tải danh sách Token SVIP...
                      </td>
                    </tr>
                  ) : tokens.length === 0 ? (
                    <tr>
                      <td colSpan={9} className="py-12 text-center text-slate-400">
                        Không tìm thấy Token SVIP nào phù hợp
                      </td>
                    </tr>
                  ) : (
                    tokens.map((token) => {
                      const isAll = (token.characterUid || '').toUpperCase() === 'ALL';
                      return (
                        <tr key={token.id} className="hover:bg-slate-900/40 transition">
                          <td className="py-3.5 px-4">
                            <div className="flex items-center gap-2">
                              <span className="font-mono text-xs text-sky-400 bg-sky-950/40 px-2 py-1 rounded border border-sky-800/30">
                                {token.deviceSnMd5 ? token.deviceSnMd5.slice(0, 16) + '...' : 'N/A'}
                              </span>
                              <button
                                onClick={() => copyToClipboard(token.deviceSnMd5, 'Đã copy Mã Thiết Bị MD5')}
                                title="Copy Mã Thiết Bị"
                                className="text-slate-500 hover:text-white p-1"
                              >
                                <Copy className="w-3.5 h-3.5" />
                              </button>
                            </div>
                            {token.customerName && (
                              <div className="text-[11px] text-slate-400 mt-0.5">Khách: {token.customerName}</div>
                            )}
                          </td>
                          <td className="py-3.5 px-4">
                            {isAll ? (
                              <span className="px-2 py-0.5 rounded-full text-xs font-extrabold bg-fuchsia-500/20 text-fuchsia-300 border border-fuchsia-500/40 flex items-center gap-1 w-fit shadow-sm shadow-fuchsia-500/10">
                                <Sparkles className="w-3 h-3 text-fuchsia-400" /> ALL (MỌI NV)
                              </span>
                            ) : (
                              <span className="font-mono text-xs text-amber-300 bg-amber-950/30 px-2 py-1 rounded border border-amber-800/30">
                                {token.characterUid}
                              </span>
                            )}
                          </td>
                          <td className="py-3.5 px-4">
                            <span className="text-xs font-semibold text-emerald-400 bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-800/30">
                              C{token.characterReincarnation || 8} / C{token.characterReincarnationSecondary || 7}
                            </span>
                          </td>
                          <td className="py-3.5 px-4">
                            <div className="flex items-center gap-1.5">
                              <span className="font-semibold text-slate-200">
                                {token.durationDays === 0.000694444 ? '60 giây' : `${token.durationDays} ngày`}
                              </span>
                              {token.isTest && (
                                <span className="px-1.5 py-0.2 rounded text-[10px] font-extrabold bg-amber-500/20 text-amber-400 border border-amber-500/30">
                                  TEST
                                </span>
                              )}
                            </div>
                          </td>
                          <td className="py-3.5 px-4 text-xs text-slate-300">
                            {new Date(token.expireAt).toLocaleDateString('vi-VN', {
                              day: '2-digit',
                              month: '2-digit',
                              year: 'numeric',
                            })}
                          </td>
                          <td className="py-3.5 px-4 whitespace-nowrap">
                            {renderLastOnline(token)}
                          </td>
                          <td className="py-3.5 px-4">{getStatusBadge(token)}</td>
                          <td className="py-3.5 px-4 text-xs">
                            <div className="font-medium text-slate-200">{token.createdBy?.displayName || 'N/A'}</div>
                            <div className="text-[10px] text-slate-500">@{token.createdBy?.username}</div>
                          </td>
                          <td className="py-3.5 px-4 text-right">
                            <div className="flex items-center justify-end gap-1.5">
                              <button
                                onClick={() => copyToClipboard(token.encryptedToken, 'Đã copy Chuỗi Token SVIP')}
                                title="Copy Chuỗi Token Base64"
                                className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-sky-400 transition"
                              >
                                <Copy className="w-4 h-4" />
                              </button>
                              <button
                                onClick={() => openEditModal(token)}
                                title="Chỉnh sửa / Gia hạn"
                                className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-amber-400 transition"
                              >
                                <Edit className="w-4 h-4" />
                              </button>
                              <button
                                onClick={() => handleDeleteToken(token.id, token.isDeleted)}
                                title={token.isDeleted ? 'Khôi phục' : 'Thu hồi'}
                                className={`p-1.5 rounded-lg transition ${
                                  token.isDeleted
                                    ? 'bg-slate-800 hover:bg-slate-700 text-emerald-400'
                                    : 'bg-slate-800 hover:bg-slate-700 text-rose-400'
                                }`}
                              >
                                {token.isDeleted ? <RotateCcw className="w-4 h-4" /> : <Trash2 className="w-4 h-4" />}
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {pagination.totalPages > 1 && (
              <div className="p-4 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
                <div>
                  Tổng cộng: <strong className="text-white">{pagination.total}</strong> token SVIP
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

      {/* Modal Tạo / Sửa Token SVIP */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="glass-panel w-full max-w-xl rounded-2xl border border-slate-700/80 bg-slate-950 p-6 shadow-2xl space-y-5 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Crown className="w-5 h-5 text-amber-400" />
                {editingToken ? 'Cập Nhật / Gia Hạn Token SVIP' : 'Tạo Token SVIP Mới'}
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-slate-800"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleFormSubmit} className="space-y-4 text-sm">
              {/* Mã Thiết Bị MD5 */}
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Mã Thiết Bị (Device SN MD5) <span className="text-rose-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="VD: 8a5f80b... (32 ký tự MD5)"
                  value={formData.deviceSnMd5}
                  onChange={(e) => setFormData({ ...formData, deviceSnMd5: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white font-mono text-xs focus:outline-none focus:border-amber-500"
                />
              </div>

              {/* UID Nhân Vật */}
              <div>
                <div className="flex items-center justify-between mb-1">
                  <label className="text-xs font-semibold text-slate-300">
                    Mã UID Nhân Vật <span className="text-rose-400">*</span>
                  </label>
                  {user?.role === 'ADMIN' ? (
                    <label className="flex items-center gap-1.5 text-xs text-fuchsia-400 font-bold cursor-pointer">
                      <input
                        type="checkbox"
                        checked={formData.isAllUid}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            isAllUid: e.target.checked,
                            characterUid: e.target.checked ? 'ALL' : '',
                          })
                        }
                        className="rounded border-slate-700 text-fuchsia-500 focus:ring-0"
                      />
                      <span>Đăng nhập mọi nhân vật (ALL)</span>
                    </label>
                  ) : (
                    <span className="text-[11px] text-slate-500 italic">
                      * Sale bắt buộc nhập UID cụ thể (Không được cấp ALL)
                    </span>
                  )}
                </div>
                <input
                  type="text"
                  required={!formData.isAllUid}
                  disabled={formData.isAllUid}
                  placeholder={formData.isAllUid ? 'Đã kích hoạt chế độ ALL cho mọi nhân vật' : 'Nhập UID nhân vật của khách (VD: 1000234)'}
                  value={formData.isAllUid ? 'ALL' : formData.characterUid}
                  onChange={(e) => {
                    const val = e.target.value;
                    if (val.trim().toUpperCase() === 'ALL' && user?.role !== 'ADMIN') {
                      showToast('Nhân viên SALE không có quyền nhập ALL!', 'error');
                      return;
                    }
                    setFormData({ ...formData, characterUid: val });
                  }}
                  className={`w-full px-3 py-2 border rounded-xl text-sm focus:outline-none ${
                    formData.isAllUid
                      ? 'bg-fuchsia-950/30 border-fuchsia-800/40 text-fuchsia-300 font-bold'
                      : 'bg-slate-900 border-slate-700 text-white focus:border-amber-500 font-mono'
                  }`}
                />
              </div>

              {/* Cấp Chuyển Chính / Phụ */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">
                    Cấp Chuyển Chính (3-12)
                  </label>
                  <input
                    type="number"
                    min={3}
                    max={12}
                    value={formData.mainTier}
                    onChange={(e) => {
                      const mainVal = parseInt(e.target.value, 10) || 8;
                      setFormData({
                        ...formData,
                        mainTier: mainVal,
                        subTier: mainVal > 1 ? mainVal - 1 : 1,
                      });
                    }}
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-amber-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">
                    Cấp Chuyển Phụ (3-12)
                  </label>
                  <input
                    type="number"
                    min={3}
                    max={12}
                    value={formData.subTier}
                    onChange={(e) => setFormData({ ...formData, subTier: parseInt(e.target.value, 10) || 7 })}
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              {/* Ngày Bắt Đầu & Thời Hạn */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1 flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5 text-slate-400" /> Ngày Bắt Đầu
                  </label>
                  <input
                    type="datetime-local"
                    value={formData.startDate}
                    onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white text-xs focus:outline-none focus:border-amber-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1 flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5 text-slate-400" /> Thời Lượng (Số Ngày)
                  </label>
                  <input
                    type="number"
                    step="any"
                    min={0.0001}
                    value={formData.durationDays}
                    onChange={(e) => setFormData({ ...formData, durationDays: parseFloat(e.target.value) || 0 })}
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm font-semibold focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              {/* Chọn Nhanh Thời Hạn */}
              <div>
                <div className="text-[11px] text-slate-400 mb-1.5">Chọn nhanh thời hạn:</div>
                <div className="flex flex-wrap gap-1.5">
                  {[
                    { label: '3 ngày', val: 3 },
                    { label: '7 ngày', val: 7 },
                    { label: '15 ngày', val: 15 },
                    { label: '30 ngày', val: 30 },
                    { label: '60 ngày', val: 60 },
                    { label: '90 ngày', val: 90 },
                    { label: '60 giây test', val: 0.000694444 },
                  ].map((preset) => (
                    <button
                      type="button"
                      key={preset.label}
                      onClick={() => setFormData({ ...formData, durationDays: preset.val })}
                      className={`px-2.5 py-1 rounded-lg text-xs font-medium border transition ${
                        formData.durationDays === preset.val
                          ? 'bg-amber-500/20 text-amber-300 border-amber-500/50 font-bold'
                          : 'bg-slate-900 text-slate-400 border-slate-800 hover:bg-slate-800 hover:text-white'
                      }`}
                    >
                      {preset.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Preview Ngày Hết Hạn */}
              <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-800 text-xs flex items-center justify-between">
                <span className="text-slate-400">Ngày Hết Hạn Dự Kiến:</span>
                <span className="font-bold text-emerald-400">{calculateExpirePreview()}</span>
              </div>

              {/* Giá Tiền & Tùy chọn Test */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 items-center">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">
                    Giá Bán (VNĐ)
                  </label>
                  <input
                    type="number"
                    disabled={formData.isTest}
                    value={formData.isTest ? 0 : formData.price}
                    onChange={(e) => setFormData({ ...formData, price: parseFloat(e.target.value) || 0 })}
                    placeholder="0"
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-amber-500 disabled:opacity-50"
                  />
                </div>
                <div className="pt-4">
                  <label className="flex items-center gap-2 p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/20 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.isTest}
                      onChange={(e) => setFormData({ ...formData, isTest: e.target.checked, price: e.target.checked ? 0 : formData.price })}
                      className="rounded border-slate-700 text-amber-500 focus:ring-0"
                    />
                    <div>
                      <div className="text-xs font-bold text-amber-300">Token Dùng Thử (Test)</div>
                      <div className="text-[10px] text-slate-400">Loại trừ khỏi doanh thu</div>
                    </div>
                  </label>
                </div>
              </div>

              {/* Tên Khách & Ghi Chú */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">
                    Tên Khách Hàng (Tùy chọn)
                  </label>
                  <input
                    type="text"
                    placeholder="VD: Anh Nam Loren"
                    value={formData.customerName}
                    onChange={(e) => setFormData({ ...formData, customerName: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-amber-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1">
                    Ghi Chú
                  </label>
                  <input
                    type="text"
                    placeholder="Ghi chú nội bộ..."
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:outline-none focus:border-amber-500"
                  />
                </div>
              </div>

              {/* Submit Buttons */}
              <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-sm font-semibold bg-slate-800 text-slate-300 hover:bg-slate-700 transition"
                >
                  Hủy Bỏ
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-6 py-2 rounded-xl text-sm font-bold bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-slate-950 shadow-lg shadow-amber-500/20 transition disabled:opacity-50"
                >
                  {isSubmitting ? 'Đang tạo Token...' : editingToken ? 'Cập Nhật Token SVIP' : 'Lưu & Sinh Token SVIP'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
