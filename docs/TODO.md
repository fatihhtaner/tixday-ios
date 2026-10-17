# TODO

Yeni oturumda kaldığımız yer burası. Sorumlu belirtilmemişse iş Claude'da; **Fatih** yazanlar App Store Connect, RevenueCat, cihaz gibi Fatih'in elindekiler.

## 🚨 Yayına kadar zorunlu

### Web: destek ve gizlilik
- [x] Destek sitesi üretildi (`tools/build_site.py`, 12 dil: ana sayfa, gizlilik, destek/SSS) ve `~/tixday-site`'ta commit'lendi; uygulama linkleri dile göre siteye bağlı
- [x] Site yayında: https://fatihhtaner.github.io/tixday-site/ (12 dil, tüm sayfalar 200)
- [x] Privacy / Support / Marketing URL'leri 12 dilde `fastlane metadata` ile yüklendi (2026-10-16)
- [x] Alan adı kararı: şimdilik GitHub Pages (`fatihhtaner.github.io/tixday-site`)

### Uygulama içi
- [x] **Ayarlar ekranı** (ana ekranda dişli): Pro durumu (yenilenme/bitiş tarihi, ömür boyu), Pro'ya geç, geri yükle, aboneliği yönet (Apple sayfası), hatırlatmaları aç/kapat + saat, yardım/destek e-postası/gizlilik/koşullar, sürüm
- [x] Ayarlar → Dil: uygulama içi dil seçici (iPhone ile aynı + 12 dil), anında uygulanır; widget'lar ve hatırlatmalar da seçilen dili kullanır (`AppLanguage`, App Group'ta `appLanguage`)
- [x] Ayarlar → "Tixday'i Değerlendir" (App Store yorum sayfası, Apple ID `6820981179`)
- [x] Gün değişince ana ekran yenilenir (arka planda açık kalsa bile)
- [x] Widget'a dokununca o bilet açılır (kilitliyse paywall); hatırlatmaya dokununca o bilet açılır; uygulama açıkken hatırlatmalar banner olarak görünür (`DeepLink`, `LinkRouter`, `AppDelegate`)
- [x] **Gizlilik bildirim dosyası** `PrivacyInfo.xcprivacy` (uygulama + widget): takip yok, UserDefaults sebebi CA92.1 + 1C8F.1 (App Group)
- [x] **Açılış ekranı**: koyu zemin (`LaunchBackground`, `Tixday/Info.plist`)
- [x] Widget ayarında "En yakın bilet" seçeneği (varsayılan); silinen bilete sabitlenen widget en yakın bilete döner
- [x] Release kontrolü: `-sampleData`, `-resetPro`, `-proScreenshots`, `-ticketGallery`, galeri ekranı, sahte ürünler ve test anahtarı Release ikilisinde yok

