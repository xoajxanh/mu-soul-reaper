'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Navbar from '@/components/Navbar';
import Toast from '@/components/Toast';
import { Package, Plus, Edit2, Trash2, X, Sliders } from 'lucide-react';

export default function PackagesPage() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [packages, setPackages] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Modal state
  const [showModal, setShowModal] = useState(false);
  const [editingPkgId, setEditingPkgId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [durationDays, setDurationDays] = useState(30);
  const [price, setPrice] = useState(300000);
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
          loadPackages();
        }
      })
      .catch(() => router.push('/login'));
  }, [router]);

  const loadPackages = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/packages');
      if (res.ok) {
        const json = await res.json();
        setPackages(json.packages || []);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (pkg?: any) => {
    if (pkg) {
      setEditingPkgId(pkg.id);
      setName(pkg.name);
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
    } else {
      setEditingPkgId(null);
      setName('');
      setDurationDays(30);
      setPrice(300000);
      setFovMin(20);
      setFovMax(90);
      setBossRefreshMin(1);
      setBossRefreshMax(60);
      setMaxMoveSpeed(2.5);
      setMaxAttackSpeed(2.5);
      setMaxMonsterRange(50);
      setMaxPickupCount(100);
      setPickupDelayMin(100);
      setPickupDelayMax(500);
      setActiveTabBasic(true);
      setActiveTabAdvanced(true);
      setActiveTabAutofarm(true);
    }
    setShowModal(true);
  };

  const handleSavePackage = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    try {
      const payload = {
        name: name.trim(),
        durationDays: Number(durationDays),
        price: Number(price),
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
      };

      const url = editingPkgId ? `/api/packages/${editingPkgId}` : '/api/packages';
      const method = editingPkgId ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (!res.ok) {
        throw new Error(json.error || 'Lỗi khi lưu gói VIP');
      }

      setToast({ message: 'Lưu cấu hình gói VIP thành công!', type: 'success' });
      setShowModal(false);
      loadPackages();
    } catch (err: any) {
      setToast({ message: err.message || 'Lỗi hệ thống', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeletePackage = async (id: string, name: string) => {
    if (!confirm(`Bạn có chắc muốn xóa gói VIP [${name}]?`)) return;

    try {
      const res = await fetch(`/api/packages/${id}`, { method: 'DELETE' });
      const json = await res.json();
      if (!res.ok) {
        setToast({ message: json.error || 'Không thể xóa', type: 'error' });
        return;
      }
      setToast({ message: 'Đã xóa gói VIP', type: 'success' });
      loadPackages();
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
                Cấu Hình Các Gói Cước VIP
                <Package className="w-5 h-5 text-cyan-400" />
              </h1>
              <p className="text-xs text-slate-400 mt-1">
                Thiết lập đầy đủ thông số mod (FOV, tốc độ, nhặt đồ, delay nhặt, tabs) để nhân viên chọn tạo token nhanh
              </p>
            </div>

            {(user.role === 'ADMIN' || user.role === 'SALE') && (
              <button
                onClick={() => handleOpenModal()}
                className="px-5 py-2.5 gradient-button text-white text-sm font-semibold rounded-xl shadow-lg shadow-cyan-500/20 flex items-center gap-2 self-start sm:self-auto hover:scale-105 transition"
              >
                <Plus className="w-4 h-4" />
                THÊM GÓI VIP MỚI
              </button>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {packages.map((pkg) => (
              <div key={pkg.id} className="glass-card p-6 rounded-2xl space-y-4 relative group">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="font-bold text-slate-100 text-base">{pkg.name}</h3>
                    <span className="text-xs text-cyan-400 font-semibold">{pkg.durationDays} Ngày Sử Dụng</span>
                  </div>
                  <div className="text-right">
                    <span className="text-lg font-black text-emerald-400">
                      {pkg.price.toLocaleString('vi-VN')} đ
                    </span>
                  </div>
                </div>

                <div className="space-y-2 text-xs text-slate-300 pt-3 border-t border-slate-800">
                  <div className="flex justify-between">
                    <span className="text-slate-400">FOV Min - Max:</span>
                    <span className="font-semibold">{pkg.fovMin} - {pkg.fovMax}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Refresh Boss:</span>
                    <span className="font-semibold">{pkg.bossRefreshMin}s - {pkg.bossRefreshMax}s</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Tốc Chạy / Đánh Max:</span>
                    <span className="font-semibold">{pkg.maxMoveSpeed}x / {pkg.maxAttackSpeed}x</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Phạm Vi / Nhặt Max:</span>
                    <span className="font-semibold">{pkg.maxMonsterRange}m / {pkg.maxPickupCount} item</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Delay Nhặt Đồ:</span>
                    <span className="font-semibold text-amber-300">{pkg.pickupDelayMin}ms - {pkg.pickupDelayMax}ms</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Tabs Active:</span>
                    <span className="font-semibold text-indigo-300">
                      {[pkg.activeTabBasic && 'Cơ bản', pkg.activeTabAdvanced && 'Nâng cao', pkg.activeTabAutofarm && 'AutoFarm'].filter(Boolean).join(', ')}
                    </span>
                  </div>
                </div>

                {(user.role === 'ADMIN' || user.role === 'SALE') && (
                  <div className="flex items-center justify-end gap-2 pt-2">
                    <button
                      onClick={() => handleOpenModal(pkg)}
                      className="p-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg transition"
                      title="Sửa gói VIP"
                    >
                      <Edit2 className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => handleDeletePackage(pkg.id, pkg.name)}
                      className="p-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 rounded-lg transition"
                      title="Xóa gói VIP"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Modal Add/Edit Package */}
          {showModal && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm overflow-y-auto">
              <div className="glass-card w-full max-w-2xl p-6 rounded-2xl space-y-4 border border-slate-800 relative my-8 max-h-[90vh] overflow-y-auto">
                <button
                  onClick={() => setShowModal(false)}
                  className="absolute top-4 right-4 p-1 text-slate-400 hover:text-white"
                >
                  <X className="w-5 h-5" />
                </button>

                <h3 className="font-bold text-slate-100 text-base flex items-center gap-2">
                  <Sliders className="w-5 h-5 text-cyan-400" />
                  {editingPkgId ? 'Cập Nhật Cấu Hình Gói VIP' : 'Thêm Gói VIP Cấu Hình Mới'}
                </h3>

                <form onSubmit={handleSavePackage} className="space-y-4 text-xs">
                  {/* Row 1: Package Name & Duration & Price */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div className="flex flex-col justify-end">
                      <label className="block font-semibold text-slate-300 mb-1 text-xs min-h-[20px] flex items-end">
                        Tên Gói Cước <span className="text-rose-400 ml-1">*</span>
                      </label>
                      <input
                        type="text"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="Gói VIP 30 Ngày"
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-100"
                        required
                      />
                    </div>
                    <div className="flex flex-col justify-end">
                      <label className="block font-semibold text-slate-300 mb-1 text-xs min-h-[20px] flex items-end">
                        Thời Hạn Sử Dụng (Ngày) <span className="text-rose-400 ml-1">*</span>
                      </label>
                      <input
                        type="number"
                        step="any"
                        min="0.001"
                        value={durationDays}
                        onChange={(e) => setDurationDays(Number(e.target.value))}
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-100 font-semibold"
                        required
                      />
                    </div>
                    <div className="flex flex-col justify-end">
                      <label className="block font-semibold text-slate-300 mb-1 text-xs min-h-[20px] flex items-end">
                        Giá Tiền (VNĐ)
                      </label>
                      <input
                        type="number"
                        value={price}
                        onChange={(e) => setPrice(Number(e.target.value))}
                        className="w-full h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-emerald-400 font-bold"
                        required
                      />
                    </div>
                  </div>

                  {/* Row 2: FOV & Refresh Boss */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block font-semibold text-slate-300 mb-1 min-h-[20px] flex items-end">
                        FOV Tối Thiểu / Tối Đa
                      </label>
                      <div className="flex gap-2">
                        <input
                          type="number"
                          value={fovMin}
                          onChange={(e) => setFovMin(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                        <input
                          type="number"
                          value={fovMax}
                          onChange={(e) => setFovMax(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1 min-h-[20px] flex items-end">
                        Refresh Boss (Min / Max s)
                      </label>
                      <div className="flex gap-2">
                        <input
                          type="number"
                          value={bossRefreshMin}
                          onChange={(e) => setBossRefreshMin(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                        <input
                          type="number"
                          value={bossRefreshMax}
                          onChange={(e) => setBossRefreshMax(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Row 3: Move Speed & Attack Speed */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block font-semibold text-slate-300 mb-1 min-h-[20px] flex items-end">
                        Tốc Chạy Max / Tốc Đánh Max
                      </label>
                      <div className="flex gap-2">
                        <input
                          type="number"
                          step="0.1"
                          value={maxMoveSpeed}
                          onChange={(e) => setMaxMoveSpeed(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                        <input
                          type="number"
                          step="0.1"
                          value={maxAttackSpeed}
                          onChange={(e) => setMaxAttackSpeed(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                      </div>
                    </div>

                    <div>
                      <label className="block font-semibold text-slate-300 mb-1 min-h-[20px] flex items-end">
                        Phạm Vi Quái / Giới Hạn Nhặt
                      </label>
                      <div className="flex gap-2">
                        <input
                          type="number"
                          value={maxMonsterRange}
                          onChange={(e) => setMaxMonsterRange(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                        <input
                          type="number"
                          value={maxPickupCount}
                          onChange={(e) => setMaxPickupCount(Number(e.target.value))}
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-slate-200"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Row 4: Delay Nhặt Đồ (Min / Max ms) */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block font-semibold text-slate-300 mb-1 min-h-[20px] flex items-end">
                        Delay Nhặt Đồ Min / Max (ms)
                      </label>
                      <div className="flex gap-2">
                        <input
                          type="number"
                          value={pickupDelayMin}
                          onChange={(e) => setPickupDelayMin(Number(e.target.value))}
                          placeholder="Min ms (VD: 100)"
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-amber-300 font-semibold"
                        />
                        <input
                          type="number"
                          value={pickupDelayMax}
                          onChange={(e) => setPickupDelayMax(Number(e.target.value))}
                          placeholder="Max ms (VD: 500)"
                          className="w-1/2 h-10 px-3 bg-slate-900 border border-slate-800 rounded-xl text-amber-300 font-semibold"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Active Tabs Toggles */}
                  <div className="pt-2 border-t border-slate-800 flex flex-wrap gap-6 text-xs font-semibold">
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={activeTabBasic}
                        onChange={(e) => setActiveTabBasic(e.target.checked)}
                        className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                      />
                      <span className="text-slate-200">Active Tab Cơ Bản</span>
                    </label>

                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={activeTabAdvanced}
                        onChange={(e) => setActiveTabAdvanced(e.target.checked)}
                        className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                      />
                      <span className="text-slate-200">Active Tab Nâng Cao</span>
                    </label>

                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={activeTabAutofarm}
                        onChange={(e) => setActiveTabAutofarm(e.target.checked)}
                        className="rounded bg-slate-900 border-slate-800 text-cyan-500 focus:ring-cyan-500"
                      />
                      <span className="text-slate-200">Active Tab AUTO Farm</span>
                    </label>
                  </div>

                  <button
                    type="submit"
                    disabled={submitting}
                    className="w-full h-11 gradient-button text-white font-bold rounded-xl shadow-lg text-xs mt-2"
                  >
                    {submitting ? 'Đang lưu...' : 'LƯU CẤU HÌNH GÓI VIP'}
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
