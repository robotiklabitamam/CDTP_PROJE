# ÇDTP Mobil Değerlendirme Uygulaması (iPhone ↔ ESP32, BLE)

YTÜ EEF ÇDTP "İki Tekerlekli Ev İçi Hasta Destek Robotu" projesinin **Modül D (Mobil izleme ve değerlendirme)** ve **Ö4 (Mobil görsel ölçüm ve değerlendirme)** kısmı. Bu kısım Bilgisayar Mühendisliği'nin sorumluluğunda.

Uygulama şunları yapar:
- Robotla **BLE** üzerinden haberleşir.
- **Şarj** ve **eğim** bilgisini 1 Hz'de alıp gösterir.
- Robota **ileri / geri / sağ / sol / dur** komutu gönderir.
- Test sırasında robotun hareketini **telefon kamerasıyla** tespit eder ve testi **video ile kaydeder**.
- Süreleri ölçer, testin **geçti/kaldı** sonucunu otomatik verir.
- Kayıtları **değiştirilemez** biçimde saklar ve sonradan izletir.

Uygulama Flutter ile yazılır, hedef cihaz iPhone. Geliştirme Ubuntu'da yapılır, Mac kullanılmaz.

> **Claude Code için:** Bu dosya projenin spesifikasyonu. Başlamadan önce tamamını oku ve 10. bölümdeki iş sırasını izle. Şartnameden alınan kesin şartlar **[ŞARTNAME]** etiketiyle işaretli; bunlar pazarlık konusu değildir.

---

## 1. Şartnameden gelen kesin isterler (özet)

| # | İster | Karşılandığı yer |
|---|---|---|
| Ö4.1 | Uygulama robotla kablosuz iletişim kurar. Şarj durumu ve güncel eğim açısı canlı gösterilir, iletişim **1 Hz**. Bağlantı uygulama çalışırken **2 s'den fazla kopmamalı**. | 3. ve 5. bölüm |
| Ö4.2 | Robotun **hareket** bilgisi (hareket ediyor / dönüyor / statik denge / toparlanma) ve **yön** bilgisi (ileri / geri / sağ / sol) **kameradan** tespit edilir ve anlık gösterilir. | 6. bölüm |
| Ö4.3 | Arayüzden seçilen görevin başarıyla tamamlanıp tamamlanmadığı **otomatik** değerlendirilir. | 7. bölüm |
| Ö4.4 | Her test video veya zaman damgalı kayıtla **otomatik sonuç raporu** üretir. Sonuç sonradan elle "geçti" yapılamaz. | 8. bölüm |
| 5.2 | "Testi Başlat"a basıldığı an test süresinin başlangıcıdır ve video kaydı o anda başlar. Ekranda geçen süreyi gösteren bir sayaç vardır. Test elle ("Testi Bitir") ya da otomatik bitiş koşuluyla sonlanır. Süre toleransı **±2 s**, mesafe aralığı **0,8–1,2 m**. | 5.3 ve 7. bölüm |
| 5.1 | **[ŞARTNAME]** Kabul testlerinde komutlar **yalnızca eldivenden** gelir. Telefondan manuel komut kullanılamaz. | 4.3 bölüm |
| 7 | Eldiven komutlarında fiziksel tepki **2 s içinde** başlamalıdır. | 4.4 bölüm |

---

## 2. Mimari

```
 ┌───────────┐  kablosuz (ekibin seçimi)  ┌──────────────────────┐      BLE (GATT)        ┌──────────────────┐
 │  Eldiven  │ ─────── komut ───────────► │  ESP32 (robot)       │ ◄──── komut (uint8) ── │   iPhone app     │
 │ IMU / EMG │                            │  ble_link modülü     │ ── telemetri 1 Hz ───► │   (Flutter)      │
 └───────────┘                            │  + denge / motor fw  │ ── komut olayı ──────► │   + kamera       │
                                          └──────────────────────┘                        └──────────────────┘
```

- **Rol dağılımı:** ESP32 **peripheral**'dır (advertise eder, GATT server). Telefon **central**'dır.
- **Firmware sınırı:** Bu repodaki firmware yalnızca **BLE haberleşme modülüdür** (`ble_link`). Robotun denge ve motor firmware'i Kontrol ekibine ait. `ble_link` o firmware'e entegre edilecek temiz bir API sunar (bkz. 9. bölüm). Robot olmadan geliştirme yapabilmek için şarj ve eğim **dummy** değerlerle üretilir.
- **Mac gerekmez:** iOS'ta BLE central için özel bir entitlement gerekmez. Ücretsiz Apple ID ile sideload edilen uygulamada da çalışır.

