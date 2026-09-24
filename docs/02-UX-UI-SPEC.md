# UX/UI Specification

## Expense Tracker Android

| Informasi | Detail |
| --- | --- |
| Versi dokumen | 1.1 |
| Versi produk | MVP V0.1 |
| Platform | Android |
| Teknologi antarmuka | Flutter |
| Bahasa | Bahasa Indonesia |
| Mata uang | Indonesian Rupiah (IDR) |
| Dokumen acuan | `docs/01-PRD.md` versi 1.0 |
| Style UI | Wise-inspired, berdasarkan style aktif `wise` dari needmcp |
| Status | Siap digunakan sebagai acuan implementasi MVP |

## 1. Tujuan Dokumen

Dokumen ini menerjemahkan kebutuhan produk dalam PRD menjadi aturan pengalaman pengguna dan antarmuka yang dapat diimplementasikan. Dokumen ini menjadi acuan untuk:

- Struktur navigasi aplikasi.
- Susunan dan perilaku setiap layar.
- Interaksi tambah, lihat, edit, dan hapus pengeluaran.
- Validasi dan feedback kepada pengguna.
- Empty, loading, success, dan error state.
- Visual foundation dan aksesibilitas dasar.

Dokumen ini tidak mengubah scope produk. Jika terdapat konflik, `docs/01-PRD.md` menjadi sumber utama.

## 2. Prinsip UX

### 2.1 Cepat Dicatat

Pengguna harus dapat mulai menambahkan pengeluaran dengan satu tindakan dari Home atau Transactions. Form hanya berisi empat field sesuai PRD.

### 2.2 Mudah Dipahami

Label, pesan, dan tindakan menggunakan Bahasa Indonesia yang sederhana. Ikon tidak digunakan sebagai satu-satunya penjelas untuk tindakan penting.

### 2.3 Fokus pada Informasi Utama

Nominal, kategori, tanggal, dan total bulanan memiliki prioritas visual tertinggi. Grafik, insight, budget, dan elemen di luar MVP tidak ditampilkan.

### 2.4 Aman dari Kesalahan

Validasi ditampilkan dekat dengan field terkait. Penghapusan selalu membutuhkan konfirmasi. Data form tidak boleh hilang ketika penyimpanan gagal.

### 2.5 Konsisten dan Offline-first

Komponen, istilah, format tanggal, dan format Rupiah harus konsisten. Seluruh alur utama tidak bergantung pada koneksi internet.

### 2.6 Berani dan Transparan

Visual menggunakan kontras kuat, tipografi tegas, ruang kosong yang lapang, serta primary lime yang energik. Gaya ini harus terasa cepat dan terpercaya tanpa menggunakan logo, nama, ilustrasi, atau aset merek Wise.

## 3. Information Architecture

```text
Expense Tracker
├── Home
│   ├── Total pengeluaran bulan berjalan
│   ├── Maksimal 5 transaksi terbaru
│   └── Tambah Pengeluaran
├── Transaksi
│   ├── Seluruh riwayat pengeluaran
│   ├── Edit transaksi
│   ├── Hapus transaksi
│   └── Tambah Pengeluaran
└── Form Pengeluaran
    ├── Tambah Pengeluaran
    └── Edit Pengeluaran
```

Home dan Transaksi adalah dua destinasi utama. Form Tambah/Edit Pengeluaran dibuka di atas destinasi utama dan tidak menjadi item navigasi utama.

## 4. Navigasi

### 4.1 Navigasi Utama

Aplikasi menggunakan bottom navigation dengan dua destinasi:

| Destinasi | Label | Ikon semantik | Tujuan |
| --- | --- | --- | --- |
| Home | Beranda | Home | Ringkasan bulan berjalan dan transaksi terbaru. |
| Transactions | Transaksi | Receipt/List | Seluruh riwayat pengeluaran. |

Aturan:

- Aplikasi pertama kali dibuka pada Home.
- Destinasi aktif memiliki ikon dan label yang terlihat jelas.
- Destinasi aktif menggunakan pill berwarna lime dengan ikon dan teks dark green; destinasi tidak aktif menggunakan teks sekunder pada surface putih.
- Perpindahan destinasi tidak membuka layar baru pada navigation stack.
- Ketika kembali dari form, pengguna kembali ke destinasi asal.
- Setelah aplikasi ditutup dan dibuka kembali, aplikasi boleh kembali ke Home.

### 4.2 Navigasi ke Form

- Home dan Transactions menyediakan floating action button dengan ikon tambah dan label **Tambah**.
- Menekan tombol tersebut membuka form dalam mode tambah.
- Memilih **Edit** dari menu transaksi membuka form dalam mode edit.
- Tombol Back pada app bar atau tombol Back Android menutup form dan kembali ke layar asal.
- Jika pengguna telah mengubah isi form, tindakan kembali menampilkan dialog konfirmasi pembuangan perubahan.
- Jika form belum berubah, tindakan kembali langsung menutup form.

### 4.3 Dialog Buang Perubahan

| Elemen | Teks |
| --- | --- |
| Judul | Buang perubahan? |
| Isi | Perubahan yang belum disimpan akan hilang. |
| Aksi sekunder | Tetap di sini |
| Aksi utama | Buang |

