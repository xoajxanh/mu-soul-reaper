'use client';

import React, { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import {
  Key,
  Copy,
  ExternalLink,
  ArrowLeft,
  History,
  Save,
  Send,
  User,
  PackageCheck,
  ClipboardPaste,
  Lock,
  Ban,
  Clock,
  AlertTriangle,
  Link2,
  GitFork,
  PlusCircle,
  Smartphone,
} from 'lucide-react';
import Link from 'next/link';

export default function TokenDetailPage() {
  const router = useRouter();
  const params = useParams();
  const tokenId = params.id as string;

  const [user, setUser] = useState<any>(null);
  const [token, setToken] = useState<any>(null);
  const [packages, setPackages] = useState<any[]>([]);
  const [systemTelegrams, setSystemTelegrams] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Edit State
  const [isEditing, setIsEditing] = useState(false);
  const [deviceSnMd5, setDeviceSnMd5] = useState('');
  const [characterUid, setCharacterUid] = useState('');
  const [customerName, setCustomerName] = useState('');
  const [isTest, setIsTest] = useState(false);
  const [selectedPackageId, setSelectedPackageId] = useState<string | null>(null);
  const [isCustom, setIsCustom] = useState(false);
  const [durationDays, setDurationDays] = useState(30);
  const [subTokenType, setSubTokenType] = useState<'NONE' | 'CHARACTER' | 'DEVICE'>('NONE');
  const [parentCharacterUid, setParentCharacterUid] = useState('');
  const [parentDeviceSnMd5, setParentDeviceSnMd5] = useState('');
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
  const [characterReincarnation, setCharacterReincarnation] = useState(8);
  const [characterReincarnationSecondary, setCharacterReincarnationSecondary] = useState(7);
  const [selectedTelegrams, setSelectedTelegrams] = useState<string[]>([]);
  const [price, setPrice] = useState(0);
  const [noteDetail, setNoteDetail] = useState('');
  const [updating, setUpdating] = useState(false);

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
          loadTokenDetail();
          loadPackages();
          loadSystemTelegrams();
        }
      })
      .catch(() => router.push('/login'));
  }, [router, tokenId]);

  const loadPackages = async () => {
    try {
      const res = await fetch('/api/packages');
      if (res.ok) {
        const json = await res.json();
        setPackages(json.packages || []);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const loadSystemTelegrams = async () => {
    try {
      const res = await fetch('/api/telegrams');
      if (res.ok) {
        const json = await res.json();
        setSystemTelegrams(json.telegrams || []);
      }
    } catch (e) {
      console.error(e);
    }
  };

  const loadTokenDetail = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/tokens/${tokenId}`);
      if (res.ok) {
        const json = await res.json();
        const tok = json.token;
        setToken(tok);
        if (tok) {
          setDeviceSnMd5(tok.deviceSnMd5);
          setCharacterUid(tok.characterUid);
          setCustomerName(tok.customerName || '');
          setIsTest(tok.isTest || false);
          setSelectedPackageId(tok.packageId || null);
          setIsCustom(tok.isCustom);
          setDurationDays(tok.durationDays);
          if (tok.parent) {
            const isDevSub = tok.parent.deviceSnMd5 !== tok.deviceSnMd5;
            if (isDevSub) {
              setSubTokenType('DEVICE');
              setParentDeviceSnMd5(tok.parent.deviceSnMd5);
              setParentCharacterUid('');
            } else {
              setSubTokenType('CHARACTER');
              setParentCharacterUid(tok.parent.characterUid);
              setParentDeviceSnMd5('');
            }
          } else {
            setSubTokenType('NONE');
            setParentCharacterUid('');
            setParentDeviceSnMd5('');
          }
          setFovMin(tok.fovMin);
          setFovMax(tok.fovMax);
          setBossRefreshMin(tok.bossRefreshMin);
          setBossRefreshMax(tok.bossRefreshMax);
          setMaxMoveSpeed(tok.maxMoveSpeed);
          setMaxAttackSpeed(tok.maxAttackSpeed);
          setMaxMonsterRange(tok.maxMonsterRange);
          setMaxPickupCount(tok.maxPickupCount);
          setPickupDelayMin(tok.pickupDelayMin ?? 100);
          setPickupDelayMax(tok.pickupDelayMax ?? 500);
          setActiveTabBasic(tok.activeTabBasic);
          setActiveTabAdvanced(tok.activeTabAdvanced);
          setActiveTabAutofarm(tok.activeTabAutofarm);
          setCharacterReincarnation(tok.characterReincarnation);
          setCharacterReincarnationSecondary(tok.characterReincarnationSecondary ?? (tok.characterReincarnation > 1 ? tok.characterReincarnation - 1 : 1));
          setPrice(tok.price);

          let teleList: string[] = [];
          if (tok.adminTelegrams) {
            try {
              teleList = JSON.parse(tok.adminTelegrams);
            } catch {
              teleList = ['@xoajxanh', '@legend92vn'];
            }
          }
          setSelectedTelegrams(teleList);
        }
      } else {
        setToast({ message: 'Không tìm thấy Token', type: 'error' });
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
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
    setToast({ message: `Đã chọn gói [${pkg.name}] thành công!`, type: 'success' });
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

  const handleCopyText = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setToast({ message: `Đã copy ${label} vào Clipboard!`, type: 'success' });
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

  const handleUpdateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!deviceSnMd5.trim() || !characterUid.trim()) {
      setToast({ message: 'Vui lòng nhập Mã MD5 thiết bị và UID Nhân vật!', type: 'error' });
      return;
    }

    if (subTokenType === 'CHARACTER' && !parentCharacterUid.trim()) {
      setToast({ message: 'Vui lòng nhập UID Token Cha cho Token nhân vật phụ!', type: 'error' });
      return;
    }

    if (subTokenType === 'DEVICE' && !parentDeviceSnMd5.trim()) {
      setToast({ message: 'Vui lòng nhập Mã thiết bị (MD5) Token máy chính cho Token máy phụ!', type: 'error' });
      return;
    }

    const isExp = token?.expireAt ? new Date(token.expireAt) < new Date() : false;
    const isDel = Boolean(token?.isDeleted);
    const userCanEdit = user?.role === 'ADMIN' ? !isDel : (!isExp && !isDel);
    if (!userCanEdit) {
      setToast({ message: 'Token này đã hết hạn hoặc bị khóa. Bạn không có quyền chỉnh sửa!', type: 'error' });
      return;
    }

    setUpdating(true);

    try {
      const payload = {
        deviceSnMd5: deviceSnMd5.trim(),
        characterUid: characterUid.trim(),
        customerName: customerName.trim() || null,
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
        noteDetail: noteDetail.trim() || 'Cập nhật thông số token',
        subTokenType,
        parentCharacterUid: subTokenType === 'CHARACTER' ? parentCharacterUid.trim() : '',
        parentDeviceSnMd5: subTokenType === 'DEVICE' ? parentDeviceSnMd5.trim() : '',
      };

      const res = await fetch(`/api/tokens/${tokenId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Lỗi khi cập nhật Token');
      }

      setToast({ message: 'Cập nhật cấu hình Token và ghi nhận lịch sử thành công!', type: 'success' });
      setIsEditing(false);
      setNoteDetail('');
      loadTokenDetail();
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi hệ thống', type: 'error' });
    } finally {
      setUpdating(false);
    }
  };

  if (loading || !user || !token) {
    return (
      <div className="min-h-screen bg-[#0b0f19] flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-cyan-500/20 border-t-cyan-500 rounded-full animate-spin"></div>
      </div>
    );
  }

  const now = new Date();
  const isExpired = new Date(token.expireAt) < now;
  const isSale = user.role === 'SALE';
  const isDeleted = Boolean(token.isDeleted);
  // Sale is locked from editing when expired or deleted. Admin can edit/extend expired tokens.
  const canEdit = user.role === 'ADMIN' ? !isDeleted : (!isExpired && !isDeleted);

  const apiUrl = `${typeof window !== 'undefined' ? window.location.origin : ''}/api/v1/config?sn=${token.deviceSnMd5}&uid=${token.characterUid}`;
  const packageName = token.vipPackage?.name || (token.isCustom ? 'Tùy Chỉnh (Custom)' : 'Gói Mặc Định');

  return (
    <div className="flex min-h-screen bg-[#0b0f19]">
      <Sidebar userRole={user.role} />

      <div className="flex-1 flex flex-col min-w-0">
        <Navbar user={user} />

        <main className="p-6 md:p-8 space-y-6 flex-1 overflow-y-auto">
          {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}

          {/* Header */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Link
                href="/tokens"
                className="p-2.5 rounded-xl bg-slate-900 border border-slate-800 text-slate-400 hover:text-white transition"
              >
                <ArrowLeft className="w-5 h-5" />
              </Link>
              <div>
                <div className="flex items-center gap-3">
                  <h1 className="text-2xl font-bold text-white font-mono">{token.deviceSnMd5}</h1>
                  {token.isDeleted ? (
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-950/80 text-rose-300 border border-rose-500/40 flex items-center gap-1">
                      <Ban className="w-3 h-3" /> ĐÃ XÓA (SALE)
                    </span>
                  ) : isExpired ? (
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20 flex items-center gap-1">
                      <Clock className="w-3 h-3" /> ĐÃ HẾT HẠN
                    </span>
                  ) : (
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                      HOẠT ĐỘNG
                    </span>
                  )}
                  <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                    {packageName}
                  </span>
                  {token.isTest && (
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-black bg-purple-500/20 text-purple-300 border border-purple-500/40 tracking-wider">
                      [TEST]
                    </span>
                  )}
                </div>
                <p className="text-xs text-slate-400 mt-1">
                  Khách hàng: <span className="font-semibold text-amber-300">{token.customerName || 'Chưa nhập'}</span> | UID Nhân vật: <span className="font-mono text-cyan-300 font-bold">{token.characterUid}</span> | Tạo bởi: {token.createdBy?.displayName}
                </p>
              </div>
            </div>

            {canEdit ? (
              <button
                onClick={() => setIsEditing(!isEditing)}
                className={`px-4 py-2 border rounded-xl text-xs font-semibold transition ${
                  isEditing
                    ? 'bg-rose-500/20 border-rose-500/40 text-rose-300 hover:bg-rose-500/30'
                    : 'bg-slate-800 hover:bg-slate-700 border-slate-700 text-slate-200'
                }`}
              >
                {isEditing ? 'Hủy Sửa' : 'Chỉnh Sửa Config'}
              </button>
            ) : isExpired && isSale ? (
              <div
                className="px-3.5 py-2 bg-rose-500/10 border border-rose-500/30 text-rose-300 rounded-xl text-xs font-semibold flex items-center gap-1.5 cursor-not-allowed shadow-sm"
                title="Token đã hết hạn. Quyền chỉnh sửa đã bị khóa đối với Sale."
              >
                <Lock className="w-3.5 h-3.5 text-rose-400" />
                <span>Khóa Sửa (Hết Hạn)</span>
              </div>
            ) : (
              <div
                className="px-3.5 py-2 bg-slate-800/80 border border-slate-700 text-slate-400 rounded-xl text-xs font-semibold flex items-center gap-1.5 cursor-not-allowed"
                title="Token đã bị xóa logic."
              >
                <Ban className="w-3.5 h-3.5 text-slate-500" />
                <span>Đã Xóa (Khóa Sửa)</span>
              </div>
            )}
          </div>

          {/* Sub-Token Indicator Banner */}
          {token.parent && (() => {
            const isDeviceSub = token.parent.deviceSnMd5 !== token.deviceSnMd5;
            return isDeviceSub ? (
              <div className="p-4 rounded-2xl bg-sky-950/40 border border-sky-500/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-sky-200 text-xs shadow-lg shadow-sky-950/20">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-sky-500/20 border border-sky-500/30 shrink-0 text-sky-300">
                    <Smartphone className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="font-bold text-white text-sm flex items-center gap-2">
                      TOKEN MÁY PHỤ (LIÊN KẾT THEO TOKEN MÁY CHÍNH)
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-sky-500/20 text-sky-300 border border-sky-500/40 font-black">
                        MÁY PHỤ
                      </span>
                    </div>
                    <p className="text-slate-300 mt-0.5">
                      Token này kế thừa trạng thái & hạn dùng từ Token Máy Chính (Mã MD5: <span className="font-mono text-cyan-300 font-bold">{token.parent.deviceSnMd5}</span> - Hết hạn: <span className="text-amber-300 font-semibold">{new Date(token.parent.expireAt).toLocaleDateString('vi-VN')}</span>). Khi Token máy chính gia hạn, token máy phụ này sẽ tự động được sử dụng tiếp.
                    </p>
                  </div>
                </div>
                <Link
                  href={`/tokens/${token.parent.id}`}
                  className="px-4 py-2 bg-sky-600 hover:bg-sky-500 text-white font-semibold rounded-xl flex items-center gap-1.5 self-start sm:self-auto transition shadow-sm whitespace-nowrap"
                >
                  <ExternalLink className="w-3.5 h-3.5" /> Xem Token Máy Chính
                </Link>
              </div>
            ) : (
              <div className="p-4 rounded-2xl bg-indigo-950/40 border border-indigo-500/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-indigo-200 text-xs shadow-lg shadow-indigo-950/20">
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-xl bg-indigo-500/20 border border-indigo-500/30 shrink-0 text-indigo-300">
                    <Link2 className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="font-bold text-white text-sm flex items-center gap-2">
                      TOKEN NHÂN VẬT PHỤ (LIÊN KẾT THEO TOKEN CHA)
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/40 font-black">
                        NV PHỤ
                      </span>
                    </div>
                    <p className="text-slate-300 mt-0.5">
                      Token này kế thừa trạng thái & hạn dùng từ Token Cha (UID: <span className="font-mono text-cyan-300 font-bold">{token.parent.characterUid}</span> - Hết hạn: <span className="text-amber-300 font-semibold">{new Date(token.parent.expireAt).toLocaleDateString('vi-VN')}</span>). Khi Token cha gia hạn, token phụ này sẽ tự động được sử dụng tiếp.
                    </p>
                  </div>
                </div>
                <Link
                  href={`/tokens/${token.parent.id}`}
                  className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold rounded-xl flex items-center gap-1.5 self-start sm:self-auto transition shadow-sm whitespace-nowrap"
                >
                  <ExternalLink className="w-3.5 h-3.5" /> Xem Token Cha
                </Link>
              </div>
            );
          })()}

          {/* Expiration Alert Banner */}
          {isExpired && !isDeleted && (
            <div className="p-4 rounded-2xl bg-rose-950/40 border border-rose-500/30 flex items-start sm:items-center justify-between gap-3 text-rose-300 text-xs">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-xl bg-rose-500/20 border border-rose-500/30 shrink-0">
                  <Clock className="w-5 h-5 text-rose-400" />
                </div>
                <div>
                  <div className="font-bold text-rose-200 text-sm flex items-center gap-1.5">
                    TOKEN ĐÃ HẾT HẠN SỬ DỤNG
                    <span className="text-[11px] font-normal text-rose-300/80">({new Date(token.expireAt).toLocaleString('vi-VN')})</span>
                  </div>
                  <p className="text-slate-300 mt-0.5">
                    {isSale ? (
                      <span className="text-rose-300/90 font-medium">
                        🔒 Giao diện chỉnh sửa đã bị khóa đối với nhân viên Sale. Khách hàng cần liên hệ Admin để gia hạn hoặc kích hoạt gói mới.
                      </span>
                    ) : (
                      <span className="text-slate-300 font-medium">
                        Tài khoản Quản trị viên (Admin) có thể bấm <strong className="text-cyan-300">&quot;Chỉnh Sửa Config&quot;</strong> để gia hạn thêm ngày hoặc cập nhật lại thông số cho khách hàng.
                      </span>
                    )}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Deletion Alert Banner */}
          {isDeleted && (
            <div className="p-4 rounded-2xl bg-rose-950/50 border border-rose-500/40 flex items-start sm:items-center justify-between gap-3 text-rose-200 text-xs">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-xl bg-rose-500/20 border border-rose-500/40 shrink-0">
                  <Ban className="w-5 h-5 text-rose-400" />
                </div>
                <div>
                  <div className="font-bold text-rose-200 text-sm">
                    TOKEN ĐÃ BỊ XÓA LOGIC (HỦY KÍCH HOẠT)
                  </div>
                  <p className="text-slate-300 mt-0.5">
                    Token này đã bị hủy kích hoạt trên Client Mod và không thể chỉnh sửa.
                    {user.role === 'ADMIN' && ' Admin có thể bấm Khôi phục ở danh sách Token.'}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Top Encrypted Token Copy Card (ADMIN Only) */}
          {user?.role === 'ADMIN' && (
            <div className="glass-card p-6 rounded-2xl space-y-4">
              <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-cyan-400 flex items-center gap-2">
                <Key className="w-4 h-4" /> Chuỗi Token Mã Hóa (Gửi cho Khách hoặc Mod tự kéo API)
              </h3>

              <div className="p-3 bg-slate-900/90 border border-slate-800 rounded-xl flex items-center justify-between gap-3">
                <code className="text-xs font-mono text-cyan-300 break-all line-clamp-2">
                  {token.encryptedToken}
                </code>
                <button
                  onClick={() => handleCopyText(token.encryptedToken, 'Token mã hóa')}
                  className="px-3 py-2 bg-cyan-600/20 hover:bg-cyan-600/30 text-cyan-400 rounded-lg text-xs font-semibold flex items-center gap-1 shrink-0 transition"
                >
                  <Copy className="w-3.5 h-3.5" /> Copy Token
                </button>
              </div>

              <div className="p-3 bg-slate-900/90 border border-slate-800 rounded-xl flex items-center justify-between gap-3">
                <code className="text-xs font-mono text-indigo-300 break-all line-clamp-1">
                  {apiUrl}
                </code>
                <button
                  onClick={() => handleCopyText(apiUrl, 'API Endpoint URL')}
                  className="px-3 py-2 bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-400 rounded-lg text-xs font-semibold flex items-center gap-1 shrink-0 transition"
                >
                  <ExternalLink className="w-3.5 h-3.5" /> Copy API URL
                </button>
              </div>
            </div>
          )}

          {/* Main Grid: Details / Edit Form & Audit Notes Timeline */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Config Parameter Card */}
            <div className="lg:col-span-2 space-y-6">
              {isEditing && canEdit ? (
                <form onSubmit={handleUpdateSubmit} className="glass-card p-6 rounded-2xl space-y-5">
                  <div className="flex items-center justify-between">
                    <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-amber-400">
                      Cập Nhật Thông Số Cấu Hình Token
                    </h3>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={isCustom}
                        onChange={(e) => setIsCustom(e.target.checked)}
                        className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                      />
                      <span className="text-xs font-semibold text-cyan-400">Tùy Chỉnh (Custom)</span>
                    </label>
                  </div>

                  {/* Section 1: Edit MD5 & Character UID & Customer Name */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs p-4 bg-slate-900/70 border border-slate-800 rounded-xl">
                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Khách Hàng (Tên/Nhân vật)</label>
                      <input
                        type="text"
                        value={customerName}
                        onChange={(e) => setCustomerName(e.target.value)}
                        placeholder="Tên khách / tên nhân vật..."
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-amber-300 font-semibold text-xs"
                      />
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1 flex items-center justify-between">
                        <span>Mã MD5 Thiết Bị <span className="text-rose-400 ml-1">*</span></span>
                        <button
                          type="button"
                          onClick={() => handlePasteClipboard(setDeviceSnMd5, 'Mã MD5')}
                          className="text-cyan-400 hover:text-cyan-300 font-normal text-[11px] flex items-center gap-1"
                        >
                          <ClipboardPaste className="w-3 h-3" /> Paste
                        </button>
                      </label>
                      <input
                        type="text"
                        value={deviceSnMd5}
                        onChange={(e) => setDeviceSnMd5(e.target.value)}
                        placeholder="Mã MD5 thiết bị..."
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-cyan-300 font-mono font-bold text-xs"
                        required
                      />
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1 flex items-center justify-between">
                        <span>UID Nhân Vật <span className="text-rose-400 ml-1">*</span></span>
                        <button
                          type="button"
                          onClick={() => handlePasteClipboard(setCharacterUid, 'UID Nhân vật')}
                          className="text-cyan-400 hover:text-cyan-300 font-normal text-[11px] flex items-center gap-1"
                        >
                          <ClipboardPaste className="w-3 h-3" /> Paste
                        </button>
                      </label>
                      <input
                        type="text"
                        value={characterUid}
                        onChange={(e) => setCharacterUid(e.target.value)}
                        placeholder="UID nhân vật..."
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-100 font-mono font-bold text-xs"
                        required
                      />
                    </div>
                  </div>

                  {/* Test Token Checkbox */}
                  <div className="p-3 bg-slate-900/60 border border-slate-800 rounded-xl">
                    <label className="flex items-center gap-2 cursor-pointer w-max">
                      <input
                        type="checkbox"
                        checked={isTest}
                        onChange={(e) => setIsTest(e.target.checked)}
                        className="rounded bg-slate-900 border-slate-800 text-purple-500 focus:ring-purple-500"
                      />
                      <span className="text-xs font-bold text-purple-300 flex items-center gap-1.5">
                        <span className="px-1.5 py-0.5 rounded text-[10px] bg-purple-500/20 text-purple-300 border border-purple-500/40">TEST</span>
                        Đánh dấu Token Test [TEST] (Không tính vào thống kê Doanh thu & Token Dashboard)
                      </span>
                    </label>
                  </div>

                  {/* ========================================================================= */}
                  {/* [MOD FEATURE]: EDIT TÙY CHỌN TOKEN NHÂN VẬT PHỤ & TOKEN MÁY PHỤ */}
                  {/* ========================================================================= */}
                  <div className="p-4 bg-slate-900/70 border border-slate-800 rounded-xl space-y-4">
                    {/* Option 1: Token Nhân Vật Phụ */}
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
                          Gắn làm Token Nhân Vật Phụ (Cùng máy - Khác UID, kế thừa theo Token Cha)
                        </span>
                      </label>

                      {subTokenType === 'CHARACTER' && (
                        <div className="pt-2 border-t border-indigo-500/20 space-y-2">
                          <div className="flex items-center justify-between">
                            <label className="text-xs font-semibold text-indigo-200 flex items-center gap-1">
                              UID Token Cha (Nhân vật chính) <span className="text-rose-400">*</span>
                            </label>
                            <span className="text-[11px] text-slate-400">Phải dùng chung Mã MD5 thiết bị ở trên</span>
                          </div>
                          <div className="relative flex items-center">
                            <input
                              type="text"
                              value={parentCharacterUid}
                              onChange={(e) => setParentCharacterUid(e.target.value)}
                              placeholder="Dán UID của Token Cha vào đây..."
                              className="w-full h-10 pr-14 pl-3 bg-slate-900/90 border border-indigo-500/40 rounded-xl text-xs font-mono text-cyan-200 placeholder-slate-500 focus:outline-none focus:border-indigo-400 transition"
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
                            💡 Token nhân vật phụ sẽ hưởng theo ngày hết hạn của Token cha và tự mở lại khi cha được gia hạn.
                          </p>
                        </div>
                      )}
                    </div>

                    {/* Option 2: Token Máy Phụ */}
                    <div className="space-y-2.5 pt-3 border-t border-slate-800">
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
                          Gắn làm Token Máy Phụ (Khác máy - Chung UID nhân vật, kế thừa theo Máy Chính)
                        </span>
                      </label>

                      {subTokenType === 'DEVICE' && (
                        <div className="pt-2 border-t border-sky-500/20 space-y-2">
                          <div className="flex items-center justify-between">
                            <label className="text-xs font-semibold text-sky-200 flex items-center gap-1">
                              Mã Thiết Bị (MD5) Token Máy Chính <span className="text-rose-400">*</span>
                            </label>
                            <span className="text-[11px] text-slate-400">Mã máy chính đang chạy UID [{characterUid}]</span>
                          </div>
                          <div className="relative flex items-center">
                            <input
                              type="text"
                              value={parentDeviceSnMd5}
                              onChange={(e) => setParentDeviceSnMd5(e.target.value)}
                              placeholder="Dán Mã MD5 của Token Máy Chính vào đây..."
                              className="w-full h-10 pr-14 pl-3 bg-slate-900/90 border border-sky-500/40 rounded-xl text-xs font-mono text-cyan-200 placeholder-slate-500 focus:outline-none focus:border-sky-400 transition"
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
                            💡 Token máy phụ sẽ bị ăn theo thời hạn sử dụng và trạng thái Active/Expired của Token máy chính.
                          </p>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Change VIP Package Template Selector */}
                  <div className="space-y-2 p-4 bg-slate-900/80 border border-slate-800 rounded-xl">
                    <label className="block text-xs font-bold text-indigo-300 flex items-center gap-2">
                      <PackageCheck className="w-4 h-4" /> Chọn Lại Gói Cước VIP (Tự Động Pre-select Cấu Hình)
                    </label>
                    <div className="flex flex-wrap gap-2 pt-1">
                      {packages.map((pkg) => {
                        const isSelected = !isCustom && selectedPackageId === pkg.id;
                        return (
                          <button
                            key={pkg.id}
                            type="button"
                            onClick={() => applyPackagePreset(pkg)}
                            className={`px-3 py-2 rounded-xl text-xs font-semibold border transition ${
                              isSelected
                                ? 'bg-indigo-600/30 text-white border-cyan-400 ring-1 ring-cyan-400'
                                : 'bg-slate-900 text-slate-300 border-slate-800 hover:border-slate-700'
                            }`}
                          >
                            {pkg.name} ({pkg.durationDays}d - {pkg.price.toLocaleString('vi-VN')}đ)
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Thời Hạn Sử Dụng (Ngày)</label>
                      <input
                        type="number"
                        step="any"
                        min="0.001"
                        value={durationDays}
                        onChange={(e) => {
                          setDurationDays(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        required
                      />
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Giá Tiền (VNĐ)</label>
                      <input
                        type="number"
                        value={price}
                        onChange={(e) => {
                          setPrice(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-emerald-400 font-semibold"
                        required
                      />
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">FOV Min / Max</label>
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

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Tốc Chạy Max / Tốc Đánh Max</label>
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

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Phạm Vi / Số Nhặt Max</label>
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

                    {/* Separated Delay Nhặt Min & Delay Nhặt Max labels & inputs */}
                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Delay Nhặt Tối Thiểu (ms)</label>
                      <input
                        type="number"
                        value={pickupDelayMin}
                        onChange={(e) => {
                          setPickupDelayMin(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        placeholder="Ví dụ: 100"
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-amber-300 font-semibold"
                      />
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Delay Nhặt Tối Đa (ms)</label>
                      <input
                        type="number"
                        value={pickupDelayMax}
                        onChange={(e) => {
                          setPickupDelayMax(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        placeholder="Ví dụ: 500"
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-amber-300 font-semibold"
                      />
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Chuyển Chính (Primary)</label>
                      <select
                        value={characterReincarnation}
                        onChange={(e) => {
                          const prim = Number(e.target.value);
                          setCharacterReincarnation(prim);
                          setCharacterReincarnationSecondary(prim > 1 ? prim - 1 : 1);
                          setIsCustom(true);
                        }}
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-cyan-300 font-semibold"
                      >
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((lvl) => (
                          <option key={lvl} value={lvl}>
                            Chuyển {lvl}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1">Chuyển Phụ (Secondary)</label>
                      <select
                        value={characterReincarnationSecondary}
                        onChange={(e) => {
                          setCharacterReincarnationSecondary(Number(e.target.value));
                          setIsCustom(true);
                        }}
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-cyan-400 font-semibold"
                      >
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map((lvl) => (
                          <option key={lvl} value={lvl}>
                            Chuyển {lvl}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* Active Tabs Toggles in Edit Form */}
                    <div className="sm:col-span-2 pt-3 border-t border-slate-800 flex flex-wrap gap-6 text-xs font-semibold">
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
                        <span className="text-slate-200">Active Tab AUTO Farm / Boss</span>
                      </label>
                    </div>

                    <div className="sm:col-span-2 pt-2 border-t border-slate-800">
                      <label className="block font-semibold text-slate-300 mb-1">Chọn Admin Telegram Contact (Tối đa 2):</label>
                      <div className="flex flex-wrap gap-2">
                        {systemTelegrams.map((contact) => {
                          const isChecked = selectedTelegrams.includes(contact.username);
                          return (
                            <button
                              key={contact.id}
                              type="button"
                              onClick={() => handleTelegramToggle(contact.username)}
                              className={`px-3 py-1.5 rounded-lg text-xs font-semibold border flex items-center gap-1.5 transition ${
                                isChecked
                                  ? 'bg-cyan-500/20 text-cyan-300 border-cyan-500/60'
                                  : 'bg-slate-900/60 text-slate-400 border-slate-800'
                              }`}
                            >
                              <Send className="w-3 h-3 text-cyan-400" />
                              <span>{contact.name} ({contact.username})</span>
                              {isChecked && <span className="text-cyan-400 font-bold">✓</span>}
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    <div className="sm:col-span-2">
                      <label className="block font-semibold text-slate-300 mb-1">Ghi Chú Sửa (Không bắt buộc)</label>
                      <input
                        type="text"
                        value={noteDetail}
                        onChange={(e) => setNoteDetail(e.target.value)}
                        placeholder="Tùy chọn: Nhập lý do hoặc thông tin thay đổi..."
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                      />
                    </div>
                  </div>

                  <button
                    type="submit"
                    disabled={updating}
                    className="py-2.5 px-5 gradient-button text-white font-bold rounded-xl shadow-lg flex items-center gap-2 text-xs"
                  >
                    <Save className="w-4 h-4" />
                    LƯU CẤP NHẬT & GHI LOG
                  </button>
                </form>
              ) : (
                <div className="glass-card p-6 rounded-2xl space-y-4">
                  <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-slate-300">
                    Chi Tiết Cấu Hình Hiện Tại
                  </h3>

                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 text-xs">
                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Khách Hàng</span>
                      <span className="font-semibold text-amber-300 truncate block">
                        {token.customerName || <span className="text-slate-500 font-normal italic">Chưa nhập</span>}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Mã MD5 Thiết Bị</span>
                      <span className="font-mono font-bold text-cyan-300 truncate block">
                        {token.deviceSnMd5}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">UID Nhân Vật</span>
                      <span className="font-mono font-bold text-slate-100 truncate block">
                        {token.characterUid}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Loại Token</span>
                      <span className="font-bold">
                        {token.parent ? (
                          <span className="text-indigo-400 flex items-center gap-1 font-mono text-[11px]">
                            <Link2 className="w-3 h-3 text-indigo-400" /> Token Phụ (Cha: {token.parent.characterUid})
                          </span>
                        ) : token.children?.length > 0 ? (
                          <span className="text-cyan-400 flex items-center gap-1 font-semibold text-[11px]">
                            <GitFork className="w-3 h-3 text-cyan-400" /> Token Cha ({token.children.length} Phụ)
                          </span>
                        ) : (
                          <span className="text-slate-300 font-semibold text-[11px]">Token Độc Lập</span>
                        )}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Gói VIP Đang Dùng</span>
                      <span className="font-bold text-indigo-300">
                        {packageName}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Hạn Sử Dụng</span>
                      <span className="font-bold text-slate-200">
                        {token.parent ? (
                          <span className="text-indigo-300">
                            Theo Cha ({new Date(token.parent.expireAt).toLocaleDateString('vi-VN')})
                          </span>
                        ) : (
                          `${new Date(token.expireAt).toLocaleDateString('vi-VN')} (${token.durationDays}d)`
                        )}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Giá Tiền Token</span>
                      <span className="font-bold text-emerald-400">
                        {token.price.toLocaleString('vi-VN')} đ
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Reincarnation</span>
                      <span className="font-bold text-cyan-300">
                        Chuyển {token.characterReincarnation} & {token.characterReincarnationSecondary ?? (token.characterReincarnation - 1)}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Telegram Admin Contact</span>
                      <span className="font-mono font-bold text-slate-200 truncate block">
                        {selectedTelegrams.join(', ')}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">FOV Min / Max</span>
                      <span className="font-bold text-slate-200">
                        {token.fovMin} - {token.fovMax}
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Phạm Vi Quái / Số Nhặt Max</span>
                      <span className="font-bold text-slate-200">
                        {token.maxMonsterRange}m / {token.maxPickupCount} item
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Delay Nhặt Min / Max</span>
                      <span className="font-bold text-amber-300">
                        {token.pickupDelayMin ?? 100}ms - {token.pickupDelayMax ?? 500}ms
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Tốc Chạy / Đánh Max</span>
                      <span className="font-bold text-slate-200">
                        {token.maxMoveSpeed}x / {token.maxAttackSpeed}x
                      </span>
                    </div>

                    <div className="p-3 bg-slate-900/60 rounded-xl border border-slate-800">
                      <span className="text-slate-400 block text-[10px]">Tabs Kích Hoạt</span>
                      <span className="font-bold text-indigo-300">
                        {[
                          token.activeTabBasic && 'Cơ bản',
                          token.activeTabAdvanced && 'Nâng cao',
                          token.activeTabAutofarm && 'AutoFarm',
                        ]
                          .filter(Boolean)
                          .join(', ')}
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Audit Notes History Timeline */}
            <div className="glass-card p-6 rounded-2xl space-y-4 max-h-[550px] flex flex-col">
              <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-indigo-400 flex items-center gap-2 shrink-0">
                <History className="w-4 h-4" /> Lịch Sử Thay Đổi (Token Notes)
              </h3>

              <div className="space-y-3 overflow-y-auto pr-2 flex-1 max-h-[460px]">
                {token.notes?.map((note: any) => (
                  <div key={note.id} className="p-3 bg-slate-900/70 border border-slate-800 rounded-xl text-xs space-y-1.5">
                    <div className="flex items-center justify-between text-[10px] text-slate-400">
                      <span className="flex items-center gap-1 text-cyan-400 font-semibold">
                        <User className="w-3 h-3" /> {note.createdBy?.displayName}
                      </span>
                      <span>{new Date(note.createdAt).toLocaleString('vi-VN')}</span>
                    </div>
                    <p className="text-slate-200 leading-relaxed font-medium">{note.detail}</p>
                  </div>
                ))}

                {(!token.notes || token.notes.length === 0) && (
                  <div className="text-center text-slate-500 text-xs py-6 italic">
                    Chưa có ghi chú lịch sử nào
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* ========================================================================= */}
          {/* [MOD FEATURE]: DANH SÁCH TOKEN CON LIÊN KẾT (NV PHỤ & MÁY PHỤ) */}
          {/* ========================================================================= */}
          {!token.parent && (() => {
            const charChildren = token.children?.filter((c: any) => c.deviceSnMd5 === token.deviceSnMd5) || [];
            const deviceChildren = token.children?.filter((c: any) => c.deviceSnMd5 !== token.deviceSnMd5) || [];

            return (
              <div className="space-y-6">
                {/* 1. Danh Sách Token Nhân Vật Phụ (Cùng Máy) */}
                <div className="glass-card p-6 rounded-2xl space-y-4">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-800/80 pb-3">
                    <div>
                      <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-indigo-400 flex items-center gap-2">
                        <GitFork className="w-4 h-4" /> Danh Sách Token Nhân Vật Phụ ({charChildren.length})
                      </h3>
                      <p className="text-xs text-slate-400 mt-0.5">
                        Các tài khoản clone / phụ chạy trên cùng thiết bị này và hưởng thời hạn theo Token chính
                      </p>
                    </div>

                    <Link
                      href={`/tokens/create?subType=character&parentUid=${token.characterUid}&sn=${token.deviceSnMd5}&cust=${encodeURIComponent(token.customerName || '')}`}
                      className="px-3.5 py-1.5 gradient-button text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 self-start sm:self-auto hover:opacity-95 transition shadow-sm"
                    >
                      <PlusCircle className="w-3.5 h-3.5" /> + Thêm Token Nhân Vật Phụ
                    </Link>
                  </div>

                  {charChildren.length > 0 ? (
                    <div className="overflow-x-auto">
                      <table className="w-full text-left text-xs text-slate-300">
                        <thead className="bg-slate-900/80 uppercase text-slate-400 border-b border-slate-800 text-[11px] whitespace-nowrap">
                          <tr>
                            <th className="py-3 px-4">Trạng Thái</th>
                            <th className="py-3 px-4">UID Nhân Vật Phụ</th>
                            <th className="py-3 px-4">Khách Hàng</th>
                            <th className="py-3 px-4">Ngày Tạo</th>
                            <th className="py-3 px-4 text-right">Chi Tiết</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-800/60">
                          {charChildren.map((child: any) => {
                            const childActive = !child.isDeleted && !isExpired;
                            return (
                              <tr
                                key={child.id}
                                onClick={() => router.push(`/tokens/${child.id}`)}
                                className="hover:bg-slate-800/50 cursor-pointer transition"
                              >
                                <td className="py-3 px-4 whitespace-nowrap">
                                  {child.isDeleted ? (
                                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-rose-950/80 text-rose-300 border border-rose-500/40">
                                      ĐÃ XÓA
                                    </span>
                                  ) : childActive ? (
                                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                                      HOẠT ĐỘNG
                                    </span>
                                  ) : (
                                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20">
                                      HẾT HẠN (THEO CHA)
                                    </span>
                                  )}
                                  {child.isTest && (
                                    <span className="ml-1.5 px-1.5 py-0.5 rounded text-[9px] font-bold bg-purple-500/20 text-purple-300 border border-purple-500/40">
                                      TEST
                                    </span>
                                  )}
                                </td>
                                <td className="py-3 px-4 font-mono font-bold text-cyan-300">
                                  {child.characterUid}
                                </td>
                                <td className="py-3 px-4 text-slate-200">
                                  {child.customerName || <span className="text-slate-500 italic">Chưa nhập</span>}
                                </td>
                                <td className="py-3 px-4 text-slate-400">
                                  {new Date(child.createdAt).toLocaleDateString('vi-VN')}
                                </td>
                                <td className="py-3 px-4 text-right">
                                  <button
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      router.push(`/tokens/${child.id}`);
                                    }}
                                    className="px-3 py-1.5 bg-slate-800 hover:bg-cyan-600/30 text-cyan-300 rounded-lg text-xs font-semibold border border-slate-700 hover:border-cyan-500/40 transition inline-flex items-center gap-1.5"
                                  >
                                    <ExternalLink className="w-3.5 h-3.5" /> Xem Chi Tiết
                                  </button>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <div className="py-6 px-4 text-center space-y-2 bg-slate-900/40 border border-dashed border-slate-800 rounded-xl">
                      <p className="text-xs font-semibold text-slate-300">Chưa có Token Nhân Vật Phụ nào</p>
                      <p className="text-[11px] text-slate-500 max-w-md mx-auto">
                        Bấm nút &quot;+ Thêm Token Nhân Vật Phụ&quot; để cấp quyền chơi thêm nhân vật clone trên cùng thiết bị này.
                      </p>
                    </div>
                  )}
                </div>

                {/* 2. Danh Sách Token Máy Phụ (Khác Máy) */}
                <div className="glass-card p-6 rounded-2xl space-y-4">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-800/80 pb-3">
                    <div>
                      <h3 className="font-bold text-slate-100 text-sm uppercase tracking-wider text-sky-400 flex items-center gap-2">
                        <Smartphone className="w-4 h-4" /> Danh Sách Token Máy Phụ ({deviceChildren.length})
                      </h3>
                      <p className="text-xs text-slate-400 mt-0.5">
                        Các thiết bị phụ khác chạy chung UID nhân vật ({token.characterUid}) và hưởng thời hạn theo Token máy chính này
                      </p>
                    </div>

                    <Link
                      href={`/tokens/create?subType=device&parentSn=${token.deviceSnMd5}&uid=${token.characterUid}&cust=${encodeURIComponent(token.customerName || '')}`}
                      className="px-3.5 py-1.5 bg-sky-600/80 hover:bg-sky-600 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 self-start sm:self-auto hover:opacity-95 transition shadow-sm"
                    >
                      <PlusCircle className="w-3.5 h-3.5" /> + Thêm Token Máy Phụ
                    </Link>
                  </div>

                  {deviceChildren.length > 0 ? (
                    <div className="overflow-x-auto">
                      <table className="w-full text-left text-xs text-slate-300">
                        <thead className="bg-slate-900/80 uppercase text-slate-400 border-b border-slate-800 text-[11px] whitespace-nowrap">
                          <tr>
                            <th className="py-3 px-4">Trạng Thái</th>
                            <th className="py-3 px-4">Mã Thiết Bị Máy Phụ (MD5)</th>
                            <th className="py-3 px-4">UID Nhân Vật</th>
                            <th className="py-3 px-4">Khách Hàng</th>
                            <th className="py-3 px-4">Ngày Tạo</th>
                            <th className="py-3 px-4 text-right">Chi Tiết</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-800/60">
                          {deviceChildren.map((child: any) => {
                            const childActive = !child.isDeleted && !isExpired;
                            return (
                              <tr
                                key={child.id}
                                onClick={() => router.push(`/tokens/${child.id}`)}
                                className="hover:bg-slate-800/50 cursor-pointer transition"
                              >
                                <td className="py-3 px-4 whitespace-nowrap">
                                  {child.isDeleted ? (
                                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-rose-950/80 text-rose-300 border border-rose-500/40">
                                      ĐÃ XÓA
                                    </span>
                                  ) : childActive ? (
                                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-sky-500/10 text-sky-400 border border-sky-500/20">
                                      HOẠT ĐỘNG
                                    </span>
                                  ) : (
                                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20">
                                      HẾT HẠN (THEO MÁY CHÍNH)
                                    </span>
                                  )}
                                  {child.isTest && (
                                    <span className="ml-1.5 px-1.5 py-0.5 rounded text-[9px] font-bold bg-purple-500/20 text-purple-300 border border-purple-500/40">
                                      TEST
                                    </span>
                                  )}
                                </td>
                                <td className="py-3 px-4 font-mono font-bold text-sky-300">
                                  {child.deviceSnMd5}
                                </td>
                                <td className="py-3 px-4 font-mono text-slate-200">
                                  {child.characterUid}
                                </td>
                                <td className="py-3 px-4 text-slate-200">
                                  {child.customerName || <span className="text-slate-500 italic">Chưa nhập</span>}
                                </td>
                                <td className="py-3 px-4 text-slate-400">
                                  {new Date(child.createdAt).toLocaleDateString('vi-VN')}
                                </td>
                                <td className="py-3 px-4 text-right">
                                  <button
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      router.push(`/tokens/${child.id}`);
                                    }}
                                    className="px-3 py-1.5 bg-slate-800 hover:bg-sky-600/30 text-sky-300 rounded-lg text-xs font-semibold border border-slate-700 hover:border-sky-500/40 transition inline-flex items-center gap-1.5"
                                  >
                                    <ExternalLink className="w-3.5 h-3.5" /> Xem Chi Tiết
                                  </button>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  ) : (
                    <div className="py-6 px-4 text-center space-y-2 bg-slate-900/40 border border-dashed border-slate-800 rounded-xl">
                      <p className="text-xs font-semibold text-slate-300">Chưa có Token Máy Phụ nào</p>
                      <p className="text-[11px] text-slate-500 max-w-md mx-auto">
                        Bấm nút &quot;+ Thêm Token Máy Phụ&quot; để cấp token cho thiết bị thứ 2 chạy cùng UID nhân vật này.
                      </p>
                    </div>
                  )}
                </div>
              </div>
            );
          })()}
        </main>
      </div>
    </div>
  );
}