### App Store Connect — **Fatih**
- [x] App Privacy etiketi yayınlandı — adımlar `docs/app-store/app-privacy.md` (yalnızca Purchases → Purchase History, App Functionality, kimliğe bağlı değil, takip yok) — **Fatih**
- [x] Düğün posteri kadehsiz (yüzüklü eller) yenilendi, alkol tasviri yok → yaş derecelendirmesinde Alcohol = None, hedef 4+ (2026-10-16). IAP inceleme görseli `docs/app-store/review-paywall.png` yeni posterle yeniden çekildi; App Store Connect'te iki ürüne yeniden yüklenmeli — **Fatih**
- [x] Age Rating anketi → 4+ (Fatih); kategoriler Lifestyle / Utilities (fastlane)
- [x] Content Rights (No), fiyat = Free
- [x] 1.0.0 → Build: 1.0.0 (8) seçildi
- [x] Yıllık + ömür boyu ürün incelemeye eklendi; build 1.0.0 (9)
- [ ] İki ürünün inceleme görselini `docs/app-store/review-paywall.png` (yeni düğün posterli) ile değiştir — **Fatih**
- [x] Ürün sayfası üst görseli yüklendi
- [x] Abonelik grubunun görünen adı 12 dilde "Tixday Pro" (API ile, 2026-10-16)
- [x] App Review notu: `fastlane/metadata/review_information/notes.txt`
- [x] App Review iletişim bilgileri (Fatih) + inceleme notu (fastlane metadata, 2026-10-17) — eski not: App Store Connect → 1.0.0 → App Review Information'a gir (fastlane telefonsuz kaydı oluşturamıyor), sonra `fastlane metadata` notu da yükler
- [x] App Store Server Notifications URL (RevenueCat) girildi
- [ ] RevenueCat → Small Business Program başlangıç tarihi — **Fatih** (Apple'dan onay bekleniyor, 2026-10-17)

### Mağaza sayfası
- [x] **Ekran görüntüleri**: 12 dil × 5 kare (ana ekran, widget'lar, yıllık doğum günü, editör, damga), 6,9" 1320×2868 JPEG → `fastlane/screenshots/<dil>/`. Ham ekranlar `tools/capture_store_screens.sh`, metinler `docs/app-store/screenshot-texts.json`, kompozisyon `swift tools/make_store_screenshots.swift <ham> fastlane/screenshots`
- [x] Ekran görüntüleri yeni tasarımla (her kare farklı düzen) 12 dilde App Store Connect'e yüklendi (2026-10-16)
- [x] Mağaza metinleri 12 dilde (ad, alt başlık, anahtar kelime, açıklama — yeni özellikler dahil) yüklendi; App Store sürümü 1.0.0
- [x] Satın alma ürünlerinin 12 dilde adları/açıklamaları yüklendi (API ile, 2026-10-16)

### Gerçek cihaz testi (TestFlight) — **Fatih + Claude**
- [x] (2026-10-15) **iCloud şeması yeniden gönderildi — Fatih:** modele `repeatsYearly` eklendi. iPhone'da `-initCloudKitSchema` ile bir kez çalıştır, CloudKit Console → Deploy Schema Changes. Yapılmazsa TestFlight'ta yeni alan senkronlanmaz
- [x] iCloud (TestFlight'ta doğrulandı, 2026-10-17)
- [x] İlk TestFlight derlemesi yüklendi: 1.0.0 (1), 2026-10-09 (`fastlane beta`, uygulama, widget ve App Group imzaları otomatik)
- [x] Sandbox satın alma (doğrulandı, 2026-10-17)
- [x] Widget'lar (doğrulandı, 2026-10-17)
- [x] Bildirimler (doğrulandı, 2026-10-17)
- [x] Fotoğraf: seçme, kadraj (sürükle/yakınlaştır), bilette ve widget'ta görünme — TestFlight 1.0.0 (7)'de doğrulandı (2026-10-16)

## ⭐ Yayın öncesi önerilen
- [x] **iCloud senkronu** (kod): özel iCloud veritabanı `iCloud.com.ibrahimfatihtaner.tixday`, widget yerel kopyayı okur; Ayarlar'da iCloud durumu + Tekrar Dene (`SyncMonitor`); senkronla gelen değişiklikte widget yenilenir
- [x] **iCloud kurulumu — Fatih (bu yapılmadan `fastlane beta` imzalamada hata verir):**
  1. ✅ Xcode → Settings → Accounts: Apple ID ekli olsun
  2. ✅ (2026-10-15, cihaz için imzalama doğrulandı) `xcodegen generate`, `Tixday.xcodeproj`'u aç → Tixday hedefi → Signing & Capabilities: iCloud (CloudKit, `iCloud.com.ibrahimfatihtaner.tixday`) ve Push Notifications görünür; Xcode kapsayıcıyı ve profili kendisi oluşturur (hata varsa "Try Again")
  3. ✅ iCloud'a giriş yapılmış iPhone'da Xcode'dan Debug çalıştır, Scheme → Arguments'a `-initCloudKitSchema` ekle; konsolda "schema initialized" görünce argümanı kaldır
  4. ✅ (2026-10-15) https://icloud.developer.apple.com → Tixday kapsayıcısı → Schema → **Deploy Schema Changes** (Production). TestFlight ve App Store Production'ı kullanır; bu yapılmadan TestFlight'ta senkron çalışmaz
- [x] Onboarding: ilk açılışta (bilet yoksa) 4 sayfa — bilet destesi, widget'lar, widget nasıl eklenir + bilet seçimi (canlı örnek), hatırlatmalar — sonra "İlk biletimi oluştur" editörü açar (`OnboardingView`, DEBUG'da `-onboarding`). Bildirim izni ilk bilet kaydedilince istenir
- [x] Pro'ya hoş geldin anı: satın alma/geri yükleme sonrası paywall yerine altın Pro bileti + damga + bilet koçanı konfetisi + kilit ekranı widget'ı nasıl eklenir (`ProWelcomeView`, DEBUG'da `-proWelcome`)
- [ ] Erişilebilirlik: en büyük yazı boyutu ve VoiceOver turu (biletler, cüzdan, paywall)
- [ ] Doğum günü posterinde beyaz başlık zayıf; o türde karartmayı artır
- [ ] Çevirileri ana dili konuşan biriyle gözden geçir (özellikle AR, JA, KO, ZH); Arapça (sağdan sola) düzeni yeni ekranlarda kontrol et
- [ ] Analitik kararı: Subloom'daki gibi SDK'sız öneriliyor (App Store Connect + RevenueCat + Xcode Organizer)
- [x] Boyut temizliği: kullanılmayan `art-*` köşe dekorları ve yedek kodu kaldırıldı (uygulama + widget), `design/` içindeki eski `plate-*`, `art-*` silindi (2026-10-17)
- [ ] PRD'deki eski tasarım anlatımı

## 🔮 Sonra (1.1+)
- [ ] Live Activity / Dynamic Island (son 24 saat canlı sayaç), StandBy
- [ ] Etkinlik günü "bilet delme" animasyonu + paylaşılabilir kart
- [ ] Poster paketleri (Tokyo, Paris, İstanbul, retro sinema…) — Pro'ya dahil ya da ayrı satış. Karar (2026-10-10): ayrı "modern tema" yok; vintage poster kimliği korunur, çeşitlilik paketlerle gelir
- [ ] Yeni bilet türleri (sinema, maç, festival, mezuniyet)
- [ ] Paylaşılan geri sayım (partner/arkadaşla aynı bilet)
- [ ] Alternatif uygulama ikonları (Pro); `app-icon-v1/v2` hazır
- [ ] Büyük boy widget

## ✅ Bitti
**Ürün ve tasarım**
- Fotoğraf kadrajı: fotoğraf seçilince bilet şeklinde (1,6:1) çerçeve açılır, sürükle/yakınlaştır; kesik kare küçük widget alanını gösterir. Seçilen kadraj fotoğrafa işlenir (yeni model alanı yok, iCloud şeması değişmedi); fotoğraflar her yerde ortalanır. Editörde Ayarla / Değiştir / Kaldır (`PhotoCropView`)
- Her yıl tekrarlayan biletler (doğum günü ve tatilde varsayılan açık): `date` orijinal tarihi tutar, her yer `upcomingDate` / `DayCount.nextOccurrence` ile bir sonraki yıl dönümüne sayar (29 Şubat dahil, testli)
- Tamamlanan bilete "ONAYLANDI" damgası: detayda titreşimle iner, "Kullanıldı" kartında gri bilet üstünde kırmızı, widget'ta da var (`AdmittedStamp`)
- Puan isteme: ikinci bilet oluşturulunca ya da bir biletin günü gelince, en fazla 4 ayda bir (`ReviewPrompt`)
- Paylaşılan bilet resmi koyu kart üstünde, altında "Tixday ile yapıldı"
- Kartlara ve kahraman bilete uzun basınca menü: Düzenle (doğrudan editör), Paylaş (resim, sadece paylaşırken çizilir), Sil (onaylı). Kilitli biletlerde yalnızca Sil. Kaydırarak düzenle/sil bilerek yok (cüzdan destesinde kartlar üst üste)
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