Menekan area di luar dialog atau tombol Back diperlakukan sama dengan **Tetap di sini**.

## 5. Wireframe Tingkat Rendah

Wireframe berikut menunjukkan hierarki, bukan ukuran piksel final.

### 5.1 Home

```text
┌─────────────────────────────────┐
│ Pengeluaran                     │
│                                 │
│ September 2026                  │
│ Total pengeluaran               │
│ Rp1.250.000                     │
│                                 │
│ Transaksi terbaru   Lihat semua │
│ ┌─────────────────────────────┐ │
│ │ [ikon] Makanan    Rp25.000  │ │
│ │        7 Sep 2026           │ │
│ │        Makan siang       ⋮  │ │
│ └─────────────────────────────┘ │
│ ... maksimal 5 transaksi ...   │
│                                 │
│                  [+ Tambah]     │
├─────────────────────────────────┤
│    Beranda        Transaksi     │
└─────────────────────────────────┘
```

### 5.2 Transactions

```text
┌─────────────────────────────────┐
│ Transaksi                       │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ [ikon] Transportasi         │ │
│ │        7 Sep 2026           │ │
│ │        Ojek       Rp18.000 ⋮│ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ [ikon] Makanan              │ │
│ │        6 Sep 2026           │ │
│ │        Rp25.000           ⋮ │ │
│ └─────────────────────────────┘ │
│                                 │
│                  [+ Tambah]     │
├─────────────────────────────────┤
│    Beranda        Transaksi     │
└─────────────────────────────────┘
```

### 5.3 Add/Edit Expense

```text
┌─────────────────────────────────┐
│ ‹  Tambah Pengeluaran           │
│                                 │
│ Nominal *                       │
│ ┌─────────────────────────────┐ │
│ │ Rp 25.000                   │ │
│ └─────────────────────────────┘ │
│                                 │
│ Kategori *                      │
│ ┌─────────────────────────────┐ │
│ │ Makanan                   ▼ │ │
│ └─────────────────────────────┘ │
│                                 │
│ Tanggal *                       │
│ ┌─────────────────────────────┐ │
│ │ 7 September 2026       [▣] │ │
│ └─────────────────────────────┘ │
│                                 │
│ Catatan                         │
│ ┌─────────────────────────────┐ │
│ │ Makan siang                 │ │
│ │                         12/100││
│ └─────────────────────────────┘ │
│                                 │
│ [          Simpan             ] │
└─────────────────────────────────┘
```

Dalam mode edit, judul berubah menjadi **Edit Pengeluaran** dan tombol utama menjadi **Simpan Perubahan**.

## 6. Spesifikasi Layar Home

### 6.1 Tujuan

Memberikan gambaran cepat total pengeluaran bulan berjalan dan akses ke transaksi yang paling baru.

### 6.2 App Bar

- Judul: **Pengeluaran**.
- Tidak memiliki tombol Back.
- Tidak menampilkan avatar, notifikasi, pencarian, atau menu pengaturan pada MVP.

### 6.3 Kartu Ringkasan Bulanan

Kartu menampilkan:

- Nama bulan dan tahun berjalan, misalnya **September 2026**.
- Label **Total pengeluaran**.
- Total dalam format Rupiah tanpa angka desimal, misalnya **Rp1.250.000**.

Aturan:

- Hanya transaksi pada bulan dan tahun kalender berjalan yang dihitung.
- Jika tidak ada transaksi pada bulan berjalan, tampilkan **Rp0**.
- Total diperbarui segera setelah transaksi ditambah, diedit, atau dihapus.
- Nominal panjang tidak boleh terpotong; ukuran teks dapat menyesuaikan sampai batas minimum yang tetap mudah dibaca.
- Kartu menjadi signature surface: background lime `#9FE870`, foreground dark green `#163300`, radius 30dp, dan padding 24dp.
- Label bulan dan total menggunakan dark green; nominal menggunakan display typography paling tegas pada layar.

### 6.4 Bagian Transaksi Terbaru

- Judul bagian: **Transaksi terbaru**.
- Menampilkan maksimal lima transaksi, diurutkan dari tanggal transaksi terbaru.
- Jika tanggal transaksi sama, transaksi yang paling terakhir dibuat ditampilkan lebih dahulu.
- Tautan **Lihat semua** membuka destinasi Transactions.
- Tautan tetap boleh ditampilkan ketika daftar kosong agar navigasi konsisten.
- Item terbaru menggunakan surface putih, radius 30dp, border sangat halus, dan tidak mengandalkan elevation tinggi.

### 6.5 Empty State Home

Jika belum ada transaksi sama sekali:

| Elemen | Isi |
| --- | --- |
| Ilustrasi/ikon | Ikon receipt atau wallet sederhana dan dekoratif. |
| Judul | Belum ada pengeluaran |
| Deskripsi | Tambahkan pengeluaran pertamamu untuk mulai mencatat. |
| Tombol | Tambah Pengeluaran |

Kartu ringkasan tetap ditampilkan dengan nilai **Rp0**. Tombol empty state dan floating action button menjalankan tindakan yang sama.

Jika transaksi ada, tetapi tidak ada transaksi pada bulan berjalan, kartu menampilkan **Rp0** dan daftar terbaru tetap menampilkan transaksi lintas bulan sesuai urutan global.

