import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'VUT MOD TEAMS - Quản Lý Bản Quyền Token Remote',
  description: 'Hệ thống quản lý active token từ xa cho VUT MOD TEAMS Android Mod',
  icons: {
    icon: '/favicon.ico',
    shortcut: '/logo.png',
    apple: '/logo.png',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" className="dark">
      <head>
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <link rel="icon" type="image/png" href="/logo.png" />
        <link rel="apple-touch-icon" href="/logo.png" />
      </head>
      <body className={inter.className}>
        <div className="min-h-screen bg-[#0b0f19] text-slate-100 flex flex-col antialiased">
          {children}
        </div>
      </body>
    </html>
  );
}
