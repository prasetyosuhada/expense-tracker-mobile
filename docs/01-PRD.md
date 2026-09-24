# Product Requirements Document (PRD)

## Expense Tracker Android

| Informasi | Detail |
| --- | --- |
| Versi dokumen | 1.0 |
| Versi produk | MVP V0.1 |
| Platform | Android |
| Teknologi antarmuka | Flutter |
| Target pengguna | Pengguna individual |
| Model penggunaan | Offline, satu pengguna pada satu perangkat |
| Bahasa aplikasi | Bahasa Indonesia |
| Mata uang | Indonesian Rupiah (IDR) |

## 1. Ringkasan Produk

Expense Tracker adalah aplikasi Android sederhana yang membantu pengguna individual mencatat, melihat, memperbarui, dan menghapus pengeluaran pribadi. Aplikasi juga memberikan ringkasan total pengeluaran pada bulan berjalan.

MVP V0.1 dirancang sebagai aplikasi offline. Seluruh data disimpan secara lokal pada perangkat pengguna sehingga aplikasi dapat digunakan tanpa akun, koneksi internet, atau layanan backend.

Produk ini sengaja dibatasi pada kebutuhan pencatatan pengeluaran yang paling dasar agar mudah dipahami dan digunakan, sekaligus realistis untuk dibangun sebagai proyek Android pertama.

## 2. Latar Belakang dan Masalah

Banyak orang ingin mengetahui ke mana uang mereka digunakan, tetapi tidak mencatat pengeluaran karena prosesnya terasa rumit. Aplikasi pengelolaan keuangan yang tersedia sering memiliki terlalu banyak fitur, meminta pengguna membuat akun, atau memerlukan konfigurasi sebelum dapat digunakan.

Pengguna membutuhkan cara yang cepat dan sederhana untuk:

- Mencatat pengeluaran segera setelah transaksi terjadi.
- Melihat riwayat pengeluaran.
- Mengetahui total pengeluaran bulan berjalan.
- Memperbaiki atau menghapus catatan yang keliru.

## 3. Product Vision

Menjadi aplikasi pencatatan pengeluaran pribadi yang sederhana, cepat, dan tidak membebani pengguna dengan fitur finansial yang belum mereka perlukan.

Untuk MVP V0.1, fokus produk bukan memberikan analisis finansial yang kompleks, melainkan membangun kebiasaan dasar mencatat pengeluaran secara konsisten.

## 4. Tujuan Produk

### 4.1 Tujuan Utama

- Memungkinkan pengguna mencatat pengeluaran dalam waktu singkat.
- Memungkinkan pengguna melihat seluruh pengeluaran yang pernah dicatat.
- Memungkinkan pengguna memperbaiki dan menghapus data yang salah.
- Memberikan gambaran total pengeluaran bulan berjalan.
- Memastikan seluruh fungsi utama dapat digunakan tanpa koneksi internet.

### 4.2 Non-Goals

MVP V0.1 tidak bertujuan untuk:

- Menjadi aplikasi akuntansi lengkap.
- Mengelola pemasukan, saldo, aset, utang, atau investasi.
- Memberikan rekomendasi atau nasihat finansial.
- Menghubungkan aplikasi dengan rekening bank atau e-wallet.
- Menyinkronkan data antarperangkat.
- Mendukung penggunaan oleh beberapa pengguna.
- Menggunakan AI, OCR, atau otomatisasi kategorisasi.

## 5. Target Pengguna

### 5.1 Primary User

Pengguna individual yang ingin mencatat pengeluaran sehari-hari tanpa harus memahami konsep keuangan yang kompleks.

Contoh pengguna:

- Mahasiswa.
- Fresh graduate.
- Karyawan.
- Freelancer.
- Solopreneur yang ingin memisahkan pencatatan pengeluaran pribadinya secara sederhana.

### 5.2 User Characteristics

- Menggunakan perangkat Android.
- Membutuhkan pencatatan yang cepat dan mudah.
- Tidak ingin melakukan konfigurasi yang rumit.
- Tidak selalu memiliki koneksi internet.
- Cukup melihat nominal, kategori, tanggal, catatan, dan ringkasan bulanan.

## 6. User Needs

| ID | Kebutuhan pengguna |
| --- | --- |
| UN-01 | Saya ingin mencatat pengeluaran dengan cepat agar tidak lupa. |
| UN-02 | Saya ingin melihat riwayat pengeluaran agar mengetahui transaksi yang telah dicatat. |
| UN-03 | Saya ingin melihat total pengeluaran bulan ini agar memahami jumlah uang yang telah digunakan. |
| UN-04 | Saya ingin memperbaiki transaksi apabila terjadi kesalahan pencatatan. |
| UN-05 | Saya ingin menghapus transaksi yang tidak seharusnya tercatat. |
| UN-06 | Saya ingin tetap menggunakan aplikasi tanpa koneksi internet. |