---

## 3. BLE GATT protokolü (v1)

Tüm çok baytlı alanlar **little-endian**'dır. Paketler varsayılan MTU'ya (23 bayt, 20 bayt payload) sığacak şekilde tasarlandı, MTU büyütmeye gerek yoktur.

**Advertise edilen ad:** `CDTP-ROBOT`. Telefon tarama sırasında service UUID'ye göre filtreler.

| Öğe | UUID | Özellik |
|---|---|---|
| Service | `4570ee76-5ea5-486a-ad35-cd09392491e3` | |
| `TELEMETRY` | `dabc6282-5172-4642-8892-62566ad0398d` | Read, **Notify** (1 Hz) |
| `COMMAND` | `10ec17bd-3022-4505-b2fc-cd96074c5ab2` | **Write** (with response) |
| `CMD_EVENT` | `e63e1144-590d-4fda-af13-7deeb964aeef` | **Notify** (olay anında, 1 Hz'e bağlı değil) |

### 3.1 `TELEMETRY`: ESP32 → telefon, 1 Hz, 12 bayt

| Ofset | Tip | Alan | Açıklama |
|---|---|---|---|
| 0 | u8 | `version` | Protokol sürümü, şu an `1` |
| 1 | u8 | `seq` | Her pakette 1 artar ve 255'ten sonra 0'a döner. Telefon kayıp paketleri bununla tespit eder |
| 2 | u8 | `battery_pct` | 0–100. **Şimdilik dummy** |
| 3 | u8 | `flags` | bit0 `charging`: CHG/STAT pininden gelir, şimdilik dummy. bit1 `motors_enabled`. bit2 `fault`. bit3–7 rezerve |
| 4 | i16 | `tilt_cdeg` | Gövde eğimi × 100 (derece). Örneğin `-325` = −3,25°. **Şimdilik dummy** |
| 6 | u16 | `battery_mv` | Batarya gerilimi (mV), dummy. Bilinmiyorsa `0` |
| 8 | u32 | `robot_ms` | ESP32 `millis()` değeri. Olay sıralaması ve saat kayması tespiti için kullanılır |

### 3.2 `COMMAND`: telefon → ESP32, 1 bayt (`uint8`)

| Değer | Komut |
|---|---|
| `0x00` | DUR (STOP) |
| `0x01` | İLERİ |
| `0x02` | GERİ |
| `0x03` | SOLA DÖN |
| `0x04` | SAĞA DÖN |

- Bu tablonun dışındaki değerler ESP32 tarafında yok sayılır ve `CMD_EVENT` ile `status=invalid` bildirilir.
- **Kod eşlemesi:** Eldiven de robota aynı kodlarla komut gönderir. Böylece iki kaynak tek tabloyu kullanır.

### 3.3 `CMD_EVENT`: ESP32 → telefon, olay anında, 10 bayt

ESP32 **hangi kaynaktan gelirse gelsin** (telefon ya da eldiven) bir komutu işleme aldığı anda bu paketi gönderir.

| Ofset | Tip | Alan | Açıklama |
|---|---|---|---|
| 0 | u8 | `cmd_seq` | Komut sayacı |
| 1 | u8 | `cmd` | 3.2 bölümündeki kod |
| 2 | u8 | `source` | `0` = telefon, `1` = eldiven |
| 3 | u8 | `status` | `0` = uygulandı, `1` = invalid, `2` = reddedildi (fault, şarjda vb.) |
| 4 | u16 | `glove_latency_ms` | **ESP32'nin eldiven tarafında ölçtüğü süre.** Telefondan gelen komutlarda ve bilinmediğinde `0xFFFF`. Tam tanımı ekip netleştirecek (bkz. 4.4) |
| 6 | u32 | `robot_ms` | Komutun işleme alındığı an (`millis()`) |

> **Bu kanal neden 1 Hz değil:** Komut gecikmesi şartnamede 2 s sınırıyla ölçülüyor. Komut olayları 1 Hz telemetriye bindirilseydi ölçüme ±1 s hata eklenirdi. Bu yüzden komutlar ayrı bir notify kanalında, oluştukları anda gönderilir. 1 Hz kuralı yalnızca şarj ve eğim telemetrisi için geçerlidir.

### 3.4 Bağlantı kuralları

- **Bağlantı parametreleri:** Telefon tarafında bağlantı aralığı iOS'un belirlediği değerdir (genelde 15–30 ms). ESP32 tarafında supervision timeout **≤ 2 s** olarak istenir.
- **Kopma tespiti [ŞARTNAME]:** Telefon, 2 s boyunca `TELEMETRY` paketi gelmezse bağlantıyı "kopuk" sayar, ekranda uyarı gösterir ve otomatik olarak yeniden bağlanır. Her kopma (başlangıç anı ve süresi) aktif testin kaydına yazılır.
- **Güvenlik:** BLE bağlantısı koparsa ESP32 **telefondan gelmiş** son hareket komutunu iptal edip DUR uygular. Eldiven komutları bu kuraldan etkilenmez.

---

## 4. Uygulama: genel yapı

### 4.1 Sayfalar (alt navigasyon, 3 sekme)

**Her sayfada sabit üst çubuk (`StatusBar`)** bulunur:
- **Sol üst: eğim.** Örnek: `↗ −3.2°`. |eğim| > 15° iken turuncu, > 30° iken kırmızı.
- **Sağ üst: şarj.** Örnek: `🔋 78%`, şarj oluyorsa yanında ⚡.
- **Orta: BLE bağlantı durumu ikonu.** Bağlı, aranıyor ve kopuk durumları farklı ikonlarla gösterilir. Kopukken üst çubuk kırmızılaşır.
- **Veri tazeliği:** Son telemetri 2 s'den eskiyse değerler gri gösterilir ve yanında "veri yok" yazar.

| Sekme | İçerik |
|---|---|
| **1. Kontrol** | BLE cihaz tarama ve bağlantı. Büyük 5 komut butonu: yön tuşları ve ortada DUR. Son komut olayları listesi (kaynak, gecikme). |
| **2. Test** | Görev seçimi, kamera önizleme, canlı hareket/yön tespiti, süre sayacı, Testi Başlat/Bitir, sonuç ekranı. |
| **3. Kayıtlar** | Geçmiş testlerin listesi, video oynatma, ölçülen değerler, geçti/kaldı sonucu, bütünlük doğrulaması. |

### 4.2 Katmanlar

```
lib/
  ble/          RobotLink arayüzü, BleRobotLink (flutter_blue_plus), FakeRobotLink (simülasyon)
  protocol/     Paket parse/encode (saf Dart, birim testli), komut kodları, UUID sabitleri
  vision/       Kamera kare akışı → marker tespiti → poz izleme → hareket/yön sınıflandırma
  test_engine/  Görev tanımları, test durum makinesi, değerlendiriciler (saf Dart, birim testli)
  records/      Kayıt yazma, hash zinciri, okuma ve doğrulama
  ui/           pages/ (kontrol, test, kayıtlar), widgets/ (StatusBar vb.)
```

- **UI sınırı:** UI hiçbir zaman BLE'ye ya da kameraya doğrudan erişmez. Durum yönetimi tek bir yaklaşımla yapılır (Riverpod ya da ChangeNotifier/Provider; birini seç ve tutarlı kullan).
- **Simülasyon modu:** `FakeRobotLink` dummy telemetri üretir ve komutlara sahte `CMD_EVENT` döner. Ayarlardan "Simülasyon modu" ile açılır. Bu sayede UI, robot ve ESP32 olmadan geliştirilebilir.

### 4.3 Manuel komutlar ve şartname

**[ŞARTNAME]** Kabul testlerinde telefondan komut gönderilemez.

- Kontrol sekmesindeki butonlar **geliştirme ve deneme** amaçlıdır.
- **Test kipi:** Test sekmesinde test aktifken Kontrol sekmesindeki hareket butonları **devre dışı** kalır. Yalnızca DUR (acil durum) aktif kalır.
- **Kayda yansıma:** Test sırasında telefondan bir komut gönderilirse bu durum rapora `manual_command_used: true` olarak yazılır.

### 4.4 Süre ölçümleri

Bütün zaman damgaları telefonun **monotonik** saatinden alınır (`Stopwatch` ya da `SystemClock` elapsed). Duvar saati yalnızca rapor başlığında kullanılır.

| Ölçüm | Tanım |
|---|---|
| **Test süresi** | "Testi Başlat" anından bitişe kadar geçen süre. Ekranda canlı sayaç olarak gösterilir. |
| **Telefon komut üretim süresi** | Butona dokunma anından BLE write onayının (write with response) dönmesine kadar geçen süre. Her telefon komutu için kaydedilir. |
| **Eldiven gecikmesi** | ESP32'nin ölçüp `CMD_EVENT.glove_latency_ms` alanında gönderdiği değer, olduğu gibi kaydedilir. |
| **Fiziksel tepki süresi** | Komut olayı alındığı an (`CMD_EVENT` telefona ulaştığı an) ile kameranın **hareket başlangıcını** tespit ettiği an arasındaki süre. Eldiven komutlarında `glove_latency_ms` eklenerek uçtan uca süre de raporlanır. Şartnamedeki **2 s** sınırıyla karşılaştırılır. |

> **`glove_latency_ms`'in tam anlamı ekip tarafından netleştirilecek.** Örneğin "eldivenin hareketi algılamasından ESP32'nin komutu almasına kadar geçen süre" olabilir; bunun için eldiven paketine bir zaman damgası koymak gerekir. Firmware ve uygulama bu alanı şimdilik opak bir ms değeri olarak taşır.

---

## 5. Test sayfası akışı

1. **Hazırlık:** Kullanıcı görevi seçer (bkz. 7. bölüm). Göreve özel parametreler girilir, örneğin Yönlendirme görevinde beklenen yön.
2. **Ön kontrol:** Test başlamadan şu koşullar sağlanmalı:
   - BLE bağlı ve son 2 s içinde telemetri gelmiş.
   - Kamera açık ve robot marker'ı görüntüde.
   - Kalibrasyon yapılmış (bkz. 6.2).
   Eksik olan her koşul ekranda listelenir ve "Testi Başlat" butonu pasif kalır.
3. **Testi Başlat:**
   - `t0` zaman damgası alınır.
   - Video kaydı başlatılır. Kaydın gerçek başlangıç zamanı da ayrıca kaydedilir; bu, video ile olayları senkronlamak için gerekir.
   - Ekran açık tutulur (`wakelock_plus`).
4. **Test sırasında ekranda gösterilenler:**
   - Kamera önizlemesi, üzerinde marker ve izlenen yolun çizimi.
   - Büyük süre sayacı (`mm:ss.d`).
   - Anlık **hareket durumu** ve **yön** etiketi.
   - Kat edilen mesafe.
   - Komut olayları (zaman çizelgesi).
   - Üst çubukta şarj ve eğim.
5. **Bitiş:** "Testi Bitir" butonu ya da görevin otomatik bitiş koşulu. Video kaydı durdurulur.
6. **Sonuç:** Değerlendirici çalışır ve şunlar gösterilir:
   - Büyük **GEÇTİ / KALDI**.
   - Her kriterin ölçülen değeri ve eşiği.
   - Kayıt kimliği.
   Kayıt bu adımda kalıcı olarak yazılır (bkz. 8. bölüm). Bu ekranda sonucu değiştiren hiçbir kontrol yoktur.

---

## 6. Kamera ile hareket tespiti (Ö4.2)

### 6.1 Yaklaşım: ArUco marker ile poz izleme

- **Neden ArUco:** Şartname görüntü işleme yöntemini ekibe bırakıyor. ArUco hem **konum** hem **yön (yaw)** verdiği ve bilinen boyutu sayesinde **metre cinsinden mesafe** hesaplanabildiği için seçildi.
- **Robot marker'ı:** Robotun üst yüzeyinde, yere paralel duran bir marker. Önerilen ayar: `DICT_4X4_50`, ID `0`, kenar boyu **8 cm**.
- **Yük marker'ı:** İlaç kutusunun üstünde ikinci bir marker (ID `1`, 4–5 cm). Kutunun düşüp düşmediği bu marker ile tespit edilir (bkz. 7. bölüm).
- **Telefon konumu:** Tripod üzerinde, yerden yaklaşık 1–1,5 m yükseklikte, test alanına 30–45° aşağı bakacak şekilde. Bu açı üst yüzeydeki marker'ı dönüşler sırasında da görünür tutar. **[ŞARTNAME]** Telefon test boyunca sabit kalır.
- **Kütüphane:** `opencv_dart` (ArUco modülü dahil). Desteklenen platformları ve aruco API'sini **önce doğrula** (bkz. 10. bölüm, adım 2).
  - **Plan B:** OpenCV iOS'ta sorun çıkarırsa, iki renkli marker + HSV eşikleme ile kendi tespitini yaz. Tek renk konumu, iki renk arasındaki vektör yönü verir; mesafe ölçeği kalibrasyondan gelir.

### 6.2 Kalibrasyon (her kurulumda bir kez)

- **Odak uzaklığı (`fx`):** Robot marker'ı telefondan **bilinen bir mesafeye** (örneğin 1,00 m) konur, uygulama `fx = s_px · Z / S` formülüyle hesaplar (`s_px`: marker'ın görüntüdeki kenar uzunluğu, `Z`: mesafe, `S`: gerçek kenar boyu). Hesaplanan `cx, cy` görüntü merkezi kabul edilir.
- **Zemin düzlemi:** Robot başlangıç noktasındayken marker pozu "sıfır" olarak alınır. Mesafe, sonraki pozların bu noktaya göre zemin düzlemindeki yer değiştirmesidir.
- **Saklama:** Kalibrasyon değerleri uygulamada saklanır ve her test raporuna kopyalanır.

