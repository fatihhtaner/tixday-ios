# TODO

Yeni oturumda kaldığımız yer burası. Sorumlu belirtilmemişse iş Claude'da; **Fatih** yazanlar App Store Connect, RevenueCat, cihaz gibi Fatih'in elindekiler.

## 🚨 Yayına kadar zorunlu

### Web: destek ve gizlilik
- [x] Destek sitesi üretildi (`tools/build_site.py`, 12 dil: ana sayfa, gizlilik, destek/SSS) ve `~/tixday-site`'ta commit'lendi; uygulama linkleri dile göre siteye bağlı
- [x] Site yayında: https://fatihhtaner.github.io/tixday-site/ (12 dil, tüm sayfalar 200)
- [ ] App Store Connect → App Information: Privacy Policy URL, Support URL, (isteğe bağlı) Marketing URL — **Fatih**
- [x] Alan adı kararı: şimdilik GitHub Pages (`fatihhtaner.github.io/tixday-site`)

### Uygulama içi
- [x] **Ayarlar ekranı** (ana ekranda dişli): Pro durumu (yenilenme/bitiş tarihi, ömür boyu), Pro'ya geç, geri yükle, aboneliği yönet (Apple sayfası), hatırlatmaları aç/kapat + saat, yardım/destek e-postası/gizlilik/koşullar, sürüm
- [x] Ayarlar → Dil: uygulama içi dil seçici (iPhone ile aynı + 12 dil), anında uygulanır; widget'lar ve hatırlatmalar da seçilen dili kullanır (`AppLanguage`, App Group'ta `appLanguage`)
- [ ] Ayarlar'a "Uygulamayı değerlendir" satırı: App Store'daki uygulama kimliği (Apple ID, sayısal) gerekiyor — **Fatih** App Store Connect → App Information'dan iletsin
- [x] **Gizlilik bildirim dosyası** `PrivacyInfo.xcprivacy` (uygulama + widget): takip yok, UserDefaults sebebi CA92.1 + 1C8F.1 (App Group)
- [x] **Açılış ekranı**: koyu zemin (`LaunchBackground`, `Tixday/Info.plist`)
- [x] Widget ayarında "En yakın bilet" seçeneği (varsayılan); silinen bilete sabitlenen widget en yakın bilete döner
- [x] Release kontrolü: `-sampleData`, `-resetPro`, `-proScreenshots`, `-ticketGallery`, galeri ekranı, sahte ürünler ve test anahtarı Release ikilisinde yok