## 7. MVP Scope

### 7.1 In Scope

- Menambahkan pengeluaran.
- Melihat daftar seluruh pengeluaran.
- Menampilkan informasi dasar setiap pengeluaran.
- Mengedit pengeluaran.
- Menghapus pengeluaran dengan konfirmasi.
- Menampilkan total pengeluaran bulan berjalan.
- Menampilkan maksimal lima transaksi terbaru pada halaman utama.
- Menyimpan seluruh data secara lokal pada perangkat.
- Memvalidasi input wajib.
- Menampilkan empty state ketika belum ada data.
- Menampilkan feedback setelah operasi berhasil atau gagal.

### 7.2 Out of Scope

- Login dan registrasi.
- Multi-user dan multi-device.
- Backend, API, dan cloud database.
- Sinkronisasi dan backup cloud.
- Pencatatan pemasukan.
- Perhitungan saldo.
- Budgeting.
- Transaksi berulang.
- Filter dan pencarian lanjutan.
- Grafik dan analytics lanjutan.
- OCR atau pemindaian struk.
- AI chat input.
- Kategorisasi otomatis.
- Notifikasi.
- Ekspor CSV atau PDF.
- Integrasi bank atau e-wallet.
- Multi-currency.

Fitur di luar scope tidak boleh ditambahkan ke MVP tanpa keputusan perubahan scope.

## 8. Product Structure

MVP memiliki tiga layar utama.

| Layar | Tujuan |
| --- | --- |
| Home | Menampilkan total pengeluaran bulan berjalan dan transaksi terbaru. |
| Transactions | Menampilkan seluruh riwayat pengeluaran. |
| Add/Edit Expense | Menambahkan pengeluaran baru atau memperbarui pengeluaran yang sudah ada. |

## 9. User Stories

### US-01 — Menambahkan Pengeluaran

Sebagai pengguna, saya ingin mencatat pengeluaran agar transaksi tersebut tersimpan dan dapat saya lihat kembali.

Acceptance criteria:

- Pengguna dapat memasukkan nominal.
- Pengguna dapat memilih kategori.
- Pengguna dapat memilih tanggal transaksi.
- Pengguna dapat menambahkan catatan opsional.
- Data valid dapat disimpan.
- Transaksi baru langsung muncul dalam daftar.
- Data tetap tersedia setelah aplikasi ditutup dan dibuka kembali.

### US-02 — Melihat Riwayat Pengeluaran

Sebagai pengguna, saya ingin melihat seluruh pengeluaran yang pernah dicatat agar dapat meninjau riwayat transaksi.

Acceptance criteria:

- Seluruh transaksi yang tersimpan ditampilkan.
- Transaksi diurutkan dari tanggal terbaru ke terlama.
- Setiap transaksi menampilkan kategori, tanggal, nominal, dan catatan jika tersedia.
- Nominal ditampilkan dalam format Rupiah.
- Empty state ditampilkan jika belum ada transaksi.

### US-03 — Melihat Ringkasan Bulanan

Sebagai pengguna, saya ingin melihat total pengeluaran bulan berjalan agar mengetahui jumlah pengeluaran saya bulan ini.

Acceptance criteria:

- Home menampilkan total pengeluaran bulan dan tahun berjalan.
- Transaksi dari bulan lain tidak ikut dihitung.
- Total diperbarui setelah transaksi ditambah, diedit, atau dihapus.
- Home menampilkan maksimal lima transaksi terbaru.

### US-04 — Mengedit Pengeluaran

Sebagai pengguna, saya ingin mengedit pengeluaran agar dapat memperbaiki data yang salah.

Acceptance criteria:

- Pengguna dapat membuka transaksi dalam mode edit.
- Form menampilkan data transaksi saat ini.
- Pengguna dapat mengubah nominal, kategori, tanggal, atau catatan.
- Hanya data yang valid yang dapat disimpan.
- Perubahan langsung terlihat pada daftar dan ringkasan bulanan.

### US-05 — Menghapus Pengeluaran

Sebagai pengguna, saya ingin menghapus pengeluaran agar transaksi yang salah tidak lagi tercatat.

Acceptance criteria:

- Pengguna dapat memilih tindakan hapus pada sebuah transaksi.
- Aplikasi menampilkan dialog konfirmasi sebelum menghapus.
- Memilih batal tidak mengubah data.
- Memilih hapus menghilangkan transaksi dari penyimpanan lokal.
- Daftar dan total bulanan diperbarui setelah penghapusan.