### 6.3 İşleme hattı

- **Kare kaynağı:** Video kaydı sürerken kare akışı alınır (`camera` paketindeki `startVideoRecording(onAvailable: ...)`). Bu özelliğin iOS'ta çalıştığı **adım 2'de doğrulanmalı**. Çalışmıyorsa alternatif yollar değerlendirilir.
- **İşleme:** Kareler **10–15 Hz**'e seyreltilir ve ayrı bir **isolate**'te işlenir. Eski kareler kuyrukta biriktirilmez, düşürülür.
- **Çıktı:** Her işlenen kare için `{t, x, y, yaw, marker_visible, box_visible, box_rel_pos}` üretilir. Poz değerleri kısa bir filtreden geçirilir (EMA ya da medyan).

### 6.4 Sınıflandırma (eşikler ayarlanabilir sabitler olarak tutulur)

**Hareket durumu**

| Durum | Koşul |
|---|---|
| **hareket ediyor** | Doğrusal hız > 0,05 m/s |
| **dönüyor** | Açısal hız > 15°/s ve doğrusal hız düşük |
| **statik denge** | Hız ve açısal hız eşiklerin altında, \|eğim\| < 5° (eğim BLE telemetrisinden gelir) |
| **toparlanma** | \|eğim\| > 5° ve \|eğim\| azalıyor (son iki telemetri karşılaştırılır), ya da 0,5 s altı kısa salınım |