## 7. Spesifikasi Layar Transactions

### 7.1 Tujuan

Menampilkan seluruh transaksi yang tersimpan dan menyediakan akses ke tindakan edit dan hapus.

### 7.2 App Bar

- Judul: **Transaksi**.
- Tidak memiliki tombol Back.
- Pencarian, filter, pengurutan manual, dan grouping per bulan tidak disediakan pada MVP.

### 7.3 Daftar Transaksi

- Menggunakan daftar vertikal yang dapat di-scroll.
- Seluruh transaksi ditampilkan tanpa pagination pada MVP.
- Urutan mengikuti aturan pada PRD: tanggal transaksi terbaru, lalu waktu pembuatan terbaru.
- Tidak menggunakan swipe untuk edit atau hapus agar tindakan tidak tersembunyi dan mengurangi risiko penghapusan tidak sengaja.
- Item menggunakan surface putih, radius 30dp, padding 16dp pada adaptasi mobile, dan divider/border halus. Pressed state menggunakan surface muted tanpa animasi mengambang.

Setiap item menampilkan:

| Elemen | Aturan |
| --- | --- |
| Ikon kategori | Ikon konsisten sesuai kategori. |
| Nama kategori | Selalu ditampilkan. |
| Tanggal | Format ringkas, misalnya `7 Sep 2026`. |
| Nominal | Format Rupiah, rata kanan, dan memiliki prioritas visual tinggi. |
| Catatan | Ditampilkan jika ada, maksimal dua baris lalu ellipsis. |
| Menu tindakan | Tombol tiga titik dengan label aksesibilitas `Tindakan transaksi`. |

Menekan menu tindakan menampilkan:

- **Edit** dengan ikon edit.
- **Hapus** dengan ikon hapus dan warna yang menandakan tindakan destruktif.

Menekan area item di luar menu membuka form dalam mode edit. Hal ini mempercepat alur koreksi, sementara menu tetap menyediakan affordance eksplisit.

### 7.4 Empty State Transactions

| Elemen | Isi |
| --- | --- |
| Judul | Belum ada transaksi |
| Deskripsi | Pengeluaran yang kamu tambahkan akan muncul di sini. |
| Tombol | Tambah Pengeluaran |

Bottom navigation dan floating action button tetap ditampilkan.

## 8. Spesifikasi Form Add/Edit Expense

### 8.1 Mode Form

| Elemen | Mode tambah | Mode edit |
| --- | --- | --- |
| Judul app bar | Tambah Pengeluaran | Edit Pengeluaran |
| Nilai awal nominal | Kosong | Nilai transaksi saat ini |
| Nilai awal kategori | Belum dipilih | Kategori transaksi saat ini |
| Nilai awal tanggal | Hari ini | Tanggal transaksi saat ini |
| Nilai awal catatan | Kosong | Catatan transaksi saat ini |
| Tombol utama | Simpan | Simpan Perubahan |

### 8.2 Susunan dan Fokus

Urutan field:

1. Nominal.
2. Kategori.
3. Tanggal.
4. Catatan.
5. Tombol simpan.

Saat layar tambah dibuka, fokus langsung berada pada field Nominal dan keyboard numerik muncul. Saat layar edit dibuka, tidak ada field yang otomatis fokus agar pengguna dapat meninjau data terlebih dahulu.

Semua field dan tombol berada dalam area scroll agar tetap dapat diakses ketika keyboard terbuka atau pada perangkat berlayar kecil.

Semua input menggunakan surface putih, radius 10dp, border 2dp, dan tinggi minimum 52dp. Focus state menggunakan border lime dan focus indicator dark green transparan; error state menggunakan danger red.

### 8.3 Field Nominal

- Label: **Nominal \***.
- Prefix visual: **Rp**.
- Keyboard: numerik.
- Hanya menerima digit; aplikasi tidak menggunakan nilai desimal.
- Digit diformat dengan pemisah ribuan Indonesia saat diketik, misalnya `25000` menjadi `25.000`.
- Nilai yang disimpan adalah angka, bukan string terformat.
- Nilai awal kosong pada mode tambah.
- Tombol aksi keyboard berpindah ke field berikutnya jika didukung.

Validasi:

| Kondisi | Pesan |
| --- | --- |
| Kosong | Nominal wajib diisi |
| Nilai 0 | Nominal harus lebih besar dari 0 |
| Nilai tidak dapat diproses | Nominal tidak valid |
| Nilai di atas Rp999.999.999.999 | Nominal terlalu besar |

Technical Design menetapkan batas aman penyimpanan sebesar Rp999.999.999.999 per transaksi. Nilai di atas batas tidak boleh disimpan.

### 8.4 Field Kategori

- Label: **Kategori \***.
- Dibuka sebagai modal bottom sheet agar mudah digunakan dengan satu tangan.
- Hanya satu kategori dapat dipilih.
- Pilihan ditampilkan dengan ikon, label, dan indikator pilihan aktif.

Urutan kategori tetap:

1. Makanan.
2. Transportasi.
3. Belanja.
4. Tagihan.
5. Lainnya.

Jika belum dipilih, field menampilkan placeholder **Pilih kategori**.

