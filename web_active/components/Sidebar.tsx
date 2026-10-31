'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { LayoutDashboard, Key, Package, Users, User, ShieldAlert, Send, MessageSquareQuote, Crown, History } from 'lucide-react';

interface SidebarProps {
  userRole?: 'ADMIN' | 'SALE';
}

export default function Sidebar({ userRole }: SidebarProps) {
  const pathname = usePathname();

  const navItems = [
    { label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
    { label: 'Token Customer', href: '/tokens', icon: Key },
    { label: 'Token SVIP', href: '/svip-tokens', icon: Crown },
    { label: 'Mẫu Tin Nhắn', href: '/templates', icon: MessageSquareQuote },
    { label: 'Gói Cước VIP', href: '/packages', icon: Package },
    { label: 'Telegram CSKH', href: '/telegrams', icon: Send },
    ...(userRole === 'ADMIN'
      ? [{ label: 'Quản Lý Tài Khoản', href: '/users', icon: Users }]
      : []),
    { label: 'Cá Nhân', href: '/profile', icon: User },
  ];


  return (
    <aside className="w-64 glass-panel flex flex-col shrink-0 border-r border-slate-800 hidden md:flex min-h-screen">
      <div className="p-6 border-b border-slate-800/60">
        <Link href="/" className="flex items-center gap-3 group hover:opacity-90 transition">
          <div className="w-11 h-11 rounded-xl bg-slate-900 border border-amber-500/30 p-1 flex items-center justify-center shadow-lg shadow-amber-500/10 overflow-hidden shrink-0 group-hover:border-amber-400/60 transition">
            <img src="/logo.png" alt="VUT MOD TEAMS Logo" className="w-full h-full object-contain" />
          </div>
          <div>
            <h1 className="font-extrabold text-base text-white tracking-wide leading-snug group-hover:text-amber-300 transition">VUT MOD TEAMS</h1>
            <p className="text-[11px] text-cyan-400 font-medium">Bản Quyền Mod Client</p>
          </div>
        </Link>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = pathname === item.href || (item.href !== '/' && pathname.startsWith(item.href));

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all ${
                isActive
                  ? 'bg-gradient-to-r from-sky-600 to-indigo-600 text-white shadow-lg shadow-sky-500/20 font-semibold'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`}
            >
              <Icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
              {item.label}
            </Link>
          );
        })}
      </nav>

      <div className="p-4 m-4 rounded-xl bg-slate-900/80 border border-slate-800 text-xs text-slate-400 space-y-2">
        <div className="flex items-center gap-2 text-cyan-400 font-semibold">
          <ShieldAlert className="w-4 h-4" /> Hệ Thống Active Remote
        </div>
        <p className="text-[11px] leading-relaxed">
          Tạo token & cấp quyền tự động qua API endpoint bảo mật.
        </p>
      </div>
    </aside>
  );
}