**Yön**

| Yön | Koşul |
|---|---|
| **ileri / geri** | Yer değiştirme vektörünün robot yönelimi (yaw) üzerine izdüşümünün işareti |
| **sol / sağ** | Açısal hızın işareti |

**Hareket başlangıcı:** Komut olayından sonra hız ya da açısal hızın eşiği ilk aştığı an. Fiziksel tepki süresi bu andan hesaplanır.

---

## 7. Görevler ve otomatik değerlendirme (Ö4.3)

Görevler şartname 5.2'deki tablodan alınmıştır. Değerlendiriciler **saf Dart** fonksiyonlarıdır: ölçüm dizisini alır, `{pass, criteria[]}` döndürür ve sentetik verilerle birim testlenir.

| Görev | Modül | Başarı koşulu (hepsi sağlanmalı) | Otomatik bitiş |
|---|---|---|---|
| **Statik Denge** | A | 30 s boyunca: robot marker'ı sürekli görünür, yer değiştirme < 10 cm, \|eğim\| < 15°, kutu robot üzerinde. Ölçülen süre ≥ 30 s (±2 s). | 30 s dolunca, ya da düşme tespit edilince (\|eğim\| > 45° veya marker kaybı > 1 s) **KALDI** |
| **Robot Yönlendirmesi** | B | Hareket yönü kullanıcının seçtiği beklenen yönle aynı (ileri/geri). Net mesafe **0,8–1,2 m**. Sonunda ≥ 3 s durma. Kutu robot üzerinde. Her komutta fiziksel tepki < 2 s. | Hareket bittikten sonra 3 s statik kalınca |
| **Şarj Etme** | C | Robot durduktan sonra (kamera ile hareket bitişi) `charging` biti **≤ 5 s** içinde 1 olur. Bunu destekleyen sinyaller: eğim stabil (yerleşme), son konum kalibrasyonda işaretlenen istasyon bölgesinde. | `charging = 1` olduğunda, ya da durduktan 5 s sonra hâlâ 0 ise **KALDI** |
| **Bütünleşik Görev** | E | Başlangıçta ≥ 5 s denge → komutlarla hareket → hedefte ≥ 5 s bekleme → istasyona yönelme → `charging = 1`. Görev boyunca kutu robot üzerinde. | `charging = 1` olunca, ya da zaman aşımında (varsayılan 180 s, ayarlanabilir) |

