# AFC Ride Report (Otobüs Yolcu Takip Sistemi)

## 🇹🇷 Türkçe

### Proje Hakkında
Bu proje, Asis Elektronik'teki stajım kapsamında geliştirdiğim "Otobüs Yolcu Takip ve Biletleme Sistemi" projesinin veritabanı altyapısını içermektedir. Toplu taşıma sistemlerinde kullanılan kart ve biletlerin yönetimine yönelik olarak; fiziksel ve sanal kartlarla yapılan biniş işlemlerini, tek kullanımlık ve QR biletleri, ayrıca kredi kartı kullanımlarını SQL veritabanı üzerinden takip eden ve raporlayan bir sistemdir.

### Özellikler
- **Yolcu ve Biniş Takibi:** Otobüslere yolcu binişlerinin anlık takibi.
- **Dinamik Fiyatlandırma:** Yolcu tipine göre (Öğrenci, Tam, Ücretsiz) otomatik bilet fiyatı belirleme (Trigger ile).
- **Kapasite Kontrolü:** Otobüs kapasitesinin kontrol edilmesi ve kapasite aşıldığında binişin engellenmesi (Trigger ve Rollback Transaction ile).
- **Gelişmiş Raporlama:** Otobüs ve hat bazlı detaylı raporlamalar, toplam gelir hesaplamaları (Stored Procedure'ler ile).
- **Veri Görselleştirme Altyapısı:** Günlük toplam gelirlerin kolay takibi (View ile).

### Neler Öğrendim?
Bu staj projesi boyunca yazılım geliştirme yaşam döngüsünü veri odaklı bir bağlamda deneyimleme fırsatı buldum ve teknik becerilerimi şu konularda geliştirdim:
- **Veritabanı Tasarımı ve Yönetimi:** SQL Server Management Studio 19 (SSMS) kullanarak sıfırdan ilişkisel veritabanı tasarlama.
- **SQL Komutları (DML ve DDL):** Karmaşık `JOIN`, `GROUP BY` sorguları yazma; veri ekleme, silme ve güncelleme operasyonları.
- **Stored Procedure (Saklı Yordamlar):** Veritabanı üzerinde çalışan, parametre alan ve belirli iş mantıklarını yürüten verimli prosedürler geliştirme.
- **Trigger'lar (Tetikleyiciler):** Veritabanındaki değişikliklerde otomatik çalışan kurallar yazma (işlem iptali, fiyat ataması vb.).
- **Performans ve Optimizasyon:** Performans artırımı için uygun tablolara Index ekleme, karmaşık veri grupları için View oluşturma ve Transaction yönetimi.
- **Hata Ayıklama:** Eski kodlardaki mantık veya yapısal hataları tespit edip performansı olumsuz etkileyen kısımları düzeltme.

---

## 🇬🇧 English

### About the Project
This repository contains the database backend for the "Bus Passenger Tracking and Ticketing System" (AFC Ride Report), which I developed during my internship at Asis Elektronik. The project tracks, manages, and reports boarding transactions made with physical/virtual cards, single-use tickets, QR tickets, and credit cards across public transportation networks using an SQL database.

### Features
- **Boarding Tracking:** Real-time tracking of passenger boardings on buses.
- **Dynamic Pricing:** Automatic ticket pricing based on passenger type (Student, Adult, Free) using SQL Triggers.
- **Capacity Management:** Validating bus capacity during boarding and preventing transactions if the bus is full (using Triggers and Rollback Transactions).
- **Advanced Reporting:** Detailed bus and route-specific passenger and revenue reporting via Stored Procedures.
- **Data Summarization:** Generating daily revenue summaries using SQL Views.

### What I Learned
During this internship project, I experienced the software development lifecycle in a data-centric context and improved my technical skills in the following areas:
- **Database Design & Administration:** Designing a relational database from scratch using SQL Server Management Studio 19 (SSMS).
- **Advanced SQL (DML & DDL):** Writing complex queries using `JOIN`s and `GROUP BY`, as well as effectively managing data inserts, updates, and deletes.
- **Stored Procedures:** Developing efficient, parameterized procedures that execute core business logic directly on the database.
- **Triggers:** Automating business rules upon data changes, such as assigning dynamic ticket prices and enforcing capacity limits.
- **Performance & Optimization:** Applying Indexes to improve query performance, creating Views to simplify complex data extraction, and managing Transactions safely.
- **Troubleshooting & Debugging:** Identifying errors in legacy SQL code and refactoring it for better performance and reliability.
