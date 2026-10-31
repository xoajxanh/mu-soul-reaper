'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  LogIn,
  Zap,
  Eye,
  Sliders,
  Sparkles,
  Flame,
  CheckCircle2,
  ShieldCheck,
  RefreshCw,
  Layers,
  Send,
  MessageCircle,
  Crosshair,
  LayoutDashboard,
} from 'lucide-react';

export default function HomePage() {
  const [activeTab, setActiveTab] = useState<'basic' | 'advanced' | 'autoboss'>('basic');
  const [user, setUser] = useState<any>(null);

  // Simulated state for interactive demo
  const [fov, setFov] = useState(70);
  const [moveSpeed, setMoveSpeed] = useState(4.0);
  const [attackSpeed, setAttackSpeed] = useState(4.0);
  const [botRange, setBotRange] = useState(6);
  const [autoPick, setAutoPick] = useState(true);
  const [pickCount, setPickCount] = useState(7);
  const [showKundunHp, setShowKundunHp] = useState(true);
  const [autoPkGuild, setAutoPkGuild] = useState(false);
  const [autoFarm, setAutoFarm] = useState(false);
  const [autoSecretMap, setAutoSecretMap] = useState(false);

  useEffect(() => {
    fetch('/api/auth/me')
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (data?.user) {
          setUser(data.user);
        }
      })
      .catch(() => {});
  }, []);

  return (
    <div className="min-h-screen bg-[#090d16] text-slate-100 font-sans selection:bg-emerald-500 selection:text-white pb-20">
      {/* Background Decor */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden z-0">
        <div className="absolute -top-40 -left-40 w-96 h-96 bg-emerald-600/15 rounded-full blur-3xl"></div>
        <div className="absolute top-1/3 -right-40 w-96 h-96 bg-cyan-600/15 rounded-full blur-3xl"></div>
        <div className="absolute bottom-10 left-1/3 w-[500px] h-[500px] bg-purple-600/10 rounded-full blur-3xl"></div>
        <div className="absolute inset-0 bg-[radial-gradient(#1e293b_1px,transparent_1px)] [background-size:24px_24px] opacity-25"></div>
      </div>

      {/* TOP HEADER NAVBAR */}
      <header className="sticky top-0 z-50 backdrop-blur-md bg-[#090d16]/80 border-b border-emerald-500/20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3 group hover:opacity-90 transition cursor-pointer">
            {/* Project Logo Image */}
            <div className="relative w-11 h-11 rounded-xl overflow-hidden shadow-lg shadow-emerald-500/20 border border-emerald-400/40 bg-slate-900 group-hover:border-emerald-300/60 transition">
              <img
                src="/logo.png"
                alt="MU Vĩnh Hằng Logo"
                className="w-full h-full object-cover"
                onError={(e) => {
                  (e.target as HTMLElement).setAttribute('src', '/logo-full.jpg');
                }}
              />
            </div>
            <div>
              <span className="font-extrabold text-xl tracking-wider text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-green-300 to-cyan-400 uppercase">
                MU Vĩnh Hằng
              </span>
              <span className="block text-[10px] font-semibold tracking-widest text-emerald-400/80 uppercase">
                Mod Tool VIP Client • VUT Team
              </span>
            </div>
          </Link>

          {/* Nav links */}
          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-300">
            <a href="#features" className="hover:text-emerald-400 transition-colors">
              Tính năng Mod
            </a>
            <a href="#demo" className="hover:text-emerald-400 transition-colors">
              Giao diện Tool
            </a>
            <a href="#packages" className="hover:text-emerald-400 transition-colors">
              Bảng giá VIP
            </a>
            <a href="#contact" className="hover:text-emerald-400 transition-colors">
              Liên hệ
            </a>
          </nav>

          {/* Actions */}
          <div className="flex items-center gap-2 sm:gap-3">
            <a
              href="https://zalo.me/0386918686"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-blue-600 hover:bg-blue-500 text-white font-medium text-xs sm:text-sm transition-all shadow-lg shadow-blue-600/30 border border-blue-400/40 active:scale-95"
            >
              <MessageCircle className="w-4 h-4" />
              <span>Zalo 0386918686</span>
            </a>

            <a
              href="https://t.me/vutmod"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:inline-flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-sky-600 hover:bg-sky-500 text-white font-medium text-xs sm:text-sm transition-all shadow-lg shadow-sky-600/30 border border-sky-400/40 active:scale-95"
            >
              <Send className="w-4 h-4" />
              <span>Telegram @vutmod</span>
            </a>

            {user ? (
              <Link
                href="/dashboard"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-medium text-sm transition-all border border-emerald-400/40 shadow-lg shadow-emerald-600/20"
              >
                <LayoutDashboard className="w-4 h-4" />
                <span>Trang Quản Trị</span>
              </Link>
            ) : (
              <Link
                href="/login"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 hover:text-white font-medium text-sm transition-all border border-slate-700 hover:border-emerald-500/40"
              >
                <LogIn className="w-4 h-4 text-emerald-400" />
                <span>Đăng nhập Admin</span>
              </Link>
            )}
          </div>
        </div>
      </header>

      {/* HERO SECTION */}
      <section className="relative z-10 pt-12 pb-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center space-y-6 max-w-4xl mx-auto">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs sm:text-sm font-semibold tracking-wide uppercase shadow-inner">
            <Sparkles className="w-4 h-4 animate-pulse text-emerald-400" />
            <span>Bản Mod MU Vĩnh Hằng Độc Quyền bởi VUT Team v1.0</span>
          </div>

          <h1 className="text-3xl sm:text-5xl lg:text-6xl font-black tracking-tight text-white leading-tight">
            Tối Ưu Trải Nghiệm <br className="hidden sm:block" />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-green-300 to-cyan-400">
              MU Vĩnh Hằng Đỉnh Cao
            </span>
          </h1>

          <p className="text-slate-300 text-base sm:text-lg max-w-2xl mx-auto leading-relaxed">
            Hỗ trợ tăng tốc đánh &amp; chạy x4.0, tự động săn Boss Ẩn, nhặt đồ siêu tốc, 
            hiển thị thông số Kundun chi tiết và lọc tự động tách trang bị thông minh.
          </p>

          <div className="flex flex-wrap items-center justify-center gap-4 pt-4">
            <a
              href="https://zalo.me/0386918686"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2.5 px-7 py-4 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-bold text-base shadow-xl shadow-blue-600/25 border border-blue-400/40 transition-all transform hover:-translate-y-0.5 active:translate-y-0"
            >
              <MessageCircle className="w-5 h-5" />
              <span>LIÊN HỆ ZALO 0386918686</span>
            </a>
            <a
              href="https://t.me/vutmod"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2.5 px-7 py-4 rounded-xl bg-gradient-to-r from-sky-500 to-cyan-600 hover:from-sky-400 hover:to-cyan-500 text-white font-bold text-base shadow-xl shadow-sky-500/25 border border-sky-300/40 transition-all transform hover:-translate-y-0.5 active:translate-y-0"
            >
              <Send className="w-5 h-5" />
              <span>LIÊN HỆ TELEGRAM @vutmod</span>
            </a>
          </div>

          {/* Highlights */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 pt-10 text-left">
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800/80 backdrop-blur-sm">
              <div className="text-emerald-400 font-bold text-2xl">4.0x</div>
              <div className="text-slate-400 text-xs">Tốc chạy &amp; Tốc đánh</div>
            </div>
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800/80 backdrop-blur-sm">
              <div className="text-emerald-400 font-bold text-2xl">FOV 120</div>
              <div className="text-slate-400 text-xs">Góc nhìn siêu rộng</div>
            </div>
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800/80 backdrop-blur-sm">
              <div className="text-emerald-400 font-bold text-2xl">Auto Boss</div>
              <div className="text-slate-400 text-xs">Tự vào Map Ẩn &amp; C3-C12</div>
            </div>
            <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800/80 backdrop-blur-sm">
              <div className="text-emerald-400 font-bold text-2xl">Kundun HP</div>
              <div className="text-slate-400 text-xs">Hiện chính xác máu Boss</div>
            </div>
          </div>
        </div>
      </section>

      {/* INTERACTIVE DEMO TOOL SECTION */}
      <section id="demo" className="relative z-10 py-12 px-4 sm:px-6 lg:px-8 max-w-6xl mx-auto">
        <div className="text-center mb-8">
          <h2 className="text-2xl sm:text-3xl font-extrabold text-white">
            Mô Phỏng Giao Diện Tool Mod In-Game
          </h2>
          <p className="text-slate-400 text-sm mt-2">
            Click thử các tab và nút điều chỉnh bên dưới để xem thiết kế trực quan của Menu Mod
          </p>
        </div>

        {/* MOCK GAME MENU FRAMEWORK */}
        <div className="bg-[#121620] rounded-2xl border-2 border-emerald-500/40 shadow-2xl overflow-hidden max-w-3xl mx-auto backdrop-blur-md">
          {/* Menu Header Tabs (Matched with real screenshots) */}
          <div className="grid grid-cols-3 bg-[#0d1017] border-b border-slate-800">
            <button
              onClick={() => setActiveTab('basic')}
              className={`py-3 px-4 text-center font-bold text-sm sm:text-base tracking-wider transition-all border-b-4 ${
                activeTab === 'basic'
                  ? 'bg-emerald-700 text-white border-emerald-400 shadow-inner'
                  : 'text-slate-400 hover:text-slate-200 border-transparent bg-slate-900/50'
              }`}
            >
              [ CƠ BẢN ]
            </button>
            <button
              onClick={() => setActiveTab('advanced')}
              className={`py-3 px-4 text-center font-bold text-sm sm:text-base tracking-wider transition-all border-b-4 ${
                activeTab === 'advanced'
                  ? 'bg-emerald-700 text-white border-emerald-400 shadow-inner'
                  : 'text-slate-400 hover:text-slate-200 border-transparent bg-slate-900/50'
              }`}
            >
              [ NÂNG CAO ]
            </button>
            <button
              onClick={() => setActiveTab('autoboss')}
              className={`py-3 px-4 text-center font-bold text-sm sm:text-base tracking-wider transition-all border-b-4 ${
                activeTab === 'autoboss'
                  ? 'bg-emerald-700 text-white border-emerald-400 shadow-inner'
                  : 'text-slate-400 hover:text-slate-200 border-transparent bg-slate-900/50'
              }`}
            >
              [ AUTO BOSS ]
            </button>
          </div>

          {/* TAB 1: CƠ BẢN CONTENT */}
          {activeTab === 'basic' && (
            <div className="p-5 sm:p-6 space-y-5 text-sm bg-gradient-to-b from-[#121620] to-[#0c0f17]">
              {/* Row 1: FOV & Refresh */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* FOV */}
                <div className="flex items-center justify-between bg-slate-900/80 p-3 rounded-lg border border-slate-800">
                  <div className="flex items-center gap-2 font-semibold text-slate-200">
                    <Eye className="w-4 h-4 text-emerald-400" />
                    <span>FOV: <strong className="text-emerald-400">{fov}</strong></span>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => setFov(Math.max(20, fov - 5))}
                      className="w-8 h-8 rounded bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold border border-slate-700"
                    >
                      -5
                    </button>
                    <button
                      onClick={() => setFov(Math.min(120, fov + 5))}
                      className="w-8 h-8 rounded bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold border border-slate-700"
                    >
                      +5
                    </button>
                  </div>
                </div>

                {/* Auto Refresh Timer */}
                <div className="flex items-center justify-between bg-slate-900/80 p-3 rounded-lg border border-slate-800">
                  <div className="flex items-center gap-2 font-semibold text-slate-200">
                    <RefreshCw className="w-4 h-4 text-emerald-400" />
                    <span>Tự làm mới: <strong className="text-emerald-400">3s</strong></span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button className="px-2.5 py-1 rounded bg-slate-800 text-slate-300 font-bold text-xs">-</button>
                    <button className="px-2.5 py-1 rounded bg-slate-800 text-slate-300 font-bold text-xs">+</button>
                  </div>
                </div>
              </div>

              {/* Row 2: Tốc Chạy, Tốc Đánh, Phạm Vi Bot */}
              <div className="space-y-3">
                {/* Tốc chạy */}
                <div className="flex items-center justify-between bg-slate-900/80 p-3 rounded-lg border border-slate-800">
                  <span className="font-semibold text-slate-200">
                    Tốc Chạy: <strong className="text-emerald-400">{moveSpeed.toFixed(1)}x</strong>
                  </span>
                  <div className="flex items-center gap-1.5">
                    <button onClick={() => setMoveSpeed(Math.max(1, moveSpeed - 0.5))} className="px-2.5 py-1 bg-red-900/50 hover:bg-red-800 text-red-200 font-bold rounded border border-red-800/60">-5</button>
                    <button onClick={() => setMoveSpeed(Math.max(1, moveSpeed - 0.1))} className="px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded border border-slate-700">-</button>
                    <button onClick={() => setMoveSpeed(Math.min(5, moveSpeed + 0.1))} className="px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded border border-slate-700">+</button>
                    <button onClick={() => setMoveSpeed(Math.min(5, moveSpeed + 0.5))} className="px-2.5 py-1 bg-emerald-900/50 hover:bg-emerald-800 text-emerald-200 font-bold rounded border border-emerald-800/60">+5</button>
                  </div>
                </div>

                {/* Tốc đánh */}
                <div className="flex items-center justify-between bg-slate-900/80 p-3 rounded-lg border border-slate-800">
                  <span className="font-semibold text-slate-200">
                    Tốc Đánh: <strong className="text-emerald-400">{attackSpeed.toFixed(1)}x</strong>
                  </span>
                  <div className="flex items-center gap-1.5">
                    <button onClick={() => setAttackSpeed(Math.max(1, attackSpeed - 0.5))} className="px-2.5 py-1 bg-red-900/50 hover:bg-red-800 text-red-200 font-bold rounded border border-red-800/60">-5</button>
                    <button onClick={() => setAttackSpeed(Math.max(1, attackSpeed - 0.1))} className="px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded border border-slate-700">-</button>
                    <button onClick={() => setAttackSpeed(Math.min(5, attackSpeed + 0.1))} className="px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded border border-slate-700">+</button>
                    <button onClick={() => setAttackSpeed(Math.min(5, attackSpeed + 0.5))} className="px-2.5 py-1 bg-emerald-900/50 hover:bg-emerald-800 text-emerald-200 font-bold rounded border border-emerald-800/60">+5</button>
                  </div>
                </div>

                {/* Phạm vi bot */}
                <div className="flex items-center justify-between bg-slate-900/80 p-3 rounded-lg border border-slate-800">
                  <span className="font-semibold text-slate-200">
                    Phạm Vi Bot: <strong className="text-emerald-400">{botRange}</strong>
                  </span>
                  <div className="flex items-center gap-1.5">
                    <button onClick={() => setBotRange(Math.max(1, botRange - 1))} className="px-2.5 py-1 bg-red-900/50 hover:bg-red-800 text-red-200 font-bold rounded border border-red-800/60">-5</button>
                    <button onClick={() => setBotRange(Math.max(1, botRange - 1))} className="px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded border border-slate-700">-</button>
                    <button onClick={() => setBotRange(Math.min(50, botRange + 1))} className="px-2 py-1 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded border border-slate-700">+</button>
                    <button onClick={() => setBotRange(Math.min(50, botRange + 5))} className="px-2.5 py-1 bg-emerald-900/50 hover:bg-emerald-800 text-emerald-200 font-bold rounded border border-emerald-800/60">+5</button>
                  </div>
                </div>
              </div>

              {/* Boss Spawn Tracker Display */}
              <div className="border-t border-slate-800 pt-4 space-y-2">
                <div className="text-amber-400 font-bold text-xs tracking-wider uppercase flex items-center gap-2">
                  <Flame className="w-4 h-4 text-amber-400 animate-pulse" />
                  <span>Danh Sách Boss Tự Động Theo Dõi (Live Tracker)</span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                  <div className="bg-slate-900/90 p-2.5 rounded border border-slate-800">
                    <div className="text-amber-300 font-bold mb-1">Hoang Dã C5</div>
                    <div className="flex justify-between text-slate-300">
                      <span>Giác Ma Đ.Ngục:</span> <span className="text-emerald-400 font-bold">[ xuất hiện ]</span>
                    </div>
                    <div className="flex justify-between text-slate-300">
                      <span>Phẫn Nộ / Cường Bạo:</span> <span className="text-emerald-400 font-bold">[ xuất hiện ]</span>
                    </div>
                  </div>

                  <div className="bg-slate-900/90 p-2.5 rounded border border-slate-800">
                    <div className="text-amber-300 font-bold mb-1">Trang Sức C5</div>
                    <div className="flex justify-between text-slate-300">
                      <span>Hươu Thủy Tinh:</span> <span className="text-cyan-400 font-mono font-bold">(01:37)</span>
                    </div>
                    <div className="flex justify-between text-slate-300">
                      <span>Thoát Phó Bản:</span> <span className="text-red-400 font-bold">[ Rời phó bản ]</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: NÂNG CAO CONTENT */}
          {activeTab === 'advanced' && (
            <div className="p-5 sm:p-6 space-y-5 text-sm bg-gradient-to-b from-[#121620] to-[#0c0f17]">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Column 1: NHẶT ĐỒ SIÊU TỐC */}
                <div className="bg-slate-900/80 p-4 rounded-xl border border-slate-800 space-y-3">
                  <div className="text-amber-400 font-bold text-xs uppercase tracking-wider">
                    [ NHẶT ĐỒ SIÊU TỐC ]
                  </div>

                  <button
                    onClick={() => setAutoPick(!autoPick)}
                    className={`w-full py-2.5 px-3 rounded font-bold text-center transition-all ${
                      autoPick
                        ? 'bg-emerald-700 hover:bg-emerald-600 text-white border border-emerald-400'
                        : 'bg-red-950 hover:bg-red-900 text-red-200 border border-red-800'
                    }`}
                  >
                    TỰ ĐỘNG NHẶT: {autoPick ? 'ON' : 'OFF'}
                  </button>

                  <div className="flex items-center justify-between text-xs text-slate-300 pt-1">
                    <span>SỐ LƯỢNG NHẶT: <strong className="text-emerald-400 text-sm">{pickCount}</strong></span>
                    <div className="flex gap-1">
                      <button onClick={() => setPickCount(Math.max(1, pickCount - 1))} className="px-3 py-1 bg-slate-800 hover:bg-slate-700 rounded font-bold text-white border border-slate-700">-</button>
                      <button onClick={() => setPickCount(pickCount + 1)} className="px-3 py-1 bg-slate-800 hover:bg-slate-700 rounded font-bold text-white border border-slate-700">+</button>
                    </div>
                  </div>
                </div>

                {/* Column 2: CHỨC NĂNG HỖ TRỢ */}
                <div className="bg-slate-900/80 p-4 rounded-xl border border-slate-800 space-y-3">
                  <div className="text-amber-400 font-bold text-xs uppercase tracking-wider">
                    [ CHỨC NĂNG HỖ TRỢ ]
                  </div>

                  <button
                    onClick={() => setShowKundunHp(!showKundunHp)}
                    className={`w-full py-2 rounded font-bold text-xs transition-all ${
                      showKundunHp
                        ? 'bg-emerald-700 text-white border border-emerald-400'
                        : 'bg-slate-800 text-slate-400'
                    }`}
                  >
                    HIỆN MÁU KUNDUN: {showKundunHp ? 'ON' : 'OFF'}
                  </button>

                  <button
                    onClick={() => setAutoPkGuild(!autoPkGuild)}
                    className={`w-full py-2 rounded font-bold text-xs transition-all ${
                      autoPkGuild
                        ? 'bg-emerald-700 text-white border border-emerald-400'
                        : 'bg-red-900/60 text-red-200 border border-red-800'
                    }`}
                  >
                    AUTO PK GUILD: {autoPkGuild ? 'ON' : 'OFF'}
                  </button>

                  <div className="flex items-center gap-2 bg-slate-950 p-2 rounded border border-slate-800 text-xs">
                    <span className="text-slate-400">KHÓA MỤC TIÊU:</span>
                    <span className="font-mono font-bold text-emerald-400">S399.</span>
                  </div>
                </div>
              </div>

              {/* INFO KUNDUN BOSS */}
              <div className="bg-slate-900/90 p-4 rounded-xl border border-emerald-500/20">
                <div className="text-emerald-400 font-bold text-xs uppercase mb-2 flex items-center justify-between">
                  <span>[ INFO KUNDUN BOSS ]</span>
                  <span className="text-amber-400 font-mono">[ BOSS C5 ]</span>
                </div>
                <div className="text-slate-300 text-xs font-mono bg-slate-950 p-3 rounded border border-slate-800 flex justify-between items-center">
                  <span>THÁNH CỐT KUNDUN:</span>
                  <span className="text-emerald-400 font-bold">0 / 70 (0)</span>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: AUTO BOSS CONTENT */}
          {activeTab === 'autoboss' && (
            <div className="p-5 sm:p-6 space-y-4 text-sm bg-gradient-to-b from-[#121620] to-[#0c0f17]">
              {/* Row 1 Controls */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <button
                  onClick={() => setAutoFarm(!autoFarm)}
                  className={`py-2.5 px-3 rounded font-bold text-xs uppercase transition-all ${
                    autoFarm
                      ? 'bg-emerald-700 text-white border border-emerald-400'
                      : 'bg-red-950 text-red-200 border border-red-800'
                  }`}
                >
                  AUTO FARM: {autoFarm ? 'ON' : 'OFF'}
                </button>

                <button
                  onClick={() => setAutoSecretMap(!autoSecretMap)}
                  className="py-2.5 px-3 rounded bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-xs border border-slate-700"
                >
                  TỰ VÀO MAP ẨN: {autoSecretMap ? 'BẬT' : 'TẮT'}
                </button>

                <button className="py-2.5 px-3 rounded bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-xs border border-slate-700">
                  VÀO ẨN KC: TẮT
                </button>
              </div>

              {/* Row 2: Tách Đồ (C3 đến C12) */}
              <div className="bg-slate-900/80 p-3 rounded-xl border border-slate-800 space-y-2 text-xs">
                <div className="text-slate-300 font-bold mb-1">TỰ ĐỘNG PHÂN TÁCH TRANG BỊ:</div>

                <div className="flex items-center justify-between border-b border-slate-800 pb-1.5 overflow-x-auto">
                  <span className="text-slate-400 shrink-0 mr-2">TÁCH NHẪN:</span>
                  <div className="flex gap-1 flex-wrap justify-end">
                    {['C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10', 'C11', 'C12'].map((lv) => (
                      <span key={lv} className="px-1.5 py-0.5 rounded bg-slate-800 text-emerald-400 font-mono font-bold text-[11px] border border-slate-700">{lv}</span>
                    ))}
                  </div>
                </div>

                <div className="flex items-center justify-between border-b border-slate-800 pb-1.5 overflow-x-auto">
                  <span className="text-slate-400 shrink-0 mr-2">TÁCH DÂY:</span>
                  <div className="flex gap-1 flex-wrap justify-end">
                    {['C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10', 'C11', 'C12'].map((lv) => (
                      <span key={lv} className="px-1.5 py-0.5 rounded bg-slate-800 text-emerald-400 font-mono font-bold text-[11px] border border-slate-700">{lv}</span>
                    ))}
                  </div>
                </div>

                <div className="flex items-center justify-between overflow-x-auto">
                  <span className="text-slate-400 shrink-0 mr-2">TÁCH KHUYÊN:</span>
                  <div className="flex gap-1 flex-wrap justify-end">
                    {['C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'C10', 'C11', 'C12'].map((lv) => (
                      <span key={lv} className="px-1.5 py-0.5 rounded bg-slate-800 text-emerald-400 font-mono font-bold text-[11px] border border-slate-700">{lv}</span>
                    ))}
                  </div>
                </div>
              </div>

              {/* Statistics Footer */}
              <div className="flex flex-wrap items-center justify-between bg-slate-950 p-3 rounded-lg border border-slate-800 text-xs gap-2">
                <button className="px-3 py-1 bg-red-900/70 hover:bg-red-800 text-red-200 font-bold rounded uppercase">
                  RESET THỐNG KÊ
                </button>
                <div className="flex items-center gap-3 text-amber-400 font-semibold font-mono">
                  <span>BOSS ẨN: <strong className="text-white">0</strong></span>
                  <span>TỔNG BOSS C3: <strong className="text-emerald-400">7</strong></span>
                  <span>TỔNG BOSS C5: <strong className="text-white">0</strong></span>
                </div>
              </div>
            </div>
          )}

          {/* Mock Watermark */}
          <div className="bg-[#090b10] px-4 py-2 text-right border-t border-slate-800">
            <span className="text-[11px] italic font-semibold text-emerald-500/80">
              Modded by VUT Team
            </span>
          </div>
        </div>
      </section>

      {/* FEATURE CARDS GRID */}
      <section id="features" className="relative z-10 py-16 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-3xl font-black text-white tracking-tight">
            Tính Năng Nổi Bật Bản Mod MU Vĩnh Hằng
          </h2>
          <p className="text-slate-400 text-sm mt-2 max-w-2xl mx-auto">
            Bộ công cụ được tối ưu riêng biệt cho game MU Vĩnh Hằng, chạy mượt mà trên mọi giả lập &amp; điện thoại Android.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Feature 1 */}
          <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-emerald-500/50 transition-all group backdrop-blur-sm">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <Zap className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2 group-hover:text-emerald-400 transition-colors">
              Tốc Độ Chạy &amp; Đánh x4.0
            </h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              Tùy chỉnh tốc độ di chuyển và tốc độ ra chiêu từ 1.0x tới 4.0x. Giúp đi phó bản nhanh gấp 4 lần và chiếm ưu thế tuyệt đối trong PK.
            </p>
          </div>

          {/* Feature 2 */}
          <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-emerald-500/50 transition-all group backdrop-blur-sm">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <Eye className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2 group-hover:text-emerald-400 transition-colors">
              Mở Rộng Góc Nhìn FOV
            </h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              Điều chỉnh FOV linh hoạt từ 20 đến 120. Mở rộng tầm nhìn giúp theo dõi Boss từ khoảng cách cực xa mà góc nhìn mặc định không thấy được.
            </p>
          </div>

          {/* Feature 3 */}
          <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-emerald-500/50 transition-all group backdrop-blur-sm">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <Layers className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2 group-hover:text-emerald-400 transition-colors">
              Nhặt Đồ Siêu Tốc &amp; Tách Đồ C3-C12
            </h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              Hệ thống lọc vật phẩm thông minh, tự động nhặt ngọc &amp; trang bị quý. Tự động phân tách Nhẫn, Dây, Khuyên từ C3 đến C12 tránh đầy rương.
            </p>
          </div>

          {/* Feature 4 */}
          <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-emerald-500/50 transition-all group backdrop-blur-sm">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <Flame className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2 group-hover:text-emerald-400 transition-colors">
              Auto Boss &amp; Đếm Máu Kundun
            </h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              Hiển thị chính xác thanh máu Boss Kundun và số lượng Thánh Cốt. Tự động di chuyển vào Map Ẩn và đếm chính xác thời gian Boss xuất hiện.
            </p>
          </div>

          {/* Feature 5 */}
          <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-emerald-500/50 transition-all group backdrop-blur-sm">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <Crosshair className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2 group-hover:text-emerald-400 transition-colors">
              Khóa Mục Tiêu &amp; Auto PK Guild
            </h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              Hỗ trợ tự động khóa mục tiêu kẻ địch trong bang hội đối địch, giúp xả skill chính xác 100% không lo chọn nhầm mục tiêu.
            </p>
          </div>

          {/* Feature 6 */}
          <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-emerald-500/50 transition-all group backdrop-blur-sm">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2 group-hover:text-emerald-400 transition-colors">
              Bảo Mật Key VIP Server
            </h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              Hệ thống xác thực Token/Key theo thời hạn (ngày), tích hợp quản lý qua Web Admin chuyên nghiệp và an toàn tuyệt đối.
            </p>
          </div>
        </div>
      </section>

      {/* PACKAGES PREVIEW SECTION */}
      <section id="packages" className="relative z-10 py-12 px-4 sm:px-6 lg:px-8 max-w-6xl mx-auto">
        <div className="text-center mb-10">
          <h2 className="text-3xl font-black text-white">Bảng Gói VIP &amp; Đăng Ký Bản Quyền</h2>
          <p className="text-slate-400 text-sm mt-2">Liên hệ hỗ trợ cài đặt &amp; mua key VIP qua Zalo hoặc Telegram chính thức</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Gói Thường */}
          <div className="p-6 rounded-2xl bg-slate-900/80 border border-slate-800 flex flex-col justify-between hover:border-slate-700 transition">
            <div>
              <div className="text-slate-400 text-xs font-bold uppercase tracking-widest mb-2">BẢN CƠ BẢN</div>
              <div className="text-2xl font-black text-white mb-4">Gói Thường</div>
              <ul className="space-y-3 text-sm text-slate-300 mb-6">
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Chạy nhanh (Speed Hack)</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Zoom gần xa (Mở rộng FOV)</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Phát hiện mục tiêu xa</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Auto PK khóa tên mục tiêu</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Nhặt đồ Kundun tỷ lệ 80%</span>
                </li>
              </ul>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-4">
              <a
                href="https://zalo.me/0386918686"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full py-2.5 rounded-xl bg-blue-600/90 hover:bg-blue-500 text-white font-bold text-center text-xs border border-blue-400/40 shadow-lg shadow-blue-600/20 flex items-center justify-center gap-1.5 transition-all"
              >
                <MessageCircle className="w-3.5 h-3.5" />
                <span>Zalo 0386918686</span>
              </a>
              <a
                href="https://t.me/vutmod"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full py-2.5 rounded-xl bg-sky-600/90 hover:bg-sky-500 text-white font-bold text-center text-xs border border-sky-400/40 shadow-lg shadow-sky-600/20 flex items-center justify-center gap-1.5 transition-all"
              >
                <Send className="w-3.5 h-3.5" />
                <span>Telegram @vutmod</span>
              </a>
            </div>
          </div>

          {/* Gói VIP */}
          <div className="p-6 rounded-2xl bg-gradient-to-b from-emerald-950/70 via-slate-900 to-slate-900 border-2 border-emerald-500 relative flex flex-col justify-between shadow-xl shadow-emerald-500/10">
            <div className="absolute -top-3 right-6 px-3 py-0.5 rounded-full bg-gradient-to-r from-emerald-400 to-green-500 text-slate-950 font-black text-[11px] uppercase tracking-wider shadow-md">
              KHUYÊN DÙNG ★ VIP
            </div>
            <div>
              <div className="text-emerald-400 text-xs font-bold uppercase tracking-widest mb-2">BẢN CAO CẤP FULL TÍNH NĂNG</div>
              <div className="text-2xl font-black text-white mb-4">Gói VIP</div>
              <ul className="space-y-3 text-sm text-slate-200 mb-6">
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
                  <span className="font-semibold text-amber-300">Bao gồm toàn bộ tính năng Gói Thường</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Auto săn Boss</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Bảng theo dõi tất cả Boss</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Tự vào Boss ẩn</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Tự tách nhẫn &amp; dây chuyền</span>
                </li>
                <li className="flex items-start gap-2.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                  <span>Điều chỉnh Mod hoàn toàn trên game</span>
                </li>
              </ul>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-4">
              <a
                href="https://zalo.me/0386918686"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full py-2.5 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-bold text-center text-xs border border-blue-400/40 shadow-lg shadow-blue-600/20 flex items-center justify-center gap-1.5 transition-all"
              >
                <MessageCircle className="w-3.5 h-3.5" />
                <span>Zalo 0386918686</span>
              </a>
              <a
                href="https://t.me/vutmod"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full py-2.5 rounded-xl bg-gradient-to-r from-sky-500 to-emerald-600 hover:from-sky-400 hover:to-emerald-500 text-white font-bold text-center text-xs border border-sky-300/40 shadow-lg shadow-sky-500/20 flex items-center justify-center gap-1.5 transition-all"
              >
                <Send className="w-3.5 h-3.5" />
                <span>Telegram @vutmod</span>
              </a>
            </div>
          </div>

          {/* Admin */}
          <div className="p-6 rounded-2xl bg-slate-900/80 border border-slate-800 flex flex-col justify-between">
            <div>
              <div className="text-amber-400 text-xs font-bold uppercase tracking-widest mb-2">DÀNH CHO ĐẠI LÝ</div>
              <div className="text-2xl font-black text-white mb-4">Tài Khoản Quản Trị</div>
              <ul className="space-y-3 text-sm text-slate-300 mb-6">
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-amber-400 shrink-0" />
                  <span>Tự tạo Key Token cho khách hàng</span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-amber-400 shrink-0" />
                  <span>Quản lý thời hạn &amp; gia hạn Key</span>
                </li>
                <li className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-amber-400 shrink-0" />
                  <span>Giao diện Dashboard trực quan</span>
                </li>
              </ul>
            </div>
            {user ? (
              <Link
                href="/dashboard"
                className="w-full py-3 rounded-xl bg-emerald-700 hover:bg-emerald-600 text-white font-bold text-center text-sm border border-emerald-500/40 flex items-center justify-center gap-2"
              >
                <LayoutDashboard className="w-4 h-4" />
                <span>Vào Dashboard Quản Trị</span>
              </Link>
            ) : (
              <Link
                href="/login"
                className="w-full py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold text-center text-sm border border-slate-700 flex items-center justify-center gap-2"
              >
                <LogIn className="w-4 h-4 text-emerald-400" />
                <span>Đăng Nhập Dashboard</span>
              </Link>
            )}
          </div>
        </div>
      </section>

      {/* CONTACT CTA BANNER */}
      <section id="contact" className="relative z-10 pt-8 pb-12 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto">
        <div className="p-8 sm:p-12 rounded-3xl bg-gradient-to-r from-emerald-900/70 via-slate-900 to-green-950/80 border border-emerald-500/40 shadow-2xl text-center space-y-6">
          <h2 className="text-3xl sm:text-4xl font-black text-white">
            Liên Hệ Kích Hoạt &amp; Cài Đặt Bản Mod
          </h2>
          <p className="text-slate-300 text-sm sm:text-base max-w-xl mx-auto">
            Hỗ trợ kích hoạt bản quyền nhanh chóng, tư vấn và hướng dẫn cài đặt tận tình cho mọi thiết bị Android &amp; Giả lập PC (NoxPlayer, LDPlayer, Bluestacks).
          </p>

          <div className="flex flex-wrap justify-center gap-4 pt-2">
            <a
              href="https://zalo.me/0386918686"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2.5 px-8 py-4 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 text-white font-bold text-base transition-all shadow-xl shadow-blue-600/30 border border-blue-400/40"
            >
              <MessageCircle className="w-5 h-5" />
              <span>LIÊN HỆ ZALO 0386918686</span>
            </a>
            <a
              href="https://t.me/vutmod"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2.5 px-8 py-4 rounded-xl bg-sky-600 hover:bg-sky-500 text-white font-bold text-base transition-all border border-sky-400/40 shadow-lg shadow-sky-500/20"
            >
              <Send className="w-5 h-5" />
              <span>LIÊN HỆ TELEGRAM @vutmod</span>
            </a>
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="relative z-10 border-t border-slate-800/80 pt-8 text-center text-slate-500 text-xs">
        <div className="flex items-center justify-center gap-2 mb-2">
          <img src="/logo.png" alt="Logo" className="w-5 h-5 rounded object-cover" />
          <span className="font-bold text-slate-400">MU Vĩnh Hằng • VUT Team Modded</span>
        </div>
        <p>© 2026 MU Vĩnh Hằng Mod. Tất cả quyền được bảo lưu.</p>
        <p className="mt-1 text-slate-600">Hỗ trợ đầy đủ cho mọi thiết bị Android &amp; Giả lập PC.</p>
      </footer>
    </div>
  );
}