**Kutu durumu:** Kutu marker'ı ile robot marker'ı arasındaki göreli konum test başında kaydedilir. Test sırasında bu konum 5 cm'den fazla değişirse ya da kutu marker'ı 1 s'den uzun süre görünmezken robot marker'ı görünüyorsa "kutu düştü" kabul edilir ve sonuç **KALDI** olur.

**Şarj istasyonu bölgesi:** Kalibrasyonda istasyonun konumu bir kez işaretlenir (robot istasyondayken "İstasyonu kaydet"). Şarj Etme ve Bütünleşik Görev'deki "son konum" kontrolü bu bölgeye göre yapılır.

---

## 8. Kayıtlar ve değiştirilemezlik (Ö4.4)

### 8.1 Dosya yapısı

Her test için `app_documents/records/<test_id>/` altında şu dosyalar tutulur:

| Dosya | İçerik |
|---|---|
| `video.mp4` | Test videosu |
| `events.jsonl` | Zaman damgalı tüm olaylar: telemetri, komut olayları, tespit edilen poz ve durumlar, BLE kopmaları. Satır başına bir JSON nesnesi. |
| `report.json` | Görev, parametreler, kalibrasyon, `t0`, video başlangıç ofseti, ölçülen değerler, kriterler, sonuç, uygulama sürümü, `manual_command_used`, `video_sha256`, `events_sha256`, `prev_record_hash`, `record_hash` |

