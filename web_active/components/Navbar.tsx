'use client';

// =========================================================================
// [MOD FEATURE]: RESPONSIVE NAVBAR VỚI HAMBURGER MENU VÀ MOBILE DRAWER
// Mô tả: Cung cấp nút menu và ngăn kéo điều hướng đầy đủ cho thiết bị di động
// =========================================================================

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  User,
  LogOut,
  ShieldCheck,
  KeyRound,
  Menu,
  X,
  LayoutDashboard,
  Key,
  Package,
  Users,
  Send,
  MessageSquareQuote,
  Crown,
  History,
} from 'lucide-react';
import { UserSession } from '@/lib/auth';

interface NavbarProps {
  user: UserSession | null;
}

export default function Navbar({ user }: NavbarProps) {
  const router = useRouter();
  const pathname = usePathname();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Đóng Drawer khi nhấn phím Escape
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setIsMobileMenuOpen(false);
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Khóa cuộn trang khi đang mở Mobile Menu
  useEffect(() => {
    if (isMobileMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMobileMenuOpen]);

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/logout', { method: 'POST' });
      router.push('/login');
      router.refresh();
    } catch (e) {
      console.error(e);
    }
  };

  const navItems = [
    { label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    { label: 'Token Customer', href: '/tokens', icon: Key },
    { label: 'Token SVIP', href: '/svip-tokens', icon: Crown, isSvip: true },
    { label: 'Mẫu Tin Nhắn', href: '/templates', icon: MessageSquareQuote },
    { label: 'Gói Cước VIP', href: '/packages', icon: Package },
    { label: 'Telegram CSKH', href: '/telegrams', icon: Send },
    ...(user?.role === 'ADMIN'
      ? [{ label: 'Quản Lý Tài Khoản', href: '/users', icon: Users }]
      : []),
    { label: 'Cá Nhân', href: '/profile', icon: User },
  ];

  return (
    <>
      <header className="h-16 glass-panel border-b border-slate-800 px-4 md:px-6 flex items-center justify-between sticky top-0 z-40">
        <div className="flex items-center gap-3">
          {/* Nút Hamburger Menu Responsive cho Mobile */}
          <button
            type="button"
            onClick={() => setIsMobileMenuOpen(true)}
            className="p-2 -ml-1 rounded-xl text-slate-300 hover:text-white hover:bg-slate-800/80 md:hidden transition flex items-center justify-center focus:outline-none"
            aria-label="Mở menu điều hướng"
          >
            <Menu className="w-5 h-5 text-cyan-400" />
          </button>

          <Link href="/" className="flex items-center gap-2.5 hover:opacity-90 transition group">
            <img
              src="/logo.png"
              alt="VUT MOD TEAMS"
              className="w-8 h-8 object-contain md:hidden drop-shadow group-hover:scale-105 transition shrink-0"
            />
            <h2 className="font-semibold text-slate-200 text-xs sm:text-sm md:text-base flex items-center gap-2">
              <span className="truncate max-w-[170px] sm:max-w-none">Hệ Thống Quản Lý Bản Quyền Token</span>
              <span className="hidden lg:inline text-xs px-2 py-0.5 rounded bg-amber-500/10 text-amber-400 border border-amber-500/20 font-bold group-hover:border-amber-400/50 shrink-0">
                VUT MOD TEAMS
              </span>
            </h2>
          </Link>
        </div>

        <div className="flex items-center gap-2 sm:gap-4">
          {user && (
            <div className="flex items-center gap-2 sm:gap-3">
              <span
                className={`px-2 sm:px-2.5 py-0.5 sm:py-1 rounded-full text-[10px] sm:text-xs font-bold uppercase flex items-center gap-1 ${
                  user.role === 'ADMIN'
                    ? 'bg-amber-500/10 text-amber-400 border border-amber-500/30'
                    : 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/30'
                }`}
              >
                <ShieldCheck className="w-3 sm:w-3.5 h-3 sm:h-3.5" />
                <span className="hidden xs:inline">{user.role === 'ADMIN' ? 'Super Admin' : 'Sale Staff'}</span>
                <span className="xs:hidden">{user.role === 'ADMIN' ? 'Admin' : 'Sale'}</span>
              </span>

              <div className="flex items-center gap-2 border-l border-slate-800 pl-2 sm:pl-4">
                <div className="w-7 h-7 sm:w-8 sm:h-8 rounded-full bg-slate-800 flex items-center justify-center text-cyan-400 font-bold text-xs sm:text-sm border border-slate-700">
                  {user.displayName.charAt(0).toUpperCase()}
                </div>
                <div className="hidden sm:block text-left">
                  <div className="text-xs font-semibold text-slate-200">{user.displayName}</div>
                  <div className="text-[10px] text-slate-400">@{user.username}</div>
                </div>
              </div>

              <Link
                href="/profile"
                className="p-1.5 sm:p-2 rounded-lg bg-slate-800/60 hover:bg-slate-800 text-slate-400 hover:text-slate-200 transition"
                title="Đổi thông tin / Mật khẩu"
              >
                <KeyRound className="w-4 h-4" />
              </Link>

              <button
                onClick={handleLogout}
                className="p-1.5 sm:p-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 border border-red-500/20 transition flex items-center gap-1 text-xs font-medium"
                title="Đăng xuất"
              >
                <LogOut className="w-4 h-4" />
                <span className="hidden sm:inline">Thoát</span>
              </button>
            </div>
          )}
        </div>
      </header>

      {/* ========================================================================= */}
      {/* [MOD FEATURE]: MOBILE DRAWER NAVIGATION MENU */}
      {/* Mô tả: Ngăn kéo menu trượt mượt mà cho mobile/tablet */}
      {/* ========================================================================= */}
      {isMobileMenuOpen && (
        <div className="fixed inset-0 z-50 md:hidden flex">
          {/* Lớp nền mờ */}
          <div
            className="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity"
            onClick={() => setIsMobileMenuOpen(false)}
          />

          {/* Khung Drawer Menu */}
          <div className="relative w-72 max-w-[85vw] bg-slate-950 border-r border-slate-800 h-full flex flex-col z-10 shadow-2xl">
            {/* Header Drawer */}
            <div className="p-4 border-b border-slate-800 flex items-center justify-between">
              <Link
                href="/"
                onClick={() => setIsMobileMenuOpen(false)}
                className="flex items-center gap-2.5"
              >
                <div className="w-9 h-9 rounded-xl bg-slate-900 border border-amber-500/30 p-1 flex items-center justify-center shrink-0">
                  <img src="/logo.png" alt="Logo" className="w-full h-full object-contain" />
                </div>
                <div>
                  <h3 className="font-extrabold text-sm text-white">VUT MOD TEAMS</h3>
                  <p className="text-[10px] text-cyan-400 font-medium">Bản Quyền Mod Client</p>
                </div>
              </Link>
              <button
                type="button"
                onClick={() => setIsMobileMenuOpen(false)}
                className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
                aria-label="Đóng menu"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Thông tin tài khoản trong Drawer */}
            {user && (
              <div className="p-4 border-b border-slate-800/80 bg-slate-900/50">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-slate-800 flex items-center justify-center text-cyan-400 font-bold text-base border border-slate-700 shrink-0">
                    {user.displayName.charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="text-xs font-bold text-white truncate">{user.displayName}</div>
                    <div className="text-[11px] text-slate-400 truncate">@{user.username}</div>
                    <div className="mt-1">
                      <span
                        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                          user.role === 'ADMIN'
                            ? 'bg-amber-500/10 text-amber-400 border border-amber-500/30'
                            : 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/30'
                        }`}
                      >
                        <ShieldCheck className="w-3 h-3" />
                        {user.role === 'ADMIN' ? 'Super Admin' : 'Sale Staff'}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Danh sách liên kết điều hướng */}
            <nav className="flex-1 overflow-y-auto p-3 space-y-1">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setIsMobileMenuOpen(false)}
                    className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-semibold transition-all ${
                      isActive
                        ? item.isSvip
                          ? 'bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 shadow-md font-bold'
                          : 'bg-gradient-to-r from-sky-600 to-indigo-600 text-white shadow-md'
                        : 'text-slate-300 hover:text-white hover:bg-slate-800/60'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon className={`w-4 h-4 ${isActive ? (item.isSvip ? 'text-slate-950' : 'text-white') : 'text-slate-400'}`} />
                      <span>{item.label}</span>
                    </div>
                    {item.isSvip && (
                      <span
                        className={`text-[9px] px-1.5 py-0.5 rounded font-black uppercase ${
                          isActive
                            ? 'bg-slate-950 text-amber-300'
                            : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                        }`}
                      >
                        VIP
                      </span>
                    )}
                  </Link>
                );
              })}
            </nav>

            {/* Chân menu Drawer */}
            <div className="p-3 border-t border-slate-800 bg-slate-900/60 space-y-2">
              <button
                type="button"
                onClick={() => {
                  setIsMobileMenuOpen(false);
                  handleLogout();
                }}
                className="w-full flex items-center justify-center gap-2 px-3 py-2 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 text-xs font-semibold transition"
              >
                <LogOut className="w-4 h-4" />
                <span>Đăng xuất</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