Validasi:

| Kondisi | Pesan |
| --- | --- |
| Belum dipilih | Kategori wajib dipilih |

### 8.5 Field Tanggal

- Label: **Tanggal \***.
- Nilai awal mode tambah adalah tanggal perangkat saat ini.
- Field bersifat read-only dan dibuka melalui tap pada seluruh area field.
- Menggunakan date picker bergaya Material dengan locale Bahasa Indonesia.
- Format pada field: `d MMMM yyyy`, misalnya `7 September 2026`.
- Jika date picker dibatalkan, nilai sebelumnya tidak berubah.

PRD tidak melarang tanggal masa depan. Date picker menggunakan rentang 100 tahun sebelum sampai 100 tahun setelah tahun perangkat saat ini. Dalam mode edit, rentang harus diperluas jika diperlukan agar selalu mencakup tanggal transaksi yang sudah tersimpan.

### 8.6 Field Catatan

- Label: **Catatan**.
- Penanda opsional tidak perlu ditambahkan karena tidak ada tanda bintang.
- Placeholder: **Contoh: Makan siang bersama teman**.
- Input multiline, minimal dua baris.
- Maksimal 100 karakter.
- Character counter selalu ditampilkan dengan format `0/100`.
- Baris baru dihitung sebagai karakter.
- Catatan yang hanya terdiri dari whitespace diperlakukan sebagai kosong saat disimpan.

Jika input telah mencapai 100 karakter, karakter berikutnya tidak dimasukkan.

### 8.7 Validasi Form

- Validasi dijalankan saat pengguna menekan tombol simpan.
- Setelah percobaan simpan pertama, error pada field terkait diperbarui saat nilai berubah.
- Pesan error muncul tepat di bawah field.
- Tampilan error tidak boleh menghapus input pengguna.
- Jika lebih dari satu field tidak valid, fokus dan scroll diarahkan ke field invalid pertama.
- Form tidak disimpan selama masih ada error.

### 8.8 Proses Simpan

Saat tombol simpan ditekan dan form valid:

1. Tombol masuk ke state loading.
2. Label tombol tetap terlihat dan indikator progres ditampilkan.
3. Seluruh input dan navigasi kembali dinonaktifkan sementara untuk mencegah simpan ganda.
4. Jika berhasil, form ditutup dan layar asal diperbarui.
5. Jika gagal, form tetap terbuka dengan semua input tetap tersedia.

Feedback berhasil:

| Operasi | Snackbar |
| --- | --- |
| Tambah | Pengeluaran berhasil ditambahkan |
| Edit | Pengeluaran berhasil diperbarui |

Feedback gagal:

| Operasi | Snackbar |
| --- | --- |
| Tambah | Pengeluaran gagal disimpan. Coba lagi. |
| Edit | Perubahan gagal disimpan. Coba lagi. |

Snackbar ditampilkan pada layar yang sedang aktif dan tidak menutupi bottom navigation atau floating action button.

Tombol simpan menggunakan varian primary berukuran besar: tinggi 56dp, bentuk pill, background lime, dan teks dark green semi-bold. Snackbar menggunakan background near-black dan teks putih agar terpisah jelas dari canvas.

## 9. Penghapusan Transaksi

### 9.1 Dialog Konfirmasi

Memilih tindakan **Hapus** membuka dialog:

| Elemen | Teks |
| --- | --- |
| Judul | Hapus pengeluaran? |
| Isi | Pengeluaran ini akan dihapus secara permanen. |
| Aksi sekunder | Batal |
| Aksi destruktif | Hapus |

Aturan:

- Fokus awal tidak ditempatkan pada tombol **Hapus**.
- Tombol **Hapus** menggunakan warna error/destruktif.
- Dialog menggunakan surface putih, radius 40dp, padding 24dp, dan overlay near-black 50%.
- Tombol **Batal** menggunakan varian secondary/ghost; tombol **Hapus** menggunakan danger red dengan teks putih.
- Menekan **Batal**, tombol Back, atau area di luar dialog menutup dialog tanpa perubahan data.
- Saat proses penghapusan berlangsung, aksi dialog dinonaktifkan dan indikator progres ditampilkan.
- Tidak ada aksi undo karena PRD menetapkan penghapusan permanen dan konfirmasi wajib.

### 9.2 Feedback Penghapusan

- Berhasil: dialog ditutup, daftar dan ringkasan diperbarui, lalu snackbar **Pengeluaran berhasil dihapus** ditampilkan.
- Gagal: dialog ditutup, transaksi tetap ditampilkan, lalu snackbar **Pengeluaran gagal dihapus. Coba lagi.** ditampilkan.

## 10. System States

### 10.1 Initial Loading

- Saat penyimpanan lokal sedang dibuka dan data belum siap, tampilkan indikator progres terpusat.
- Jangan menampilkan empty state sebelum proses membaca data selesai agar tidak terjadi false empty state.
- App bar dan struktur navigasi boleh tetap terlihat.

### 10.2 Read Error

Jika data lokal gagal dibaca, tampilkan state berikut pada area konten:

| Elemen | Isi |
| --- | --- |
| Judul | Data tidak dapat dimuat |
| Deskripsi | Terjadi masalah saat membuka data pengeluaran. |
| Tombol | Coba Lagi |