### 8.2 Değiştirilemezlik kuralları

- **Yeni kayıt:** Her test yeni bir `test_id` alır (zaman + rastgele ek). Var olan bir kayıt **asla üzerine yazılmaz**.
- **Hash zinciri:** `record_hash = SHA-256(report.json'un record_hash alanı hariç kanonik JSON'u)`. Her kayıt bir önceki kaydın hash'ini (`prev_record_hash`) içerir, böylece kayıtlar bir zincir oluşturur. Zincirin başı `records/index.jsonl` dosyasında tutulur ve bu dosya yalnızca sonuna ekleme ile güncellenir.
- **Düzenleme yok:** UI'de sonucu düzenleme, yeniden değerlendirme ya da kayıt silme yoktur.
- **Doğrulama:** Kayıtlar sayfası her kayıt için video ve olay hash'lerini, ayrıca zincir bağlantısını doğrular. Sonuç "✓ bütünlük doğrulandı" ya da "✗ kayıt değiştirilmiş" olarak gösterilir.
- **Dışa aktarma:** Paylaş menüsü ile kaydın klasörü zip olarak dışa aktarılabilir.

### 8.3 Kayıtlar sayfası

- **Liste:** Tarih, görev ve GEÇTİ/KALDI rozeti.
- **Detay:** Video oynatıcı (`video_player`). Video ile olaylar `t0` ve video başlangıç ofseti üzerinden senkronlanır. Videonun altında, o andaki süre, durum, yön, eğim ve şarj değerleri gösterilir.
- **Özet:** Ölçülen değerler ve kriter tablosu, komut ve tepki süreleri, BLE kopmaları.

---

## 9. ESP32 firmware: `ble_link` modülü

- **Klasör:** `firmware/`. Proje PlatformIO ile kurulur. Ayarlar: `framework = arduino`, `board = esp32dev`; kart farklıysa kullanıcıya sor. ESP32-S2'de BLE olmadığını unutma.
- **Kütüphane:** `h2zero/NimBLE-Arduino@^2`. 2.x sürümünde callback imzaları 1.x'ten farklıdır, örnekleri sürüme göre kontrol et.
- **Dosyalar:** `src/ble_link.h` ve `src/ble_link.cpp` (entegre edilecek modül), `src/main.cpp` (dummy demo).

### 9.1 Modül API'si

Ana robot firmware'i bu API ile entegre olur:

```cpp
namespace ble_link {
  void begin(const char* name = "CDTP-ROBOT");
  // Ana döngü 1 Hz'de çağırır ya da modül kendisi 1 Hz'de gönderir:
  void setTelemetry(uint8_t batteryPct, bool charging, int16_t tiltCdeg,
                    uint16_t batteryMv, bool motorsEnabled, bool fault);
  // Telefondan komut gelince çağrılır (BLE task bağlamında; kısa tut, kuyruğa at):
  void onCommand(void (*cb)(uint8_t cmd));
  // Robot bir komutu işleme aldığında (kaynak telefon ya da eldiven) çağrılır:
  void notifyCommandEvent(uint8_t cmd, uint8_t source, uint8_t status,
                          uint16_t gloveLatencyMs = 0xFFFF);
  bool isConnected();
  void loop();   // 1 Hz telemetri zamanlaması, bağlantı izleme
}
```

### 9.2 Demo (`main.cpp`) davranışı

- **Dummy batarya:** %100'den her 10 s'de bir 1 azalır. `charging` 1 olduğunda artar.
- **Dummy eğim:** ±3° genlikli yavaş sinüs ve üzerine küçük gürültü.
- **Seri port komutları (115200 baud):**
  - `c`: `charging` bitini değiştirir. Şarj Etme testini denemek için.
  - `g0` … `g4`: Eldivenden komut gelmiş gibi davranır. Rastgele bir `glove_latency_ms` (50–300) ile `CMD_EVENT` gönderir.
  - `t<sayı>`: Eğimi sabit bir değere zorlar (×100). Örneğin `t1500` = 15°.
- **Telefon komutları:** Gelen her komut seri porta yazılır, kart LED'i yanıp söner ve `CMD_EVENT(source=0)` gönderilir.
- **Bağlantı kopunca:** Telefondan gelmiş son komut iptal edilir (DUR) ve yeniden advertise başlar.
- **Loop kuralı:** `loop()` hiç bloklanmaz, `delay()` kullanılmaz, zamanlamalar `millis()` ile yapılır.

---

## 10. Claude Code iş sırası

Her adımın sonunda belirtilen doğrulamayı çalıştır, geçmeden bir sonraki adıma geçme. Riskli kısımlar (adım 2) bilerek en başa alındı.

1. **Ortam ve iskelet**
   - `flutter --version` ve `flutter doctor` çalıştır. Flutter yoksa **kurmayı deneme**, kullanıcıya 11. bölümü göster ve dur.
   - Mevcut repo içeriği yalnızca README, CI workflow'u ve `scripts/` klasöründen oluşur. `flutter create --platforms=ios,android --org com.fatih --project-name cdtp_robot_app .` komutunu çalıştır.
   - Paketleri ekle: `flutter_blue_plus`, `camera`, `video_player`, `path_provider`, `crypto`, `wakelock_plus`, `share_plus`, `opencv_dart`, ayrıca seçilen durum yönetimi paketi.
   - `flutter_blue_plus`'ın güncel lisans koşullarını kontrol et ve kullanıcıya özetle. Uygun değilse `flutter_reactive_ble` kullan.
   - Android izinlerini ekle: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `CAMERA`, ayrıca eski sürümler için konum izni.
   - **Doğrulama:** `flutter analyze` hatasız.
2. **Risk spike'ı (önce bunlar)**
   - (a) `opencv_dart` ile ArUco tespiti Android'de çalışıyor mu?
   - (b) `camera` paketiyle video kaydı ve kare akışı aynı anda alınabiliyor mu?
   - Her ikisi için küçük bir deneme sayfası yaz. Kullanıcıdan Android telefonda denemesini iste, iOS'u CI build'iyle denettir.
   - Çalışmayan kısım varsa 6.1'deki plan B'yi kullanıcıyla konuş.
3. **Protokol**
   - `lib/protocol/` altında 3. bölümdeki paketlerin parse/encode kodunu, UUID'leri ve komut kodlarını yaz.
   - **Doğrulama:** `flutter test`. Sınır değerler (negatif eğim, seq taşması, bilinmeyen komut) için testler dahil.
4. **Firmware**
   - `firmware/` altında 9. bölümdeki modülü ve demoyu yaz.
   - **Doğrulama:** `pio run` başarılı.
   - Kullanıcıdan kartı yükleyip nRF Connect (telefon uygulaması) ile servisleri ve 1 Hz notify'ı kontrol etmesini iste.
5. **BLE katmanı ve Kontrol sayfası**
   - `RobotLink`, `BleRobotLink` ve `FakeRobotLink` sınıflarını yaz. Yeniden bağlanma ve 2 s telemetri watchdog'u dahil.
   - `StatusBar`'ı ve Kontrol sayfasını yaz.
   - **Doğrulama:** Simülasyon modunda widget testleri. Gerçek ESP32 ile kullanıcı denemesi.
