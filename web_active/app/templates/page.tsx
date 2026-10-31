'use client';

import React, { useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import {
  MessageSquareQuote,
  Plus,
  Edit2,
  Trash2,
  X,
  Copy,
  Check,
  Image as ImageIcon,
  Upload,
  Download,
  Search,
  Tag,
  Globe,
  User as UserIcon,
  Maximize2,
  ExternalLink,
  Sparkles,
  Layers,
  ArrowRight,
} from 'lucide-react';

interface TemplateItem {
  id: string;
  title: string;
  shortcut?: string | null;
  category: string;
  content: string;
  imageUrl?: string | null;
  isGlobal: boolean;
  sortOrder: number;
  createdById: string;
  createdAt: string;
  createdBy?: {
    id: string;
    username: string;
    displayName: string;
    role: string;
  };
}

const CATEGORIES = [
  { id: 'ALL', name: 'Tất Cả' },
  { id: 'BÁO GIÁ', name: 'Báo Giá' },
  { id: 'THANH TOÁN', name: 'Thanh Toán' },
  { id: 'HƯỚNG DẪN', name: 'Hướng Dẫn' },
  { id: 'CSKH', name: 'Chăm Sóc Khách' },
  { id: 'MINE', name: 'Mẫu Của Tôi' },
];

export default function MessageTemplatesPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [templates, setTemplates] = useState<TemplateItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState('ALL');

  // Copy status indicators
  const [copiedTextId, setCopiedTextId] = useState<string | null>(null);
  const [copiedImageId, setCopiedImageId] = useState<string | null>(null);
  const [smartStep, setSmartStep] = useState<{ id: string; step: 1 | 2 } | null>(null);
  const pendingTemplateRef = useRef<TemplateItem | null>(null);

  // Tự động copy tiếp Text khi Sale chuyển sang Zalo dán ảnh rồi quay lại web
  useEffect(() => {
    const handleWindowFocus = async () => {
      if (pendingTemplateRef.current) {
        const tpl = pendingTemplateRef.current;
        try {
          await navigator.clipboard.writeText(tpl.content);
          setCopiedTextId(tpl.id);
          setSmartStep({ id: tpl.id, step: 2 });
          setToast({
            message: `✨ Đã tự động nạp Văn bản của "${tpl.title}" vào Clipboard! Bác sang Zalo/Telegram ấn Ctrl+V gửi tiếp nhé.`,
            type: 'success',
          });
          pendingTemplateRef.current = null;
          setTimeout(() => {
            setSmartStep(null);
            setCopiedTextId(null);
          }, 3500);
        } catch (e) {
          console.error(e);
        }
      }
    };

    window.addEventListener('focus', handleWindowFocus);
    return () => window.removeEventListener('focus', handleWindowFocus);
  }, []);

  // Image preview lightbox
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  // Modal State (Create / Edit)
  const [showModal, setShowModal] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<TemplateItem | null>(null);
  const [title, setTitle] = useState('');
  const [shortcut, setShortcut] = useState('');
  const [category, setCategory] = useState('BÁO GIÁ');
  const [content, setContent] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [isGlobal, setIsGlobal] = useState(true);
  const [sortOrder, setSortOrder] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);

  const fileInputRef = useRef<HTMLInputElement>(null);

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
          loadTemplates(activeCategory, searchQuery);
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const loadTemplates = async (cat = activeCategory, query = searchQuery) => {
    setLoading(true);
    try {
      let url = `/api/templates?category=${encodeURIComponent(cat)}`;
      if (query.trim()) {
        url += `&q=${encodeURIComponent(query.trim())}`;
      }
      const res = await fetch(url);
      if (res.ok) {
        const json = await res.json();
        setTemplates(json.templates || []);
      }
    } catch (e) {
      console.error(e);
      setToast({ message: 'Không thể tải danh sách mẫu tin nhắn', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleCategoryChange = (cat: string) => {
    setActiveCategory(cat);
    loadTemplates(cat, searchQuery);
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    loadTemplates(activeCategory, searchQuery);
  };

  // Copy text to clipboard
  const handleCopyText = async (tpl: TemplateItem) => {
    try {
      await navigator.clipboard.writeText(tpl.content);
      setCopiedTextId(tpl.id);
      setToast({ message: `Đã sao chép văn bản "${tpl.title}" vào Clipboard!`, type: 'success' });
      setTimeout(() => setCopiedTextId(null), 2000);
    } catch (err) {
      console.error(err);
      setToast({ message: 'Lỗi khi sao chép văn bản vào clipboard', type: 'error' });
    }
  };

  // Convert any image URL to standard PNG Blob and copy to Clipboard
  const handleCopyImage = async (tpl: TemplateItem) => {
    if (!tpl.imageUrl) return;
    try {
      setToast({ message: 'Đang xử lý ảnh để dán vào Zalo/Telegram...', type: 'success' });

      // Fetch the image
      const res = await fetch(tpl.imageUrl);
      const blob = await res.blob();

      // Modern Clipboard API requires image/png mime-type
      const img = new Image();
      img.crossOrigin = 'anonymous';

      const blobUrl = URL.createObjectURL(blob);
      img.src = blobUrl;

      await new Promise((resolve, reject) => {
        img.onload = () => resolve(true);
        img.onerror = () => reject(new Error('Không thể tải ảnh'));
      });

      const canvas = document.createElement('canvas');
      canvas.width = img.naturalWidth;
      canvas.height = img.naturalHeight;
      const ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('Canvas not supported');

      ctx.drawImage(img, 0, 0);
      URL.revokeObjectURL(blobUrl);

      canvas.toBlob(async (pngBlob) => {
        if (!pngBlob) {
          setToast({ message: 'Không thể chuyển đổi định dạng ảnh', type: 'error' });
          return;
        }

        try {
          await navigator.clipboard.write([
            new ClipboardItem({ 'image/png': pngBlob }),
          ]);
          setCopiedImageId(tpl.id);
          setToast({
            message: 'Đã copy Ảnh vào Clipboard! Bác chỉ cần mở Zalo/Telegram ấn Ctrl + V để gửi.',
            type: 'success',
          });
          setTimeout(() => setCopiedImageId(null), 2500);
        } catch (clipErr: any) {
          console.error(clipErr);
          setToast({
            message: 'Trình duyệt chặn ghi ảnh trực tiếp. Vui lòng bấm "Tải Ảnh" để gửi!',
            type: 'error',
          });
        }
      }, 'image/png');
    } catch (e: any) {
      console.error(e);
      setToast({ message: 'Lỗi khi sao chép ảnh: ' + (e.message || ''), type: 'error' });
    }
  };

  // Smart 2-Step Combo Copy (Image first, then text)
  const handleCopyBoth = async (tpl: TemplateItem) => {
    if (!tpl.imageUrl) {
      await handleCopyText(tpl);
      return;
    }

    // Nếu đang ở Bước 1 (đã copy ảnh), bấm tiếp là copy luôn text
    if (smartStep?.id === tpl.id && smartStep.step === 1) {
      try {
        await navigator.clipboard.writeText(tpl.content);
        setCopiedTextId(tpl.id);
        setSmartStep({ id: tpl.id, step: 2 });
        setToast({
          message: '✓ 2/2: Đã copy Văn Bản! Bác sang Zalo/Telegram ấn Ctrl + V gửi tiếp lời nhắn nhé.',
          type: 'success',
        });
        pendingTemplateRef.current = null;
        setTimeout(() => {
          setSmartStep(null);
          setCopiedTextId(null);
        }, 3000);
        return;
      } catch (e) {
        console.error(e);
      }
    }

    try {
      setToast({ message: 'Đang xử lý gói gửi nhanh (Ảnh + Lời nhắn)...', type: 'success' });
      const res = await fetch(tpl.imageUrl);
      const blob = await res.blob();

      const img = new Image();
      img.crossOrigin = 'anonymous';
      const blobUrl = URL.createObjectURL(blob);
      img.src = blobUrl;

      await new Promise((resolve, reject) => {
        img.onload = () => resolve(true);
        img.onerror = () => reject(new Error('Không thể tải ảnh'));
      });

      const canvas = document.createElement('canvas');
      canvas.width = img.naturalWidth;
      canvas.height = img.naturalHeight;
      const ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('Canvas not supported');
      ctx.drawImage(img, 0, 0);
      URL.revokeObjectURL(blobUrl);

      canvas.toBlob(async (pngBlob) => {
        if (!pngBlob) return;

        // Thử ghi đồng thời cả image + html + text (nếu app hỗ trợ rich paste sẽ nhận cả 2)
        try {
          const comboData: Record<string, Blob> = {
            'image/png': pngBlob,
            'text/plain': new Blob([tpl.content], { type: 'text/plain' }),
            'text/html': new Blob([
              `<img src="${window.location.origin}${tpl.imageUrl}"><br><p>${tpl.content.replace(/\n/g, '<br>')}</p>`
            ], { type: 'text/html' })
          };
          await navigator.clipboard.write([new ClipboardItem(comboData)]);
        } catch {
          try {
            await navigator.clipboard.write([new ClipboardItem({ 'image/png': pngBlob })]);
          } catch (clipErr) {
            console.error(clipErr);
          }
        }

        // Kích hoạt cơ chế thông minh: Bước 1 copy ảnh, khi quay lại web tự nạp text
        pendingTemplateRef.current = tpl;
        setSmartStep({ id: tpl.id, step: 1 });
        setCopiedImageId(tpl.id);

        setToast({
          message: '📸 1/2: Đã nạp Ảnh! Sang Zalo ấn Ctrl+V gửi ảnh -> Quay lại Web là tự nạp tiếp Text (hoặc bấm lại nút này)!',
          type: 'success',
        });
      }, 'image/png');
    } catch (err: any) {
      console.error(err);
      setToast({ message: 'Lỗi: ' + (err.message || ''), type: 'error' });
    }
  };

  // Open modal for Create / Edit
  const handleOpenModal = (tpl?: TemplateItem) => {
    if (tpl) {
      setEditingTemplate(tpl);
      setTitle(tpl.title);
      setShortcut(tpl.shortcut || '');
      setCategory(tpl.category || 'BÁO GIÁ');
      setContent(tpl.content);
      setImageUrl(tpl.imageUrl || '');
      setIsGlobal(tpl.isGlobal);
      setSortOrder(tpl.sortOrder || 0);
    } else {
      setEditingTemplate(null);
      setTitle('');
      setShortcut('');
      setCategory('BÁO GIÁ');
      setContent('');
      setImageUrl('');
      setIsGlobal(true);
      setSortOrder(templates.length + 1);
    }
    setShowModal(true);
  };

  // Image Upload Handler
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadingImage(true);
    try {
      const formData = new FormData();
      formData.append('file', file);

      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Tải ảnh thất bại');
      }

      setImageUrl(json.url);
      setToast({ message: 'Tải ảnh lên thành công!', type: 'success' });
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi khi tải ảnh', type: 'error' });
    } finally {
      setUploadingImage(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  // Save Template (POST or PUT)
  const handleSaveTemplate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) {
      setToast({ message: 'Vui lòng điền Tiêu đề và Nội dung tin nhắn', type: 'error' });
      return;
    }

    setSubmitting(true);
    try {
      const payload = {
        title: title.trim(),
        shortcut: shortcut.trim() || null,
        category: category.trim(),
        content: content.trim(),
        imageUrl: imageUrl.trim() || null,
        isGlobal: Boolean(isGlobal),
        sortOrder: Number(sortOrder) || 0,
      };

      const url = editingTemplate ? `/api/templates/${editingTemplate.id}` : '/api/templates';
      const method = editingTemplate ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Lỗi khi lưu mẫu tin nhắn');
      }

      setToast({
        message: editingTemplate ? 'Cập nhật mẫu tin nhắn thành công!' : 'Tạo mẫu tin nhắn mới thành công!',
        type: 'success',
      });
      setShowModal(false);
      loadTemplates(activeCategory, searchQuery);
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi hệ thống', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  // Delete Template
  const handleDeleteTemplate = async (tpl: TemplateItem) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa mẫu tin nhắn "${tpl.title}"?`)) return;

    try {
      const res = await fetch(`/api/templates/${tpl.id}`, { method: 'DELETE' });
      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Không thể xóa mẫu tin nhắn');
      }

      setToast({ message: 'Đã xóa mẫu tin nhắn', type: 'success' });
      loadTemplates(activeCategory, searchQuery);
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi khi xóa', type: 'error' });
    }
  };

  // Badge category color helper
  const getCategoryBadgeClass = (cat: string) => {
    switch (cat) {
      case 'BÁO GIÁ':
        return 'bg-amber-500/10 text-amber-400 border-amber-500/30';
      case 'THANH TOÁN':
        return 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30';
      case 'HƯỚNG DẪN':
        return 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30';
      case 'CSKH':
        return 'bg-purple-500/10 text-purple-400 border-purple-500/30';
      default:
        return 'bg-slate-700/50 text-slate-300 border-slate-600/40';
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

        <main className="p-4 md:p-8 space-y-6 flex-1 overflow-y-auto">
          {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

          {/* Header */}
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-3">
                <div className="p-2.5 rounded-xl bg-gradient-to-tr from-sky-500/20 to-indigo-500/20 border border-sky-500/30 text-sky-400">
                  <MessageSquareQuote className="w-6 h-6" />
                </div>
                <div>
                  <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                    Mẫu Tin Nhắn Trả Lời Nhanh
                    <span className="text-xs px-2.5 py-0.5 rounded-full bg-sky-500/10 text-sky-400 border border-sky-500/20 font-medium">
                      Sale Kit
                    </span>
                  </h1>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Kho kịch bản tư vấn, bảng giá & thông tin thanh toán. Bấm 1 chạm để copy Ảnh hoặc Text gửi Zalo / Telegram.
                  </p>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <button
                onClick={() => handleOpenModal()}
                className="px-4 py-2.5 gradient-button text-white text-sm font-semibold rounded-xl shadow-lg shadow-sky-500/20 flex items-center gap-2 hover:scale-[1.02] transition"
              >
                <Plus className="w-4 h-4" />
                Tạo Mẫu Tin Nhắn Mới
              </button>
            </div>
          </div>

          {/* Filters & Search */}
          <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 bg-slate-900/60 p-3 rounded-2xl border border-slate-800/80">
            {/* Category tabs */}
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 scrollbar-none">
              {CATEGORIES.map((cat) => {
                const isActive = activeCategory === cat.id;
                return (
                  <button
                    key={cat.id}
                    onClick={() => handleCategoryChange(cat.id)}
                    className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
                      isActive
                        ? 'bg-sky-500 text-white shadow-md shadow-sky-500/30'
                        : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                    }`}
                  >
                    {cat.name}
                  </button>
                );
              })}
            </div>

            {/* Search Box */}
            <form onSubmit={handleSearchSubmit} className="relative min-w-[260px]">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Tìm kịch bản, gõ tắt..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-slate-950/80 border border-slate-800 rounded-xl pl-9 pr-4 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-sky-500 transition"
              />
            </form>
          </div>

          {/* Content Grid */}
          {loading ? (
            <div className="py-24 text-center">
              <div className="w-8 h-8 border-3 border-sky-500/20 border-t-sky-500 rounded-full animate-spin mx-auto mb-3"></div>
              <p className="text-xs text-slate-400">Đang tải kịch bản tin nhắn...</p>
            </div>
          ) : templates.length === 0 ? (
            <div className="py-16 text-center bg-slate-900/40 rounded-2xl border border-dashed border-slate-800">
              <MessageSquareQuote className="w-12 h-12 text-slate-600 mx-auto mb-3" />
              <p className="text-sm font-medium text-slate-300">Chưa có mẫu tin nhắn nào</p>
              <p className="text-xs text-slate-500 mt-1">Hãy bấm "Tạo Mẫu Tin Nhắn Mới" để thêm kịch bản đầu tiên!</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {templates.map((tpl) => {
                const canManage = user.role === 'ADMIN' || user.role === 'SALE';
                const isCopiedText = copiedTextId === tpl.id;
                const isCopiedImage = copiedImageId === tpl.id;

                return (
                  <div
                    key={tpl.id}
                    className="group bg-slate-900/70 hover:bg-slate-900/90 rounded-2xl border border-slate-800 hover:border-sky-500/40 shadow-xl transition-all duration-200 flex flex-col justify-between overflow-hidden"
                  >
                    {/* Header Card */}
                    <div className="p-4 border-b border-slate-800/80 bg-slate-950/30">
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex flex-wrap items-center gap-1.5">
                          <span
                            className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold border uppercase tracking-wider ${getCategoryBadgeClass(
                              tpl.category
                            )}`}
                          >
                            {tpl.category}
                          </span>

                          {tpl.isGlobal ? (
                            <span
                              className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 flex items-center gap-1"
                              title="Mẫu chung toàn Team"
                            >
                              <Globe className="w-3 h-3" /> Toàn Team
                            </span>
                          ) : (
                            <span
                              className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-slate-800 text-slate-400 border border-slate-700/60 flex items-center gap-1"
                              title="Mẫu cá nhân"
                            >
                              <UserIcon className="w-3 h-3" /> Cá nhân
                            </span>
                          )}

                          {tpl.shortcut && (
                            <span className="px-2 py-0.5 rounded bg-slate-800 text-amber-300 font-mono text-[10px] font-semibold border border-amber-500/20">
                              #{tpl.shortcut}
                            </span>
                          )}
                        </div>

                        {/* Action buttons (Edit/Delete) */}
                        {canManage && (
                          <div className="flex items-center gap-1 opacity-80 group-hover:opacity-100 transition">
                            <button
                              onClick={() => handleOpenModal(tpl)}
                              className="p-1.5 text-slate-400 hover:text-sky-300 hover:bg-slate-800 rounded-lg transition"
                              title="Chỉnh sửa mẫu"
                            >
                              <Edit2 className="w-3.5 h-3.5" />
                            </button>
                            <button
                              onClick={() => handleDeleteTemplate(tpl)}
                              className="p-1.5 text-slate-400 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition"
                              title="Xóa mẫu"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        )}
                      </div>

                      <h3 className="text-base font-bold text-white mt-2.5 line-clamp-1 group-hover:text-sky-300 transition">
                        {tpl.title}
                      </h3>
                    </div>

                    {/* Chat Bubble Body */}
                    <div className="p-4 flex-1 flex flex-col gap-3">
                      {/* Attached Image Thumbnail */}
                      {tpl.imageUrl && (
                        <div className="relative rounded-xl overflow-hidden border border-slate-700/60 bg-slate-950/60 group/img aspect-video flex items-center justify-center">
                          <img
                            src={tpl.imageUrl}
                            alt={tpl.title}
                            className="w-full h-full object-cover transition-transform duration-300 group-hover/img:scale-105"
                          />
                          <div className="absolute inset-0 bg-slate-950/50 opacity-0 group-hover/img:opacity-100 transition-opacity flex items-center justify-center gap-2">
                            <button
                              onClick={() => setPreviewImage(tpl.imageUrl!)}
                              className="px-2.5 py-1.5 rounded-lg bg-slate-900/90 hover:bg-slate-800 text-white text-xs font-semibold flex items-center gap-1 border border-slate-700 shadow"
                              title="Xem ảnh to"
                            >
                              <Maximize2 className="w-3.5 h-3.5" /> Phóng to
                            </button>
                            <button
                              onClick={() => handleCopyImage(tpl)}
                              className="px-2.5 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold flex items-center gap-1 shadow"
                              title="Copy ảnh vào clipboard"
                            >
                              <Copy className="w-3.5 h-3.5" /> Copy Ảnh
                            </button>
                          </div>
                        </div>
                      )}

                      {/* Text Message Content */}
                      <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800/80 text-xs text-slate-300 leading-relaxed font-sans whitespace-pre-line max-h-48 overflow-y-auto select-all">
                        {tpl.content}
                      </div>

                      <div className="flex items-center justify-between text-[11px] text-slate-500 pt-1">
                        <span>Đăng bởi: {tpl.createdBy?.displayName || 'Admin'}</span>
                        <span>{new Date(tpl.createdAt).toLocaleDateString('vi-VN')}</span>
                      </div>
                    </div>

                    {/* Quick Copy Action Bar */}
                    <div className="p-3 bg-slate-950/80 border-t border-slate-800/80 grid grid-cols-2 gap-2">
                      {tpl.imageUrl ? (
                        <>
                          <button
                            onClick={() => handleCopyBoth(tpl)}
                            className={`col-span-2 w-full py-2.5 px-3 rounded-xl text-xs font-bold flex items-center justify-center gap-2 transition-all shadow-md ${
                              smartStep?.id === tpl.id
                                ? smartStep.step === 1
                                  ? 'bg-gradient-to-r from-amber-500 to-orange-500 text-white shadow-amber-500/30 animate-pulse'
                                  : 'bg-emerald-500 text-white shadow-emerald-500/30'
                                : 'bg-gradient-to-r from-sky-600 via-indigo-600 to-purple-600 hover:from-sky-500 hover:to-purple-500 text-white shadow-sky-500/25'
                            }`}
                          >
                            <Sparkles className="w-4 h-4" />
                            {smartStep?.id === tpl.id
                              ? smartStep.step === 1
                                ? '1️⃣ ĐÃ COPY ẢNH! (Click tiếp để Copy Text)'
                                : '2️⃣ ĐÃ COPY TIẾP VĂN BẢN (CTRL+V)'
                              : '⚡ GỬI TRỌN BỘ (ẢNH + CHỮ SIÊU TỐC)'}
                          </button>

                          <button
                            onClick={() => handleCopyImage(tpl)}
                            className={`w-full py-1.5 px-2 rounded-lg text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-all ${
                              isCopiedImage
                                ? 'bg-emerald-500 text-white shadow-md shadow-emerald-500/30'
                                : 'bg-slate-800/80 hover:bg-slate-800 text-slate-400 hover:text-slate-200 border border-slate-700/60'
                            }`}
                          >
                            {isCopiedImage ? <Check className="w-3.5 h-3.5" /> : <ImageIcon className="w-3.5 h-3.5" />}
                            {isCopiedImage ? 'ĐÃ COPY ẢNH' : 'Chỉ Copy Ảnh'}
                          </button>

                          <button
                            onClick={() => handleCopyText(tpl)}
                            className={`w-full py-1.5 px-2 rounded-lg text-[11px] font-semibold flex items-center justify-center gap-1.5 transition-all ${
                              isCopiedText
                                ? 'bg-sky-500 text-white shadow-md shadow-sky-500/30'
                                : 'bg-slate-800/80 hover:bg-slate-800 text-slate-400 hover:text-slate-200 border border-slate-700/60'
                            }`}
                          >
                            {isCopiedText ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
                            {isCopiedText ? 'ĐÃ COPY TEXT' : 'Chỉ Copy Text'}
                          </button>
                        </>
                      ) : (
                        <button
                          onClick={() => handleCopyText(tpl)}
                          className={`col-span-2 w-full py-2.5 px-3 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-all ${
                            isCopiedText
                              ? 'bg-sky-500 text-white shadow-lg shadow-sky-500/30'
                              : 'bg-gradient-to-r from-sky-600 to-indigo-600 hover:from-sky-500 hover:to-indigo-500 text-white shadow-md shadow-sky-500/20'
                          }`}
                        >
                          {isCopiedText ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                          {isCopiedText ? 'ĐÃ SAO CHÉP VĂN BẢN VÀO CLIPBOARD' : 'SAO CHÉP VĂN BẢN (CTRL+V)'}
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Modal Create / Edit Template */}
          {showModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
              <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
                <div className="p-5 border-b border-slate-800 flex items-center justify-between bg-slate-950/40">
                  <div className="flex items-center gap-2">
                    <MessageSquareQuote className="w-5 h-5 text-sky-400" />
                    <h2 className="text-lg font-bold text-white">
                      {editingTemplate ? 'Chỉnh Sửa Mẫu Tin Nhắn' : 'Tạo Mẫu Tin Nhắn Mới'}
                    </h2>
                  </div>
                  <button
                    onClick={() => setShowModal(false)}
                    className="p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>

                <form onSubmit={handleSaveTemplate} className="p-6 space-y-4 overflow-y-auto flex-1">
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                      Tiêu đề mẫu tin nhắn <span className="text-rose-500">*</span>
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="VD: Bảng giá Tool MU Vĩnh Hằng, STK Chuyển khoản MB Bank..."
                      value={title}
                      onChange={(e) => setTitle(e.target.value)}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-sm text-white focus:outline-none focus:border-sky-500 transition"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                        Danh mục phân loại
                      </label>
                      <select
                        value={category}
                        onChange={(e) => setCategory(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-sm text-white focus:outline-none focus:border-sky-500 transition"
                      >
                        <option value="BÁO GIÁ">Báo Giá</option>
                        <option value="THANH TOÁN">Thanh Toán</option>
                        <option value="HƯỚNG DẪN">Hướng Dẫn</option>
                        <option value="CSKH">Chăm Sóc Khách</option>
                        <option value="KHÁC">Khác</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                        Mã gõ tắt (Shortcut)
                      </label>
                      <input
                        type="text"
                        placeholder="VD: bg, stk, hd..."
                        value={shortcut}
                        onChange={(e) => setShortcut(e.target.value)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-sm text-white focus:outline-none focus:border-sky-500 transition font-mono"
                      />
                    </div>
                  </div>

                  {/* Image Attachment */}
                  <div className="space-y-2">
                    <label className="block text-xs font-semibold text-slate-300">
                      Hình ảnh đính kèm (Bảng giá, QR ngân hàng, Banner...)
                    </label>

                    {imageUrl ? (
                      <div className="relative rounded-xl overflow-hidden border border-slate-700 bg-slate-950 p-2 flex items-center gap-3">
                        <img
                          src={imageUrl}
                          alt="Attached"
                          className="w-20 h-14 object-cover rounded-lg border border-slate-800 shrink-0"
                        />
                        <div className="flex-1 min-w-0">
                          <p className="text-xs text-slate-300 font-mono truncate">{imageUrl}</p>
                          <p className="text-[11px] text-emerald-400 mt-0.5">✓ Đã gắn ảnh đính kèm</p>
                        </div>
                        <button
                          type="button"
                          onClick={() => setImageUrl('')}
                          className="p-1.5 text-rose-400 hover:bg-rose-500/10 rounded-lg transition"
                          title="Xóa ảnh"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    ) : (
                      <div className="flex flex-col sm:flex-row gap-2">
                        <button
                          type="button"
                          disabled={uploadingImage}
                          onClick={() => fileInputRef.current?.click()}
                          className="flex-1 py-3 px-4 border border-dashed border-slate-700 hover:border-sky-500 rounded-xl bg-slate-950/60 hover:bg-slate-950 text-slate-400 hover:text-sky-300 text-xs flex items-center justify-center gap-2 transition"
                        >
                          <Upload className="w-4 h-4" />
                          {uploadingImage ? 'Đang tải ảnh lên...' : 'Tải ảnh từ máy tính (PNG, JPG)'}
                        </button>
                        <input
                          ref={fileInputRef}
                          type="file"
                          accept="image/*"
                          className="hidden"
                          onChange={handleFileUpload}
                        />
                      </div>
                    )}
                  </div>

                  {/* Text Content */}
                  <div>
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                      Nội dung tin nhắn <span className="text-rose-500">*</span>
                    </label>
                    <textarea
                      required
                      rows={6}
                      placeholder="Nhập nội dung kịch bản trả lời khách (hỗ trợ xuống dòng, icon emoji, thông tin giá cả...)"
                      value={content}
                      onChange={(e) => setContent(e.target.value)}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3.5 text-sm text-white focus:outline-none focus:border-sky-500 transition leading-relaxed font-sans"
                    ></textarea>
                  </div>

                  {/* Global Checkbox */}
                  <div className="flex items-center gap-3 p-3 rounded-xl bg-indigo-500/10 border border-indigo-500/20">
                    <input
                      type="checkbox"
                      id="isGlobalCheckbox"
                      checked={isGlobal}
                      onChange={(e) => setIsGlobal(e.target.checked)}
                      className="w-4 h-4 rounded text-sky-600 focus:ring-sky-500 bg-slate-900 border-slate-700 cursor-pointer"
                    />
                    <label htmlFor="isGlobalCheckbox" className="text-xs text-indigo-200 cursor-pointer">
                      <strong className="text-white">Đặt làm mẫu chung cho toàn Team Sale:</strong> Tất cả nhân viên Sale đều có thể thấy và sử dụng mẫu này.
                    </label>
                  </div>

                  <div className="flex justify-end gap-3 pt-2">
                    <button
                      type="button"
                      onClick={() => setShowModal(false)}
                      className="px-4 py-2 rounded-xl text-xs font-medium text-slate-400 hover:text-white hover:bg-slate-800 transition"
                    >
                      Hủy Bỏ
                    </button>
                    <button
                      type="submit"
                      disabled={submitting}
                      className="px-5 py-2.5 gradient-button text-white text-xs font-bold rounded-xl shadow-lg shadow-sky-500/20 flex items-center gap-2 hover:scale-[1.02] transition"
                    >
                      {submitting ? 'Đang lưu...' : editingTemplate ? 'Cập Nhật Mẫu' : 'Tạo Mẫu Tin Nhắn'}
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}

          {/* Lightbox Modal */}
          {previewImage && (
            <div
              className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-in fade-in duration-200"
              onClick={() => setPreviewImage(null)}
            >
              <div className="relative max-w-4xl max-h-[90vh] flex flex-col items-center">
                <button
                  onClick={() => setPreviewImage(null)}
                  className="absolute -top-10 right-0 p-2 text-slate-300 hover:text-white rounded-full bg-slate-900/80 border border-slate-700 transition"
                  title="Đóng"
                >
                  <X className="w-5 h-5" />
                </button>
                <img
                  src={previewImage}
                  alt="Full preview"
                  className="max-h-[82vh] w-auto object-contain rounded-2xl shadow-2xl border border-slate-800"
                  onClick={(e) => e.stopPropagation()}
                />
                <div className="mt-3 flex items-center gap-3" onClick={(e) => e.stopPropagation()}>
                  <a
                    href={previewImage}
                    target="_blank"
                    rel="noreferrer"
                    className="px-4 py-2 rounded-xl bg-slate-900/90 hover:bg-slate-800 text-xs text-slate-200 border border-slate-700 flex items-center gap-1.5 transition"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> Mở tab mới
                  </a>
                  <a
                    href={previewImage}
                    download
                    className="px-4 py-2 rounded-xl bg-sky-600 hover:bg-sky-500 text-xs text-white font-medium flex items-center gap-1.5 transition"
                  >
                    <Download className="w-3.5 h-3.5" /> Tải về máy
                  </a>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