Aplikasi tidak boleh menampilkan total atau daftar yang dapat disalahartikan sebagai data valid.

Error state menggunakan alert danger dengan background merah sangat ringan, ikon dan judul danger red, serta tombol retry berbentuk pill.

### 10.3 Refresh Setelah Perubahan

- UI diperbarui setelah operasi penyimpanan dinyatakan berhasil.
- Home harus memperbarui total serta transaksi terbaru.
- Transactions scroll ke posisi teratas (top) setelah setiap operasi write yang berhasil (tambah, edit, hapus), tanpa memperhatikan apakah posisi item berubah atau tidak.

### 10.4 Koneksi Internet

Tidak ada banner offline, permintaan koneksi, atau indikator sinkronisasi karena seluruh fitur MVP memang bekerja secara lokal.

## 11. Format Konten

### 11.1 Format Rupiah

- Menggunakan prefix `Rp` tanpa spasi pada teks display: `Rp25.000`.
- Menggunakan titik sebagai pemisah ribuan.
- Tidak menampilkan angka desimal.
- Nilai nol ditampilkan sebagai `Rp0`.
- Nominal tidak disingkat menjadi `rb`, `jt`, atau bentuk lain.

Pada field input, prefix `Rp` dapat dipisahkan secara visual dari digit selama hasilnya tetap terbaca sebagai satu nilai.

### 11.2 Format Tanggal

| Konteks | Format | Contoh |
| --- | --- | --- |
| Form | `d MMMM yyyy` | 7 September 2026 |
| Item transaksi | `d MMM yyyy` | 7 Sep 2026 |
| Ringkasan bulan | `MMMM yyyy` | September 2026 |

Semua nama bulan menggunakan locale Bahasa Indonesia.

### 11.3 Kapitalisasi dan Istilah

- Gunakan sentence case, bukan seluruh huruf kapital.
- Gunakan istilah **pengeluaran** untuk entitas dan **transaksi** untuk daftar riwayat.
- Gunakan **Beranda** pada label navigasi dan **Home** hanya pada dokumentasi teknis bila diperlukan.
- Hindari istilah teknis seperti database, sinkronisasi, atau exception dalam pesan pengguna.

## 12. Visual Foundation

### 12.1 Sumber dan Adaptasi Style

- Visual foundation menggunakan style aktif needmcp dengan slug `wise` sebagai sumber token dan definisi komponen.
- Material Design 3 tetap digunakan sebagai primitive perilaku Flutter, tetapi warna, tipografi, shape, border, elevation, dan state visual dioverride sesuai spesifikasi ini.
- Style diterapkan sebagai **Wise-inspired**, bukan salinan produk Wise. Aplikasi tidak menggunakan logo, nama, ikon proprietary, ilustrasi, copywriting, atau aset merek Wise.
- Blueprint web dari needmcp diterjemahkan untuk pola native Android dan batas aksesibilitas mobile.
- MVP hanya memiliki light theme. Dark theme tidak menjadi persyaratan MVP.
- Warna tidak menjadi satu-satunya pembeda state atau kategori.

### 12.2 Color Tokens

| Token aplikasi | Nilai | Sumber token Wise | Penggunaan |
| --- | --- | --- | --- |
| `primary` | `#9FE870` | Primary | CTA, FAB, selected state, kartu total. |
| `onPrimary` | `#163300` | On Primary | Teks dan ikon di atas primary. |
| `primaryHover` | `#CDFFAD` | Primary Hover | Pointer hover pada perangkat yang mendukung. |
| `primaryPressed` | `#8AD05E` | Primary Active | Pressed state CTA dan FAB. |
| `primarySubtle` | `#E2F6D5` | Primary Subtle | Highlight atau selected surface ringan. |
| `canvas` | `#FAFAFA` | Background Canvas | Latar utama aplikasi. |
| `backgroundMuted` | `#F5F6F4` | Background Muted | Section/state sekunder. |
| `surface` | `#FFFFFF` | Surface Card | Card, dialog, bottom sheet, input. |
| `surfaceMuted` | `#E8EBE6` | Surface Muted | Disabled dan pressed surface. |
| `surfaceActive` | `#E0E4DD` | Surface Active | Pressed state non-primary. |
| `textPrimary` | `#0E0F0C` | Foreground Ink | Teks utama. |
| `textSecondary` | `#454745` | Foreground Secondary | Tanggal dan informasi pendukung. |
| `textMuted` | `#686868` | Foreground Muted | Placeholder, counter, disabled text. |
| `link` | `#2D7A1A` | Link | Tindakan teks seperti **Lihat semua**. |
| `danger` | `#D03238` | Danger | Error dan tindakan hapus. |
| `dangerPressed` | `#B22A30` | Danger Active | Pressed state tindakan destruktif. |
| `success` | `#054D28` | Success | Ikon/status berhasil bila diperlukan. |
| `borderDefault` | `rgba(14,15,12,0.48)` | Border Default | Border input. |
| `borderSubtle` | `rgba(14,15,12,0.06)` | Border Subtle | Border card. |
| `divider` | `rgba(14,15,12,0.08)` | Border Divider | Divider item/section. |
| `focusRing` | `rgba(22,51,0,0.60)` | Ring Focus | Focus indicator. |
| `overlay` | `rgba(14,15,12,0.50)` | Overlay | Scrim dialog/bottom sheet. |
| `snackbar` | `#1E201C` | Dark Surface | Background snackbar. |
| `onSnackbar` | `#FCFCFC` | On Dark | Konten snackbar. |