6. **Test motoru**
   - `lib/test_engine/` altında görev tanımlarını, durum makinesini ve 7. bölümdeki değerlendiricileri yaz.
   - **Doğrulama:** Her görev için hem geçen hem kalan sentetik senaryo testleri. Bunlara ±2 s sınırı, 0,79 / 0,81 / 1,19 / 1,21 m sınırları, kutu düşmesi ve 5 s şarj sınırı dahil.
7. **Görüntü hattı**
   - `lib/vision/` altında kalibrasyonu, poz izlemeyi ve 6.4'teki sınıflandırmayı yaz. Sınıflandırıcıyı sentetik poz dizileriyle birim testle.
8. **Test sayfası**
   - 5. bölümdeki akışı yaz. Kayıt yazma işi adım 9'a bağlanacak.
9. **Kayıtlar**
   - `lib/records/` altında yazma, hash zinciri ve doğrulama kodunu yaz. Kayıtlar sayfasını ve video oynatmayı ekle.
   - **Doğrulama:** Bir kayıt dosyası elle değiştirildiğinde doğrulamanın "✗" verdiğini gösteren bir test.
10. **CI**
    - `scripts/patch_info_plist.sh` ve workflow'u yeni paketlere göre kontrol et.
    - **Doğrulama:** GitHub Actions'ta IPA üretiliyor.

### Genel kurallar

- **Protokol senkronu:** Protokolde yapılan her değişiklik aynı commit'te üç yere birden yansır: bu README (3. bölüm), `lib/protocol/` ve `firmware/src/ble_link.*`.
- **[ŞARTNAME] etiketli kurallar:** Gevşetme. Gerekçeli bir değişiklik gerekiyorsa önce kullanıcıya sor.
- **Robota özel değerler:** Gerçek batarya ölçümü, IMU okuması, motor sürme gibi robota özel kısımları tahmin etme. Dummy değerlerle ilerle ve kodu `TODO(robot):` ile işaretle.
- **Eşikler:** Tüm eşikler ve sabitler tek bir yerde tutulur (`lib/test_engine/thresholds.dart`). Hepsi rapora da yazılır.

---

## 11. Geliştirme ortamı (Ubuntu)

### 11.1 Flutter SDK (zorunlu)

```bash
sudo apt update
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa
sudo snap install flutter --classic      # ya da docs.flutter.dev'deki tarball kurulumu
flutter doctor
```

`flutter doctor` çıktısındaki Xcode uyarıları normaldir. iOS build'i CI'da yapılır.

### 11.2 Android (önerilen ana test cihazı)

Bu uygulamada BLE ve kamera birlikte kullanıldığı için masaüstü (Linux) hedefi pratik değil. Günlük geliştirme ve deneme **Android telefonda** yapılır.

```bash
sudo snap install android-studio --classic   # ilk açılışta SDK'yı kurar
flutter doctor --android-licenses
# Telefonda Geliştirici seçenekleri → USB hata ayıklama açılır, sonra:
flutter devices
flutter run
```

Android telefon yoksa her deneme CI üzerinden iPhone'a kurulmak zorunda kalır. Bu çok daha yavaş bir döngüdür.

### 11.3 Firmware

```bash
pipx install platformio
sudo usermod -aG dialout $USER     # sonra oturumu kapatıp aç
cd firmware && pio run -t upload && pio device monitor -b 115200
```

BLE servislerini uygulamadan bağımsız denetlemek için telefona **nRF Connect** uygulaması kurulur.

---

## 12. iPhone'a kurulum (Mac olmadan)

1. Repoyu GitHub'a push et. Ücretsiz macOS dakikaları için repo public olmalı.
2. `.github/workflows/ios-unsigned-ipa.yml` workflow'u imzasız bir IPA üretip artifact olarak yükler.
3. iPhone'da **Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu** açılır.
4. IPA, **SideStore** ile ücretsiz Apple ID kullanılarak kurulur. Adımlar için docs.sidestore.io'daki Linux kurulumuna bak. Ücretsiz Apple ID'nin kısıtları: imza 7 günde bir yenilenmeli, aynı anda en fazla 3 uygulama kurulu olabilir.
5. Uygulama ilk açılışta **Bluetooth** ve **Kamera** izinlerini ister; ikisine de izin verilmeli. Mikrofon izni istenmez, çünkü video sessiz kaydedilir.
6. **Final öncesi:** İmzanın final günü dolmaması için finalden bir gün önce SideStore'da imzayı yenile.
