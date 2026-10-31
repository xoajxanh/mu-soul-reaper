'use client';

import React, { useEffect } from 'react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

interface ToastProps {
  message: string;
  type?: 'success' | 'error' | 'info';
  onClose: () => void;
}

export default function Toast({ message, type = 'success', onClose }: ToastProps) {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, 4000);
    return () => clearTimeout(timer);
  }, [onClose]);

  const bgColors = {
    success: 'bg-emerald-950/90 border-emerald-500/50 text-emerald-200',
    error: 'bg-rose-950/90 border-rose-500/50 text-rose-200',
    info: 'bg-sky-950/90 border-sky-500/50 text-sky-200',
  };

  const Icons = {
    success: CheckCircle2,
    error: AlertCircle,
    info: Info,
  };

  const Icon = Icons[type];

  return (
    <div className={`fixed bottom-5 right-5 z-50 flex items-center gap-3 px-4 py-3 rounded-xl border backdrop-blur-md shadow-2xl transition-all animate-bounce-short ${bgColors[type]}`}>
      <Icon className="w-5 h-5 shrink-0" />
      <span className="text-sm font-medium pr-2">{message}</span>
      <button onClick={onClose} className="p-1 hover:bg-white/10 rounded-lg">
        <X className="w-4 h-4" />
      </button>
    </div>
  );
}