Pasangan warna minimum yang wajib dipertahankan:

- `onPrimary` di atas `primary`.
- `textPrimary` di atas `canvas` atau `surface`.
- Putih di atas `danger`.
- `textSecondary` di atas `surfaceMuted`.

### 12.3 Category Accent Tokens

Warna kategori adalah token semantik aplikasi yang diadaptasi dari accent palette Wise. Label dan ikon tetap menjadi identitas utama.

| Kategori | Ikon Material | Background ikon | Foreground ikon |
| --- | --- | --- | --- |
| Makanan | `restaurant` | `#FFC091` | `#0E0F0C` |
| Transportasi | `directions_car` | `#38C8FF` | `#0E0F0C` |
| Belanja | `shopping_bag` | `#9FE870` | `#163300` |
| Tagihan | `receipt_long` | `#FFD11A` | `#0E0F0C` |
| Lainnya | `more_horiz` | `#E8EBE6` | `#454745` |

Background ikon berbentuk lingkaran 40dp. Ukuran ikon 20–24dp dan tidak menggantikan label kategori.

### 12.4 Typography

- Display font: **Geist**, dibundel sebagai asset lokal.
- Body font: **Inter**, dibundel sebagai asset lokal.
- Fallback: font sans-serif sistem jika asset gagal dimuat.
- Font tidak diambil dari jaringan saat runtime.

| Peran | Font | Ukuran | Berat | Line height |
| --- | --- | --- | --- | --- |
| Total bulanan | Geist | 40sp | Black 900 | 1.1 |
| Judul layar | Geist | 26sp | Black 900 | 1.1 |
| Judul dialog | Geist | 26sp | Bold/Black | 1.1 |
| Judul bagian | Inter | 18sp | Semi-bold 600 | 1.23 |
| Nominal transaksi | Inter | 16sp | Semi-bold 600 | 1.23 |
| Body utama | Inter | 16sp | Regular 400 | 1.44 |
| Body pendukung | Inter | 14sp | Regular 400 | 1.55 |
| Button | Inter | 18sp | Semi-bold 600 | 1.0 |
| Caption/counter | Inter | 12–14sp | Regular/Semi-bold | 1.55 |

Nominal besar menggunakan tabular figures jika varian font yang dibundel mendukungnya. UI harus tetap usable ketika pengguna memperbesar ukuran font melalui pengaturan Android; ukuran tidak boleh dikunci dengan mengabaikan text scaling.

### 12.5 Spacing dan Shape Tokens

- Grid dasar: 4dp.
- Padding horizontal layar: 16dp.
- Jarak antarseksi utama: 24dp.
- Jarak antarfield: 16dp.
- Spacing umum: 4, 8, 12, 16, 20, 24, 32, dan 40dp.

| Token shape | Radius | Penggunaan |
| --- | --- | --- |
| `small` | 10dp | Input, select, textarea. |
| `medium` | 16dp | Alert, selected navigation pill. |
| `large` | 30dp | Summary dan transaction card. |
| `extraLarge` | 40dp | Dialog dan top corners bottom sheet. |
| `full` | 9999dp | Button, FAB, badge, icon circle. |

### 12.6 Elevation dan Border

- Style mengutamakan border halus daripada shadow berat.
- Card default menggunakan border `borderSubtle` dan outline shadow setara `rgba(14,15,12,0.12) 0 0 0 1px`.
- Dialog menggunakan outline shadow ditambah soft shadow setara `rgba(14,15,12,0.06) 0 4px 12px`.
- Bottom navigation menggunakan divider/outline halus terhadap konten.
- Jangan menggunakan gradient, glassmorphism, atau elevation tinggi pada MVP.

### 12.7 Component Specifications

| Komponen | Spesifikasi Wise-inspired untuk mobile |
| --- | --- |
| Primary button | Tinggi 56dp, horizontal padding 32dp, pill, lime, dark green, Inter 18sp semi-bold. |
| Secondary button | Tinggi minimal 48dp, pill, transparan/putih, border 2dp, teks primary ink. |
| Ghost button | Tinggi minimal 48dp, pill, tanpa border, pressed surface muted. |
| FAB | Extended pill, lime, dark green, tinggi minimum 56dp. |
| Input/select | Tinggi minimum 52dp, radius 10dp, padding 12dp, border 2dp. |
| Textarea | Tinggi minimum 80dp, radius 10dp, padding 12dp, border 2dp. |
| Card total | Lime, dark green, radius 30dp, padding 24dp. |
| Transaction card | Surface putih, radius 30dp, padding 16dp sebagai adaptasi kepadatan mobile, border halus. |
| Dialog | Surface putih, radius 40dp, padding 24dp, overlay 50%. |
| Bottom sheet | Surface putih, radius atas 40dp, safe-area aware. |
| Bottom navigation | Surface putih, selected pill lime, selected content dark green. |
| Snackbar | Near-black, teks putih, radius 16dp, tanpa data sensitif. |
| Alert | Radius 16dp, padding 16dp, ikon + teks; danger memakai tint merah ringan. |

