'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import {
  Key,
  ClipboardPaste,
  Sparkles,
  ArrowLeft,
  Send,
  Sliders,
  PackageCheck,
  CheckCircle2,
} from 'lucide-react';
import Link from 'next/link';

export default function TokenCreatePage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [packages, setPackages] = useState<any[]>([]);
  const [systemTelegrams, setSystemTelegrams] = useState<any[]>([]);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Form State
  const [deviceSnMd5, setDeviceSnMd5] = useState('');
  const [characterUid, setCharacterUid] = useState('');
  const [customerName, setCustomerName] = useState('');
  const [isTest, setIsTest] = useState(false);
  const [selectedPackageId, setSelectedPackageId] = useState('');
  const [durationDays, setDurationDays] = useState(30);
  const [price, setPrice] = useState(300000);
  const [isCustom, setIsCustom] = useState(false);
  const [subTokenType, setSubTokenType] = useState<'NONE' | 'CHARACTER' | 'DEVICE'>('NONE');
  const [parentCharacterUid, setParentCharacterUid] = useState('');
  const [parentDeviceSnMd5, setParentDeviceSnMd5] = useState('');

  // Detailed Config Parameters
  const [fovMin, setFovMin] = useState(20);
  const [fovMax, setFovMax] = useState(90);
  const [bossRefreshMin, setBossRefreshMin] = useState(1);
  const [bossRefreshMax, setBossRefreshMax] = useState(60);
  const [maxMoveSpeed, setMaxMoveSpeed] = useState(2.5);
  const [maxAttackSpeed, setMaxAttackSpeed] = useState(2.5);
  const [maxMonsterRange, setMaxMonsterRange] = useState(50);
  const [maxPickupCount, setMaxPickupCount] = useState(100);
  const [pickupDelayMin, setPickupDelayMin] = useState(100);
  const [pickupDelayMax, setPickupDelayMax] = useState(500);
  const [activeTabBasic, setActiveTabBasic] = useState(true);
  const [activeTabAdvanced, setActiveTabAdvanced] = useState(true);
  const [activeTabAutofarm, setActiveTabAutofarm] = useState(true);

  // Token-specific parameter
  const [characterReincarnation, setCharacterReincarnation] = useState(8);
  const [characterReincarnationSecondary, setCharacterReincarnationSecondary] = useState(7);

  // Selected Telegram Contacts (up to 2)
  const [selectedTelegrams, setSelectedTelegrams] = useState<string[]>(['@xoajxanh', '@legend92vn']);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      const subType = params.get('subType');
      const pUid = params.get('parentUid');
      const pSn = params.get('parentSn');
      const sn = params.get('sn');
      const uid = params.get('uid');
      const cust = params.get('cust');

      if (subType === 'device' || pSn) {
        setSubTokenType('DEVICE');
        if (pSn) setParentDeviceSnMd5(pSn);
        if (uid) setCharacterUid(uid);
      } else if (subType === 'character' || pUid) {
        setSubTokenType('CHARACTER');
        if (pUid) setParentCharacterUid(pUid);
        if (sn) setDeviceSnMd5(sn);
      } else if (sn) {
        setDeviceSnMd5(sn);
      }

      if (cust) {
        try {
          setCustomerName(decodeURIComponent(cust));
        } catch {
          setCustomerName(cust);
        }
      }
    }
  }, []);

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
          loadPackages();
          loadSystemTelegrams();
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const loadPackages = async () => {
    try {
      const res = await fetch('/api/packages');
      if (res.ok) {
        const json = await res.json();
        setPackages(json.packages || []);
        if (json.packages && json.packages.length > 0) {
          applyPackagePreset(json.packages[0]);
        }
      }
    } catch (err) {
      console.error(err);
    }
  };

  const loadSystemTelegrams = async () => {
    try {
      const res = await fetch('/api/telegrams');
      if (res.ok) {
        const json = await res.json();
        const list = json.telegrams || [];
        setSystemTelegrams(list);
        if (list.length >= 2) {
          setSelectedTelegrams([list[0].username, list[1].username]);
        } else if (list.length === 1) {
          setSelectedTelegrams([list[0].username]);
        }
      }
    } catch (err) {
      console.error(err);
    }
  };

  const applyPackagePreset = (pkg: any) => {
    setSelectedPackageId(pkg.id);
    setDurationDays(pkg.durationDays);
    setPrice(pkg.price);
    setFovMin(pkg.fovMin ?? 20);
    setFovMax(pkg.fovMax ?? 90);
    setBossRefreshMin(pkg.bossRefreshMin ?? 1);
    setBossRefreshMax(pkg.bossRefreshMax ?? 60);
    setMaxMoveSpeed(pkg.maxMoveSpeed ?? 2.5);
    setMaxAttackSpeed(pkg.maxAttackSpeed ?? 2.5);
    setMaxMonsterRange(pkg.maxMonsterRange ?? 50);
    setMaxPickupCount(pkg.maxPickupCount ?? 100);
    setPickupDelayMin(pkg.pickupDelayMin ?? 100);
    setPickupDelayMax(pkg.pickupDelayMax ?? 500);
    setActiveTabBasic(pkg.activeTabBasic ?? true);
    setActiveTabAdvanced(pkg.activeTabAdvanced ?? true);
    setActiveTabAutofarm(pkg.activeTabAutofarm ?? true);
    setIsCustom(false);
  };

  const handleTelegramToggle = (uname: string) => {
    if (selectedTelegrams.includes(uname)) {
      setSelectedTelegrams(selectedTelegrams.filter((u) => u !== uname));
    } else {
      if (selectedTelegrams.length >= 2) {
        setToast({ message: 'Chỉ được chọn tối đa 2 Telegram Admin Contact!', type: 'error' });
        return;
      }
      setSelectedTelegrams([...selectedTelegrams, uname]);
    }
  };

  const handlePasteClipboard = async (setter: (val: string) => void, fieldName: string) => {
    try {
      const text = await navigator.clipboard.readText();
      if (text && text.trim() !== '') {
        setter(text.trim());
        setToast({ message: `Đã dán ${fieldName} từ Clipboard!`, type: 'success' });
      } else {
        setToast({ message: 'Clipboard trống!', type: 'error' });
      }
    } catch (err) {
      setToast({ message: 'Không thể đọc Clipboard (Quyền trình duyệt)', type: 'error' });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!deviceSnMd5.trim() || !characterUid.trim()) {
      setToast({ message: 'Vui lòng nhập Mã thiết bị MD5 và UID Nhân vật', type: 'error' });
      return;
    }
    setSubmitting(true);
    try {
      if (subTokenType === 'CHARACTER') {
        if (!parentCharacterUid.trim()) {
          throw new Error('Vui lòng nhập UID Token Cha (Nhân vật chính)!');
        }
      } else if (subTokenType === 'DEVICE') {
        if (!parentDeviceSnMd5.trim()) {
          throw new Error('Vui lòng nhập Mã thiết bị (MD5) của Token Máy Chính!');
        }
      }

      const payload = {
        deviceSnMd5: deviceSnMd5.trim(),
        characterUid: characterUid.trim(),
        customerName: customerName.trim(),
        isTest,
        packageId: isCustom ? null : selectedPackageId,
        durationDays: Number(durationDays),
        fovMin: Number(fovMin),
        fovMax: Number(fovMax),
        bossRefreshMin: Number(bossRefreshMin),
        bossRefreshMax: Number(bossRefreshMax),
        maxMoveSpeed: Number(maxMoveSpeed),
        maxAttackSpeed: Number(maxAttackSpeed),
        maxMonsterRange: Number(maxMonsterRange),
        maxPickupCount: Number(maxPickupCount),
        pickupDelayMin: Number(pickupDelayMin),
        pickupDelayMax: Number(pickupDelayMax),
        activeTabBasic,
        activeTabAdvanced,
        activeTabAutofarm,
        characterReincarnation: Number(characterReincarnation),
        characterReincarnationSecondary: Number(characterReincarnationSecondary),
        adminTelegrams: selectedTelegrams,
        price: Number(price),
        isCustom,
        subTokenType,
        parentCharacterUid: subTokenType === 'CHARACTER' ? parentCharacterUid.trim() : null,
        parentDeviceSnMd5: subTokenType === 'DEVICE' ? parentDeviceSnMd5.trim() : null,
      };

      const res = await fetch('/api/tokens', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Lỗi khi tạo Token');
      }

      setToast({ message: 'Khởi tạo và kích hoạt Token thành công!', type: 'success' });
      setTimeout(() => {
        router.push(`/tokens/${json.token.id}`);
      }, 1000);
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

        <main className="p-6 md:p-8 space-y-6 flex-1 overflow-y-auto">
          {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

          {/* Header */}
          <div className="flex items-center gap-4">
            <Link
              href="/tokens"
              className="p-2.5 rounded-xl bg-slate-900 border border-slate-800 text-slate-400 hover:text-white transition"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                Kích Hoạt Token Mới
                <Sparkles className="w-5 h-5 text-cyan-400" />
              </h1>
              <p className="text-xs text-slate-400">
                Nhập thông tin khách hàng, chọn gói cước VIP để auto-fill cấu hình hoặc tích chọn Tùy chỉnh (Custom)
              </p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Form Left (2 Columns) */}
            <div className="lg:col-span-2 space-y-6">
              {/* Customer Info Card */}
              <div className="glass-card p-6 rounded-2xl space-y-4">
                <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-cyan-400 flex items-center gap-2">
                  <Key className="w-4 h-4" /> 1. Thông Tin Khách Hàng & Chuyển Nhân Vật
                </h3>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  {/* Khách Hàng */}
                  <div className="flex flex-col justify-end">
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      Khách Hàng (Tên/Nhân vật)
                    </label>
                    <input
                      type="text"
                      value={customerName}
                      onChange={(e) => setCustomerName(e.target.value)}
                      placeholder="Ví dụ: Anh Nam / CharacterX"
                      className="w-full h-10 px-3 bg-slate-900/90 border border-slate-800 rounded-xl text-xs text-amber-300 font-semibold placeholder-slate-600 focus:outline-none focus:border-cyan-500 transition"
                    />
                  </div>

                  {/* Device MD5 */}
                  <div className="flex flex-col justify-end">
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      Mã MD5 Thiết Bị <span className="text-rose-400 ml-1">*</span>
                    </label>
                    <div className="relative flex items-center">
                      <input
                        type="text"
                        value={deviceSnMd5}
                        onChange={(e) => setDeviceSnMd5(e.target.value)}
                        placeholder="Ví dụ: e10adc3949ba59abbe56e057f20f883e"
                        className="w-full h-10 pr-14 pl-3 bg-slate-900/90 border border-slate-800 rounded-xl text-xs font-mono text-cyan-300 placeholder-slate-600 focus:outline-none focus:border-cyan-500 transition"
                        required
                      />
                      <button
                        type="button"
                        onClick={() => handlePasteClipboard(setDeviceSnMd5, 'Mã MD5')}
                        className="absolute right-1.5 p-1.5 bg-cyan-600/20 hover:bg-cyan-600/30 text-cyan-400 rounded-lg text-xs flex items-center gap-1 font-medium transition"
                        title="Dán nhanh từ Clipboard"
                      >
                        <ClipboardPaste className="w-3.5 h-3.5" />
                        <span className="hidden sm:inline">Paste</span>
                      </button>
                    </div>
                  </div>

                  {/* Character UID */}
                  <div className="flex flex-col justify-end">
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      UID Nhân Vật <span className="text-rose-400 ml-1">*</span>
                    </label>
                    <div className="relative flex items-center">
                      <input
                        type="text"
                        value={characterUid}
                        onChange={(e) => setCharacterUid(e.target.value)}
                        placeholder="Ví dụ: 1008592"
                        className="w-full h-10 pr-14 pl-3 bg-slate-900/90 border border-slate-800 rounded-xl text-xs font-mono text-slate-100 placeholder-slate-600 focus:outline-none focus:border-cyan-500 transition"
                        required
                      />
                      <button
                        type="button"
                        onClick={() => handlePasteClipboard(setCharacterUid, 'UID Nhân vật')}
                        className="absolute right-1.5 p-1.5 bg-cyan-600/20 hover:bg-cyan-600/30 text-cyan-400 rounded-lg text-xs flex items-center gap-1 font-medium transition"
                        title="Dán nhanh từ Clipboard"
                      >
                        <ClipboardPaste className="w-3.5 h-3.5" />
                        <span className="hidden sm:inline">Paste</span>
                      </button>
                    </div>
                  </div>

                  {/* Character Reincarnation Primary & Secondary */}
                  <div className="flex flex-col justify-end">
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end justify-between">
                      <span>Chuyển Nhân Vật</span>
                      <span className="text-[10px] text-cyan-400 font-mono">C{characterReincarnation} & C{characterReincarnationSecondary}</span>
                    </label>
                    <div className="grid grid-cols-2 gap-1.5">
                      <select
                        value={characterReincarnation}
                        onChange={(e) => {
                          const prim = Number(e.target.value);
                          setCharacterReincarnation(prim);
                          setCharacterReincarnationSecondary(prim > 1 ? prim - 1 : 1);
                        }}
                        className="w-full h-10 px-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-cyan-300 font-semibold"
                        title="Chuyển chính (Primary)"
                      >
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((lvl) => (
                          <option key={lvl} value={lvl}>
                            Chính: C{lvl}
                          </option>
                        ))}
                      </select>
                      <select
                        value={characterReincarnationSecondary}
                        onChange={(e) => setCharacterReincarnationSecondary(Number(e.target.value))}
                        className="w-full h-10 px-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-amber-300 font-semibold"
                        title="Chuyển phụ (Secondary)"
                      >
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((lvl) => (
                          <option key={lvl} value={lvl}>
                            Phụ: C{lvl}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                </div>

                {/* Test Token Checkbox */}
                <div className="pt-3 border-t border-slate-800/80">
                  <label className="flex items-center gap-2 cursor-pointer w-max">
                    <input
                      type="checkbox"
                      checked={isTest}
                      onChange={(e) => setIsTest(e.target.checked)}
                      className="rounded bg-slate-900 border-slate-800 text-purple-500 focus:ring-purple-500"
                    />
                    <span className="text-xs font-bold text-purple-300 flex items-center gap-1.5">
                      <span className="px-1.5 py-0.5 rounded text-[10px] bg-purple-500/20 text-purple-300 border border-purple-500/40">TEST</span>
                      Đánh dấu Token Test (Không tính vào thống kê Doanh thu & Token Dashboard)
                    </span>
                  </label>
                </div>

                {/* ========================================================================= */}
                {/* [MOD FEATURE]: TÙY CHỌN TOKEN NHÂN VẬT PHỤ & TOKEN MÁY PHỤ */}
                {/* ========================================================================= */}
                <div className="pt-3 border-t border-slate-800/80 space-y-4">
                  {/* Option 1: Token Nhân Vật Phụ (Cùng Máy - Khác UID) */}
                  <div className="space-y-2.5">
                    <label className="flex items-center gap-2 cursor-pointer w-max">
                      <input
                        type="checkbox"
                        checked={subTokenType === 'CHARACTER'}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSubTokenType('CHARACTER');
                            setParentDeviceSnMd5('');
                          } else {
                            setSubTokenType('NONE');
                            setParentCharacterUid('');
                          }
                        }}
                        className="rounded bg-slate-900 border-slate-800 text-indigo-500 focus:ring-indigo-500"
                      />
                      <span className="text-xs font-bold text-indigo-300 flex items-center gap-1.5">
                        <span className="px-1.5 py-0.5 rounded text-[10px] bg-indigo-500/20 text-indigo-300 border border-indigo-500/40 font-black">
                          TOKEN NV PHỤ
                        </span>
                        Gắn làm Token Nhân Vật Phụ (Cùng máy - Khác UID, kế thừa hạn dùng theo Token Cha)
                      </span>
                    </label>

                    {subTokenType === 'CHARACTER' && (
                      <div className="p-3.5 bg-indigo-950/30 border border-indigo-500/30 rounded-xl space-y-2.5">
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1">
                          <label className="text-xs font-semibold text-indigo-200 flex items-center gap-1">
                            UID Token Cha (Nhân vật chính) <span className="text-rose-400">*</span>
                          </label>
                          <span className="text-[11px] text-slate-400">
                            Phải dùng chung Mã thiết bị MD5 ở trên
                          </span>
                        </div>
                        <div className="relative flex items-center">
                          <input
                            type="text"
                            value={parentCharacterUid}
                            onChange={(e) => setParentCharacterUid(e.target.value)}
                            placeholder="Dán UID của Token Cha vào đây (Ví dụ: 1008592)..."
                            className="w-full h-10 pr-14 pl-3 bg-slate-900/90 border border-indigo-500/40 rounded-xl text-xs font-mono text-cyan-200 placeholder-slate-500 focus:outline-none focus:border-indigo-400 transition"
                            required={subTokenType === 'CHARACTER'}
                          />
                          <button
                            type="button"
                            onClick={() => handlePasteClipboard(setParentCharacterUid, 'UID Token Cha')}
                            className="absolute right-1.5 p-1.5 bg-indigo-600/30 hover:bg-indigo-600/50 text-indigo-300 rounded-lg text-xs flex items-center gap-1 font-medium transition"
                            title="Dán nhanh từ Clipboard"
                          >
                            <ClipboardPaste className="w-3.5 h-3.5" />
                            <span className="hidden sm:inline">Paste</span>
                          </button>
                        </div>
                        <p className="text-[11px] text-indigo-300/80 leading-relaxed italic">
                          💡 Token nhân vật phụ sẽ tự động Active khi Token cha còn hạn và tự hết hạn khi Token cha hết hạn (không cần nạp ngày cho token phụ).
                        </p>
                      </div>
                    )}
                  </div>

                  {/* Option 2: Token Máy Phụ (Khác Máy - Chung UID Nhân Vật) */}
                  <div className="space-y-2.5 pt-2 border-t border-slate-800/60">
                    <label className="flex items-center gap-2 cursor-pointer w-max">
                      <input
                        type="checkbox"
                        checked={subTokenType === 'DEVICE'}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setSubTokenType('DEVICE');
                            setParentCharacterUid('');
                          } else {
                            setSubTokenType('NONE');
                            setParentDeviceSnMd5('');
                          }
                        }}
                        className="rounded bg-slate-900 border-slate-800 text-sky-500 focus:ring-sky-500"
                      />
                      <span className="text-xs font-bold text-sky-300 flex items-center gap-1.5">
                        <span className="px-1.5 py-0.5 rounded text-[10px] bg-sky-500/20 text-sky-300 border border-sky-500/40 font-black">
                          TOKEN MÁY PHỤ
                        </span>
                        Gắn làm Token Máy Phụ (Khác máy - Chung UID nhân vật, kế thừa hạn dùng theo Token Máy Chính)
                      </span>
                    </label>

                    {subTokenType === 'DEVICE' && (
                      <div className="p-3.5 bg-sky-950/30 border border-sky-500/30 rounded-xl space-y-2.5">
                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1">
                          <label className="text-xs font-semibold text-sky-200 flex items-center gap-1">
                            Mã Thiết Bị (MD5) Token Máy Chính <span className="text-rose-400">*</span>
                          </label>
                          <span className="text-[11px] text-slate-400">
                            Mã máy chính đang chạy cùng UID nhân vật [{characterUid || 'chưa nhập UID'}]
                          </span>
                        </div>
                        <div className="relative flex items-center">
                          <input
                            type="text"
                            value={parentDeviceSnMd5}
                            onChange={(e) => setParentDeviceSnMd5(e.target.value)}
                            placeholder="Dán Mã MD5 của Token Máy Chính vào đây..."
                            className="w-full h-10 pr-14 pl-3 bg-slate-900/90 border border-sky-500/40 rounded-xl text-xs font-mono text-cyan-200 placeholder-slate-500 focus:outline-none focus:border-sky-400 transition"
                            required={subTokenType === 'DEVICE'}
                          />
                          <button
                            type="button"
                            onClick={() => handlePasteClipboard(setParentDeviceSnMd5, 'Mã MD5 Máy Chính')}
                            className="absolute right-1.5 p-1.5 bg-sky-600/30 hover:bg-sky-600/50 text-sky-300 rounded-lg text-xs flex items-center gap-1 font-medium transition"
                            title="Dán nhanh từ Clipboard"
                          >
                            <ClipboardPaste className="w-3.5 h-3.5" />
                            <span className="hidden sm:inline">Paste</span>
                          </button>
                        </div>
                        <p className="text-[11px] text-sky-300/80 leading-relaxed italic">
                          💡 Token máy phụ sẽ bị ăn theo thời hạn sử dụng và trạng thái Active/Expired của Token máy chính (khi máy chính hết hạn thì máy phụ cũng hết hạn).
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* VIP Package Selector Card */}
              <div className="glass-card p-6 rounded-2xl space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-indigo-400 flex items-center gap-2">
                    <PackageCheck className="w-4 h-4" /> 2. Chọn Gói Cước VIP (Tự Động Pre-select Cấu Hình)
                  </h3>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={isCustom}
                      onChange={(e) => setIsCustom(e.target.checked)}
                      className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                    />
                    <span className="text-xs font-semibold text-cyan-400">Tùy Chỉnh Config (Custom)</span>
                  </label>
                </div>

                {/* VIP Package Buttons */}
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3">
                  {packages.map((pkg) => {
                    const isSelected = !isCustom && selectedPackageId === pkg.id;
                    return (
                      <button
                        key={pkg.id}
                        type="button"
                        onClick={() => applyPackagePreset(pkg)}
                        className={`p-3 rounded-xl border text-left transition flex flex-col justify-between ${
                          isSelected
                            ? 'bg-gradient-to-br from-sky-900/50 to-indigo-900/50 border-cyan-500/70 ring-2 ring-cyan-500/60 shadow-lg shadow-cyan-500/20'
                            : 'bg-slate-900/60 border-slate-800 hover:border-slate-700'
                        }`}
                      >
                        <div>
                          <div className="text-xs font-bold text-slate-100">{pkg.name}</div>
                          <div className="text-[11px] text-cyan-400 font-semibold mt-1">
                            {pkg.durationDays} Ngày
                          </div>
                        </div>
                        <div className="text-[11px] text-emerald-400 font-bold mt-2 pt-2 border-t border-slate-800/80">
                          {pkg.price.toLocaleString('vi-VN')} đ
                        </div>
                      </button>
                    );
                  })}
                </div>

                {/* Uniformly Aligned Form Row: Duration & Price */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
                  <div className="flex flex-col justify-end">
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 min-h-[24px] flex items-end">
                      Thời hạn sử dụng (Số ngày)
                    </label>
                    <input
                      type="number"
                      step="any"
                      min="0.001"
                      value={durationDays}
                      onChange={(e) => {
                        setDurationDays(Number(e.target.value));
                        setIsCustom(true);
                      }}
                      className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-xs font-semibold text-slate-200"
                      required
                    />
                  </div>

                  <div className="flex flex-col justify-end">
                    <label className="block text-xs font-semibold text-slate-300 mb-1.5 min-h-[24px] flex items-end">
                      Giá Token (VNĐ - Thống Kê Dashboard)
                    </label>
                    <input
                      type="number"
                      value={price}
                      onChange={(e) => {
                        setPrice(Number(e.target.value));
                        setIsCustom(true);
                      }}
                      className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-xs font-bold text-emerald-400"
                      required
                    />
                  </div>
                </div>
              </div>

              {/* Advanced Config Parameters Card */}
              <div className="glass-card p-6 rounded-2xl space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-amber-400 flex items-center gap-2">
                    <Sliders className="w-4 h-4" /> 3. Thông Số Cấu Hình Chi Tiết Mod
                  </h3>
                  {!isCustom && (
                    <span className="text-[11px] font-semibold text-cyan-400 bg-cyan-500/10 px-2.5 py-1 rounded-full border border-cyan-500/20">
                      Auto Pre-selected Theo Gói VIP
                    </span>
                  )}
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 text-xs">
                  {/* FOV Min / Max */}
                  <div className="flex flex-col justify-end">
                    <label className="block font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      FOV Tối Thiểu / Tối Đa
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        value={fovMin}
                        onChange={(e) => {
                          setFovMin(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                      <input
                        type="number"
                        value={fovMax}
                        onChange={(e) => {
                          setFovMax(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                    </div>
                  </div>

                  {/* Boss Refresh Min / Max */}
                  <div className="flex flex-col justify-end">
                    <label className="block font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      Refresh Boss (Min / Max s)
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        value={bossRefreshMin}
                        onChange={(e) => {
                          setBossRefreshMin(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                      <input
                        type="number"
                        value={bossRefreshMax}
                        onChange={(e) => {
                          setBossRefreshMax(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                    </div>
                  </div>

                  {/* Move Speed & Attack Speed Max */}
                  <div className="flex flex-col justify-end">
                    <label className="block font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      Tốc Chạy Max / Tốc Đánh Max
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        step="0.1"
                        value={maxMoveSpeed}
                        onChange={(e) => {
                          setMaxMoveSpeed(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                      <input
                        type="number"
                        step="0.1"
                        value={maxAttackSpeed}
                        onChange={(e) => {
                          setMaxAttackSpeed(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                    </div>
                  </div>

                  {/* Monster Range & Pickup Count */}
                  <div className="flex flex-col justify-end">
                    <label className="block font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      Phạm Vi Quái / Giới Hạn Nhặt
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        value={maxMonsterRange}
                        onChange={(e) => {
                          setMaxMonsterRange(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                      <input
                        type="number"
                        value={maxPickupCount}
                        onChange={(e) => {
                          setMaxPickupCount(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                    </div>
                  </div>

                  {/* Pickup Delay Min & Max (ms) */}
                  <div className="flex flex-col justify-end">
                    <label className="block font-semibold text-slate-300 mb-1.5 min-h-[20px] flex items-end">
                      Delay Nhặt Đồ Min / Max (ms)
                    </label>
                    <div className="flex gap-2">
                      <input
                        type="number"
                        value={pickupDelayMin}
                        onChange={(e) => {
                          setPickupDelayMin(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-amber-300 font-semibold"
                      />
                      <input
                        type="number"
                        value={pickupDelayMax}
                        onChange={(e) => {
                          setPickupDelayMax(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-amber-300 font-semibold"
                      />
                    </div>
                  </div>
                </div>

                {/* System Telegram Contacts Selector (Up to 2) */}
                <div className="pt-4 border-t border-slate-800 space-y-2">
                  <label className="block text-xs font-semibold text-slate-300">
                    Chọn Admin Telegram CSKH Hiển Thị Cho Khách (Tối Đa 2 Tài Khoản Trong Danh Sách):
                  </label>
                  <div className="flex flex-wrap gap-3">
                    {systemTelegrams.map((contact) => {
                      const isChecked = selectedTelegrams.includes(contact.username);
                      return (
                        <button
                          key={contact.id}
                          type="button"
                          onClick={() => handleTelegramToggle(contact.username)}
                          className={`px-3 py-2 rounded-xl text-xs font-semibold border flex items-center gap-2 transition ${
                            isChecked
                              ? 'bg-cyan-500/20 text-cyan-300 border-cyan-500/60 shadow-sm'
                              : 'bg-slate-900/60 text-slate-400 border-slate-800 hover:border-slate-700'
                          }`}
                        >
                          <Send className="w-3.5 h-3.5 text-cyan-400" />
                          <span>{contact.name} ({contact.username})</span>
                          {isChecked && <span className="text-cyan-400 font-bold">✓</span>}
                        </button>
                      );
                    })}

                    {systemTelegrams.length === 0 && (
                      <span className="text-xs text-slate-500 italic">
                        Chưa có Telegram contact nào. <Link href="/telegrams" className="text-cyan-400 underline">Thêm tại đây</Link>
                      </span>
                    )}
                  </div>
                </div>

                {/* Active Tabs Toggles */}
                <div className="pt-3 border-t border-slate-800 flex flex-wrap gap-6 text-xs font-semibold">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={activeTabBasic}
                      onChange={(e) => {
                        setActiveTabBasic(e.target.checked);
                        setIsCustom(true);
                      }}
                      className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                    />
                    <span className="text-slate-200">Active Tab Cơ Bản</span>
                  </label>

                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={activeTabAdvanced}
                      onChange={(e) => {
                        setActiveTabAdvanced(e.target.checked);
                        setIsCustom(true);
                      }}
                      className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                    />
                    <span className="text-slate-200">Active Tab Nâng Cao</span>
                  </label>

                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={activeTabAutofarm}
                      onChange={(e) => {
                        setActiveTabAutofarm(e.target.checked);
                        setIsCustom(true);
                      }}
                      className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                    />
                    <span className="text-slate-200">Active Tab AUTO Farm</span>
                  </label>
                </div>
              </div>
            </div>

            {/* Form Right Sidebar: Action & Summary */}
            <div className="space-y-6">
              <div className="glass-card p-6 rounded-2xl space-y-5 sticky top-24">
                <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-emerald-400 flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4" /> Tổng Quan Cấp Quyền
                </h3>

                <div className="space-y-3 text-xs">
                  <div className="flex justify-between py-1.5 border-b border-slate-800">
                    <span className="text-slate-400">Khách Hàng:</span>
                    <span className="font-semibold text-amber-300 truncate max-w-[150px]">
                      {customerName || 'Chưa nhập'}
                    </span>
                  </div>

                  <div className="flex justify-between py-1.5 border-b border-slate-800">
                    <span className="text-slate-400">Thiết bị MD5:</span>
                    <span className="font-mono text-cyan-300 font-bold truncate max-w-[150px]">
                      {deviceSnMd5 || 'Chưa nhập'}
                    </span>
                  </div>

                  <div className="flex justify-between py-1.5 border-b border-slate-800">
                    <span className="text-slate-400">UID Nhân vật:</span>
                    <span className="font-mono text-slate-200 font-bold">{characterUid || 'Chưa nhập'}</span>
                  </div>

                  <div className="flex justify-between py-1.5 border-b border-slate-800">
                    <span className="text-slate-400">Loại Token:</span>
                    <span className="font-semibold text-xs">
                      {subTokenType === 'CHARACTER' ? (
                        <span className="text-indigo-400 font-bold">
                          Token NV Phụ (UID Cha: {parentCharacterUid || '...'})
                        </span>
                      ) : subTokenType === 'DEVICE' ? (
                        <span className="text-sky-400 font-bold">
                          Token Máy Phụ (Máy chính: {parentDeviceSnMd5 ? parentDeviceSnMd5.substring(0, 10) + '...' : '...'})
                        </span>
                      ) : (
                        <span className="text-cyan-400 font-bold">Token Chính / Độc Lập</span>
                      )}
                    </span>
                  </div>

                  <div className="flex justify-between py-1.5 border-b border-slate-800">
                    <span className="text-slate-400">Chuyển Nhân Vật:</span>
                    <span className="font-semibold text-cyan-300">Chuyển {characterReincarnation} & {characterReincarnationSecondary}</span>
                  </div>

                  <div className="flex justify-between py-1.5 border-b border-slate-800">
                    <span className="text-slate-400">Telegram Admin:</span>
                    <span className="font-mono text-slate-200 text-[11px] truncate max-w-[140px]">
                      {selectedTelegrams.join(', ')}
                    </span>
                  </div>

                  <div className="flex justify-between py-1.5 border-b border-slate-800">
                    <span className="text-slate-400">Thời hạn:</span>
                    <span className="text-slate-200 font-semibold">{durationDays} Ngày</span>
                  </div>

                  <div className="flex justify-between py-2 text-sm font-bold">
                    <span className="text-slate-200">Tổng tiền:</span>
                    <span className="text-emerald-400">{price.toLocaleString('vi-VN')} đ</span>
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={submitting}
                  className="w-full h-11 gradient-button text-white font-bold rounded-xl shadow-lg shadow-cyan-500/20 flex items-center justify-center gap-2 hover:opacity-95 transition disabled:opacity-50 text-sm"
                >
                  {submitting ? (
                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                  ) : (
                    <>
                      <Send className="w-4 h-4" />
                      KÍCH HOẠT TOKEN NGAY
                    </>
                  )}
                </button>
              </div>
            </div>
          </form>
        </main>
      </div>
    </div>
  );
}