### App Store Connect — **Fatih**
- [ ] App Privacy etiketi (RevenueCat: satın alma geçmişi + kullanıcı kimliği, takip yok) — adımları `docs/app-store/app-privacy.md` olarak Claude hazırlayacak
- [ ] Age Rating anketi, Content Rights, fiyat = Free, kategori (Lifestyle / Utilities)
- [ ] Abonelik grubunun görünen adı "Tixday Pro Yearly" → "Tixday Pro"
- [ ] App Review notu (Pro'ya nasıl ulaşılır, ücretsiz sınır 3) — metni Claude hazırlayacak
- [ ] RevenueCat → Small Business Program başlangıç tarihi; App Store Server Notifications URL

### Mağaza sayfası
- [ ] **Ekran görüntüleri** (6,9" iPhone, en az EN + TR; Subloom'daki gibi tasarımlı set, hedef 12 dil)
- [ ] Mağaza metinleri (ad, alt başlık, anahtar kelime, açıklama) kalan 10 dile; şu an EN + TR hazır (`fastlane/metadata`)
- [ ] Satın alma ürünlerine kalan dillerin adları/açıklamaları (`docs/app-store/in-app-purchases.md`'de hazır) — **Fatih**

### Gerçek cihaz testi (TestFlight) — **Fatih + Claude**
- [x] İlk TestFlight derlemesi yüklendi: 1.0.0 (1), 2026-10-09 (`fastlane beta`, uygulama, widget ve App Group imzaları otomatik)
- [ ] Sandbox satın alma: deneme, ömür boyu, geri yükle; iptal sonrası kilitlenen biletler
- [ ] Widget'lar: küçük/orta, bilet seçme, kilit ekranı (Pro'lu/Pro'suz), gece yarısı güncellemesi
- [ ] Bildirimler: izin, 30/7/1 gün ve etkinlik günü
- [ ] Fotoğraf: seçme, widget'ta görünme, bellek (büyük fotoğraf + widget)

## ⭐ Yayın öncesi önerilen
- [ ] **iCloud senkronu** kararı: şu an veriler sadece telefonda, telefon değişince biletler kaybolur. Model CloudKit'e hazır (Subloom'daki gibi açılabilir) — **karar Fatih**
- [ ] Onboarding / ilk açılış: boş durum var ama ilk bileti oluşturmaya yönlendiren kısa bir tanıtım yok
- [x] Pro'ya hoş geldin anı: satın alma/geri yükleme sonrası paywall yerine altın Pro bileti + damga + bilet koçanı konfetisi + kilit ekranı widget'ı nasıl eklenir (`ProWelcomeView`, DEBUG'da `-proWelcome`)
- [ ] Erişilebilirlik: en büyük yazı boyutu ve VoiceOver turu (biletler, cüzdan, paywall)
- [ ] Doğum günü posterinde beyaz başlık zayıf; o türde karartmayı artır
- [ ] Çevirileri ana dili konuşan biriyle gözden geçir (özellikle AR, JA, KO, ZH); Arapça (sağdan sola) düzeni yeni ekranlarda kontrol et
- [ ] Analitik kararı: Subloom'daki gibi SDK'sız öneriliyor (App Store Connect + RevenueCat + Xcode Organizer)
- [ ] Repo/boyut temizliği: kullanılmayan `art-*` köşe dekorları (artık her türün posteri var), `design/` içindeki eski denemeler (`plate-*`, `art-*`), PRD'deki eski tasarım anlatımı

## 🔮 Sonra (1.1+)
- [ ] Live Activity / Dynamic Island (son 24 saat canlı sayaç), StandBy
- [ ] Etkinlik günü "bilet delme" animasyonu + paylaşılabilir kart
- [ ] Varış yerine özel posterler (Tokyo, Paris, İstanbul…) — Pro poster paketleri
- [ ] Yeni bilet türleri (sinema, maç, festival, mezuniyet)
- [ ] Paylaşılan geri sayım (partner/arkadaşla aynı bilet)
- [ ] Alternatif uygulama ikonları (Pro); `app-icon-v1/v2` hazır
- [ ] Büyük boy widget

## ✅ Bitti
**Ürün ve tasarım**
- Proje (XcodeGen, uygulama + widget + test), SwiftData modeli, App Group, gün hesabı (`DayCount`)
- 6 bilet türü, vintage posterli tek bilet tasarımı (`TicketView`), kullanıcının kendi fotoğrafı
- Ana ekran: tarih + "N bilet seni bekliyor", "Sıradaki" kahraman bilet (canlı saat), Wallet destesi (yerinde açılma)
- Detay ve düzenleyici posterin bulanık atmosferinde; Liquid Glass; zoom geçişi
- Uygulama ikonu v3 (posterli bilet)
- Widget: küçük/orta + kilit ekranı (yuvarlak, dikdörtgen, satır içi), bilet seçme, gece yarısı yenileme
- Bildirimler: 30/7/1 gün ve etkinlik günü 09:00
- 12 dil (çoğul biçimleri, widget dahil)

**Gelir**
- Pro: paywall, yıllık 9,99$ (1 hafta deneme) + ömür boyu 24,99$; RevenueCat `tixday_pro`, Test Store (DEBUG) + App Store `appl_` (Release); simülatörde uçtan uca doğrulandı
- Ücretsiz: en yakın 3 yaklaşan bilet; Pro bitince veri silinmez, fazlası kilitlenir, fotoğraflar gizlenir (`TicketAccess`, testli)
- App Store Connect: uygulama kaydı, iki ürün (fiyat, deneme, EN yerelleştirme, inceleme görseli/notu)

**Altyapı**
- fastlane `beta` + `metadata`, App Store metinleri EN + TR
- 12 birim testi (gün hesabı, hatırlatmalar, erişim kuralı)
- DEBUG yardımcıları: `-sampleData`, `-resetPro`, `-proScreenshots`, `-ticketGallery`, `-proWelcome`
- Yuvarlak butonlar (`CircleIconButton`): kapatma ve ayarlar butonlarının tüm dairesi dokunulabilir (TestFlight 1.0.0 (2)'de yalnızca ortadaki simge çalışıyordu)