### 12.8 Component States dan Motion

- Default transition: 150ms untuk pressed/focus dan 200ms untuk perubahan state biasa.
- Primary pressed menggunakan `primaryPressed`; komponen boleh mengecil maksimal ke skala 0.98 pada mobile.
- Komponen non-primary pressed menggunakan `surfaceMuted` atau `surfaceActive`.
- Focus menggunakan border lime dan focus indicator yang tetap terlihat pada keyboard navigation.
- Error menggunakan border/foreground `danger`; pesan teks tetap wajib.
- Disabled menggunakan `surfaceMuted`, `textMuted`, serta opacity terbatas tanpa menghilangkan keterbacaan.
- Loading tidak mengubah lebar button; label dan progress indicator tetap berada dalam ukuran yang stabil.
- Hindari hover-only affordance karena target utama adalah touch.
- Scale/transition dinonaktifkan atau dipersingkat ketika reduce motion aktif.

## 13. Responsive Behavior

- Layout utama dioptimalkan untuk ponsel Android dalam orientasi portrait.
- Aplikasi tidak perlu memaksa orientation lock; konten tetap harus dapat digunakan pada landscape.
- Tidak boleh ada overflow horizontal pada lebar layar 320dp.
- Pada layar lebar, konten form dan daftar dibatasi pada lebar maksimum sekitar 600dp dan diposisikan di tengah.
- Bottom navigation mempertahankan dua destinasi pada seluruh ukuran ponsel.
- Safe area perangkat, navigation gesture, dan keyboard inset harus dihormati.

## 14. Accessibility

- Target sentuh minimal 48×48dp.
- Kontras teks normal minimal 4.5:1 dan teks besar minimal 3:1.
- Semua ikon interaktif memiliki semantic label.
- Ikon dekoratif tidak dibacakan oleh screen reader.
- Urutan fokus mengikuti urutan visual.
- Error field diumumkan oleh screen reader setelah validasi.
- Snackbar penting dapat diumumkan sebagai live region.
- Informasi kategori dan error selalu memiliki label teks, bukan hanya warna.
- UI harus mendukung text scaling tanpa memotong tindakan utama.
- Animasi mengikuti preferensi reduce motion perangkat jika tersedia.

Contoh semantic label:

| Komponen | Label |
| --- | --- |
| Floating action button | Tambah pengeluaran |
| Menu tiga titik | Tindakan transaksi Makanan Rp25.000 |
| Ikon tanggal | Pilih tanggal |
| Tombol Back form | Kembali |

## 15. Perilaku Tombol Back Android

| Kondisi | Perilaku |
| --- | --- |
| Berada di Home | Keluar/minimalkan aplikasi sesuai perilaku Android. |
| Berada di Transactions | Kembali ke Home. |
| Form tidak berubah | Tutup form dan kembali ke layar asal. |
| Form telah berubah | Tampilkan dialog **Buang perubahan?**. |
| Date picker/bottom sheet terbuka | Tutup komponen tersebut terlebih dahulu. |
| Dialog terbuka | Tutup dialog sebagai tindakan batal. |

## 16. Daftar Microcopy

| Konteks | Teks |
| --- | --- |
| Aksi tambah utama | Tambah Pengeluaran |
| FAB | Tambah |
| Judul form tambah | Tambah Pengeluaran |
| Judul form edit | Edit Pengeluaran |
| Simpan tambah | Simpan |
| Simpan edit | Simpan Perubahan |
| Empty Home | Belum ada pengeluaran |
| Empty Transactions | Belum ada transaksi |
| Total | Total pengeluaran |
| Daftar terbaru | Transaksi terbaru |
| Semua transaksi | Lihat semua |
| Nominal kosong | Nominal wajib diisi |
| Nominal nol | Nominal harus lebih besar dari 0 |
| Nominal di atas batas | Nominal terlalu besar |
| Kategori kosong | Kategori wajib dipilih |
| Simpan berhasil | Pengeluaran berhasil ditambahkan |
| Edit berhasil | Pengeluaran berhasil diperbarui |
| Hapus berhasil | Pengeluaran berhasil dihapus |
| Error baca | Data tidak dapat dimuat |
| Retry | Coba Lagi |

## 17. Pemetaan ke User Story

| User story | Cakupan UX/UI |
| --- | --- |
| US-01 Menambahkan Pengeluaran | FAB, form mode tambah, validasi, loading, dan feedback simpan. |
| US-02 Melihat Riwayat Pengeluaran | Destinasi Transactions, item transaksi, urutan, format, dan empty state. |
| US-03 Melihat Ringkasan Bulanan | Kartu total bulanan, transaksi terbaru, serta update setelah mutasi data. |
| US-04 Mengedit Pengeluaran | Menu/item transaksi, form prefilled, konfirmasi perubahan belum disimpan, dan feedback edit. |
| US-05 Menghapus Pengeluaran | Menu tindakan, dialog konfirmasi, loading, dan feedback hapus. |

## 18. UX Acceptance Checklist

### Navigasi