## 10. Functional Requirements

### FR-01 — Expense Input

Aplikasi harus menyediakan form pengeluaran dengan field berikut:

| Field | Wajib | Aturan |
| --- | --- | --- |
| Nominal | Ya | Harus berupa angka, lebih besar dari 0, dan tidak melebihi Rp999.999.999.999. |
| Kategori | Ya | Harus dipilih dari kategori yang tersedia. |
| Tanggal | Ya | Menggunakan tanggal hari ini sebagai nilai awal. |
| Catatan | Tidak | Opsional. Maksimal 100 grapheme (karakter yang terlihat oleh pengguna). |

### FR-02 — Expense Categories

MVP menyediakan kategori tetap berikut:

- Makanan.
- Transportasi.
- Belanja.
- Tagihan.
- Lainnya.

Pengguna belum dapat menambah, mengubah, atau menghapus kategori.

### FR-03 — Expense History

- Aplikasi harus menampilkan seluruh transaksi yang tersimpan.
- Daftar harus diurutkan dari transaksi terbaru.
- Jika dua transaksi memiliki tanggal yang sama, transaksi yang terakhir dibuat ditampilkan lebih dahulu.

### FR-04 — Monthly Total

- Aplikasi harus menghitung total nominal transaksi pada bulan dan tahun berjalan.
- Hasil perhitungan harus diperbarui setiap kali data berubah.

### FR-05 — Edit Expense

- Aplikasi harus memungkinkan pengguna mengubah transaksi yang tersimpan.
- Validasi pada form edit harus sama dengan form tambah.

### FR-06 — Delete Expense

- Aplikasi harus meminta konfirmasi sebelum menghapus transaksi.
- Penghapusan yang dikonfirmasi bersifat permanen pada MVP.

### FR-07 — Local Persistence

- Seluruh transaksi harus disimpan secara lokal pada perangkat.
- Data harus tetap tersedia setelah aplikasi ditutup atau perangkat dimulai ulang.
- Seluruh fitur inti harus dapat digunakan tanpa koneksi internet.

### FR-08 — Input Validation

- Nominal kosong harus menampilkan pesan `Nominal wajib diisi`.
- Nominal nol atau negatif harus menampilkan pesan `Nominal harus lebih besar dari 0`.
- Kategori kosong harus menampilkan pesan `Kategori wajib dipilih`.
- Data tidak boleh disimpan jika masih terdapat input yang tidak valid.

## 11. UX Requirements

- Antarmuka menggunakan Bahasa Indonesia.
- Navigasi harus sederhana dan konsisten.
- Aksi tambah pengeluaran harus mudah ditemukan dari Home dan Transactions.
- Form harus nyaman digunakan dengan satu tangan.
- Input nominal menggunakan keyboard numerik.
- Nominal ditampilkan dalam format Rupiah, misalnya `Rp25.000`.
- Aplikasi harus memberikan feedback yang jelas setelah proses simpan, edit, dan hapus.
- Empty state harus menjelaskan tindakan berikutnya, misalnya `Belum ada pengeluaran. Tambahkan pengeluaran pertamamu.`
- Aplikasi tidak menampilkan grafik, insight, atau elemen dashboard yang tidak dibutuhkan MVP.

## 12. Non-Functional Requirements

### NFR-01 — Offline Availability

Seluruh alur utama harus dapat digunakan tanpa koneksi internet.

### NFR-02 — Performance

- Home dan daftar transaksi harus dapat dibuka tanpa jeda yang mengganggu.
- Operasi tambah, edit, dan hapus harus memberikan respons langsung kepada pengguna.

### NFR-03 — Reliability

- Aplikasi tidak boleh crash pada alur utama.
- Data yang telah berhasil disimpan tidak boleh hilang ketika aplikasi ditutup.

### NFR-04 — Usability

- Pengguna baru harus dapat memahami cara menambahkan pengeluaran tanpa onboarding panjang.
- Pesan validasi dan error harus menggunakan bahasa yang mudah dipahami.

### NFR-05 — Privacy

- Data pengeluaran tetap berada pada perangkat pengguna selama MVP.
- Aplikasi tidak mengirim data pengeluaran ke layanan eksternal.

### NFR-06 — Maintainability

- Implementasi harus sederhana dan sesuai kebutuhan MVP.
- Penambahan kompleksitas yang hanya diperlukan untuk fitur masa depan harus dihindari.

## 13. Primary User Flows

### 13.1 Add Expense