- [ ] Pengguna dapat berpindah antara Beranda dan Transaksi.
- [ ] Tambah Pengeluaran dapat diakses dari kedua destinasi utama.
- [ ] Kembali dari form mengarah ke layar asal.
- [ ] Perubahan form yang belum disimpan tidak hilang tanpa konfirmasi.

### Home

- [ ] Total bulan berjalan ditampilkan dalam format Rupiah.
- [ ] Maksimal lima transaksi terbaru ditampilkan.
- [ ] **Lihat semua** membuka seluruh transaksi.
- [ ] Empty state dan nilai `Rp0` tampil dengan benar.

### Transactions

- [ ] Semua transaksi ditampilkan dalam urutan yang benar.
- [ ] Setiap item menampilkan kategori, tanggal, nominal, dan catatan jika tersedia.
- [ ] Edit dan Hapus dapat ditemukan dari setiap item.
- [ ] Empty state mengarahkan pengguna untuk menambahkan transaksi.

### Form

- [ ] Field tampil sesuai urutan dan aturan PRD.
- [ ] Keyboard nominal bersifat numerik.
- [ ] Nominal diformat tanpa mengubah nilai sebenarnya.
- [ ] Date picker menggunakan Bahasa Indonesia.
- [ ] Catatan dibatasi 100 karakter.
- [ ] Error muncul dekat dengan field dan mencegah penyimpanan.
- [ ] Simpan ganda dicegah saat loading.
- [ ] Input tetap tersedia jika penyimpanan gagal.

### Delete

- [ ] Penghapusan selalu meminta konfirmasi.
- [ ] Batal tidak mengubah data.
- [ ] Berhasil atau gagal menghapus selalu menghasilkan feedback yang jelas.

### Accessibility dan Layout

- [ ] Target sentuh memenuhi minimum 48×48dp.
- [ ] Teks tetap terbaca pada text scaling Android.
- [ ] Semua kontrol memiliki semantic label yang sesuai.
- [ ] Tidak ada overflow pada layar kecil atau ketika keyboard terbuka.

### Wise-inspired Visual

- [ ] Primary CTA, FAB, selected navigation, dan kartu total memakai pasangan `#9FE870`/`#163300`.
- [ ] Input, card, dialog, dan button menggunakan radius serta border sesuai token komponen.
- [ ] Geist digunakan untuk display dan Inter untuk body dari asset lokal.
- [ ] Pressed, focus, disabled, loading, error, dan success state terlihat jelas.
- [ ] Tidak ada logo, nama, copywriting, atau aset merek Wise pada aplikasi.
- [ ] Tidak ada warna hardcoded di widget di luar semantic theme/category token.

## 19. Di Luar Scope Dokumen MVP

Spesifikasi ini tidak mencakup:

- Onboarding panjang atau autentikasi.
- Pencarian, filter, dan pengurutan manual.
- Grafik atau analisis kategori.
- Budget, pemasukan, saldo, dan transaksi berulang.
- Backup, sinkronisasi, dan konflik data.
- Notifikasi.
- Export atau sharing.
- Pengaturan kategori, bahasa, mata uang, dan tema.
- Tablet-specific navigation atau desktop layout.

## 20. Asumsi dan Keputusan yang Perlu Dibawa ke Dokumen Teknis

| Topik | Keputusan UX saat ini | Tindak lanjut teknis |
| --- | --- | --- |
| Nominal | Integer Rupiah, tanpa desimal, maksimum Rp999.999.999.999. | Simpan sebagai integer dan validasi pada form, domain, serta database. |
| Tanggal | Tanggal masa depan diizinkan; picker mencakup ±100 tahun dari tahun berjalan. | Gunakan representasi date-only lokal tanpa konversi timezone. |
| Urutan tanggal sama | Transaksi terakhir dibuat lebih dahulu. | Simpan metadata waktu pembuatan yang stabil. |
| State loading | Mencegah aksi ganda dan false empty state. | Definisikan state aplikasi/repository. |
| Tema | Light theme Wise-inspired berbasis style `wise` dari needmcp. | Override Material 3 melalui semantic colors, typography, shapes, elevation, dan component themes terpusat. |
| Daftar besar | Seluruh transaksi dimuat sebagai daftar scroll. | Evaluasi performa penyimpanan lokal tanpa menambah pagination prematur. |

Perubahan pada keputusan yang berdampak terhadap scope atau acceptance criteria harus diperbarui terlebih dahulu pada PRD, kemudian diselaraskan kembali ke dokumen ini.

## 21. Style Source Traceability

| Informasi | Nilai |
| --- | --- |
| Provider | needmcp |
| Active style | Wise |
| Style slug | `wise` |
| Tanggal pengambilan | 8 September 2026 |
| Mode token | Light |
| Versi definisi komponen | 2.4.0 pada hasil yang ditinjau |
| Komponen yang ditinjau | Button, card, input, select, textarea, modal, navbar, alert |
| Wireframe mobile style-specific | Tidak tersedia; wireframe produk pada bagian 5 dipertahankan |

Jika active style atau definisi needmcp berubah, pembaruan tidak diterapkan otomatis. Perubahan harus ditinjau, dipetakan ke semantic token aplikasi, diuji aksesibilitasnya, lalu menaikkan versi dokumen ini.