1. Pengguna membuka aplikasi.
2. Pengguna menekan **Tambah Pengeluaran**.
3. Pengguna mengisi form.
4. Pengguna menekan **Simpan**.
5. Aplikasi memvalidasi input.
6. Jika valid, aplikasi menyimpan transaksi dan memperbarui tampilan.
7. Jika tidak valid, aplikasi menampilkan pesan pada field terkait.

### 13.2 Edit Expense

1. Pengguna memilih transaksi.
2. Pengguna membuka tindakan edit.
3. Aplikasi menampilkan data transaksi saat ini.
4. Pengguna melakukan perubahan dan menyimpannya.
5. Aplikasi memperbarui transaksi dan ringkasan.

### 13.3 Delete Expense

1. Pengguna memilih tindakan hapus.
2. Aplikasi menampilkan dialog konfirmasi.
3. Pengguna memilih **Hapus** atau **Batal**.
4. Jika memilih **Hapus**, aplikasi menghapus transaksi dan memperbarui ringkasan.

## 14. Edge Cases

- Pengguna mencoba menyimpan nominal kosong.
- Pengguna memasukkan nominal nol atau negatif.
- Pengguna belum memilih kategori.
- Pengguna membatalkan date picker.
- Catatan dikosongkan.
- Belum ada transaksi sama sekali.
- Tidak ada transaksi pada bulan berjalan, tetapi terdapat transaksi pada bulan lain.
- Transaksi diedit sehingga tanggalnya berpindah ke bulan lain.
- Transaksi yang termasuk total bulan berjalan dihapus.
- Dua transaksi memiliki tanggal yang sama.

## 15. Success Criteria

MVP V0.1 dinyatakan berhasil apabila:

- Pengguna dapat menyelesaikan alur tambah, lihat, edit, dan hapus pengeluaran.
- Pengguna dapat melihat total pengeluaran bulan berjalan dengan hasil yang benar.
- Data tetap tersedia setelah aplikasi ditutup dan dibuka kembali.
- Seluruh alur utama berfungsi tanpa koneksi internet.
- Tidak ada error atau crash yang menghalangi alur utama.
- Seluruh acceptance criteria pada user stories terpenuhi.

## 16. Product Constraints and Assumptions

### Constraints

- Platform pertama hanya Android.
- Antarmuka dibuat dengan Flutter.
- Aplikasi hanya mendukung satu pengguna pada satu perangkat.
- Mata uang hanya IDR.
- Data hanya disimpan secara lokal.
- MVP harus tetap kecil dan tidak boleh berkembang menjadi aplikasi finansial lengkap.

### Assumptions

- Pengguna memasukkan transaksi secara manual.
- Pengguna bertanggung jawab atas kebenaran data yang dimasukkan.
- Pengguna tidak memerlukan sinkronisasi atau backup cloud pada MVP.
- Pengguna menerima bahwa menghapus aplikasi atau data aplikasi dapat menghapus seluruh transaksi lokal.

## 17. Risks and Mitigations

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Scope bertambah selama implementasi | MVP menjadi lambat selesai dan lebih sulit dipelajari | Terapkan daftar out-of-scope secara ketat. |
| Form terasa terlalu panjang | Pengguna malas mencatat transaksi | Batasi pada empat field dan jadikan catatan opsional. |
| Kesalahan nominal | Ringkasan bulanan menjadi tidak akurat | Terapkan input numerik dan validasi nominal. |
| Penghapusan tidak sengaja | Data pengguna hilang | Selalu tampilkan dialog konfirmasi. |
| Data hilang ketika aplikasi dihapus | Riwayat tidak dapat dipulihkan | Jelaskan keterbatasan penyimpanan lokal; backup baru dipertimbangkan setelah MVP. |

## 18. Future Roadmap

Roadmap berikut bukan bagian dari MVP V0.1.

### V0.2 — Basic Insights

- Filter tanggal dan kategori.
- Ringkasan pengeluaran per kategori.
- Grafik sederhana.

### V0.3 — Backend and Sync

- FastAPI backend.
- PostgreSQL.
- Sinkronisasi data.

### V0.4 — Account

- Login dan autentikasi.
- Penggunaan pada lebih dari satu perangkat.

### V1.0 — Assisted Expense Entry

- OCR struk.
- Kategorisasi otomatis.
- Batas penggunaan fitur AI untuk mengendalikan biaya.

## 19. Release Boundary

Versi MVP V0.1 hanya boleh dirilis jika semua user story dan success criteria telah terpenuhi. Penyelesaian MVP tidak bergantung pada tersedianya fitur V0.2 atau versi setelahnya.

