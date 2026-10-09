# Tixday — bilet temalı geri sayım widget uygulaması

Pasif gelir amaçlı, sunucusuz bir iOS uygulaması. App Store adı: **Tixday – Countdown Widgets**. Kullanıcı (Fatih) Türkçe konuşur; yanıtlar Türkçe, kod/yorumlar İngilizce.

## Önce oku
- `docs/PRD.md` — ürün tanımı, rakipler, gelir modeli, tasarım kuralları
- `docs/TODO.md` — yapılacaklar listesi. **Her adım bitince güncelle.** Yeni oturumda kaldığımız yer burası.

## Proje
- XcodeGen: `project.yml` → `xcodegen generate`. `Tixday.xcodeproj` git'e eklenmez; hedef/ayar değişikliği `project.yml` içinde yapılır.
- iOS 17+, SwiftUI, SwiftData, WidgetKit, Swift 5 dil modu.
- Kimlikler: `com.ibrahimfatihtaner.tixday`, widget `com.ibrahimfatihtaner.tixday.widget`, App Group `group.com.ibrahimfatihtaner.tixday`.
- Widget, `Tixday/Models`, `Tixday/Support` ve `Tixday/Tickets` klasörlerini uygulamayla paylaşır. Bu klasörlere uygulamaya özel (UIKit ekranı, `WidgetCenter` dışı servis vb.) kod koyma.

## Komutlar
```bash
xcodegen generate
xcodebuild -project Tixday.xcodeproj -scheme Tixday -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build
xcodebuild -project Tixday.xcodeproj -scheme Tixday -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build test
```
Yayın: `fastlane beta` (TestFlight), `fastlane metadata` (App Store metinleri) — bkz. `docs/app-store/fastlane.md`.

Örnek biletlerle açmak için uygulamayı `-sampleData` argümanıyla başlat (yalnızca DEBUG, boş veritabanını doldurur).

## Kurallar
- SwiftData modelleri CloudKit uyumlu kalmalı: her alanın varsayılan değeri olmalı, `@Attribute(.unique)` yok, ilişkiler opsiyonel. Enum'lar `String` raw value olarak saklanır (`kindRaw`).
- Bilet görünümleri `TicketSnapshot` (değer tipi) alır, SwiftData nesnesi almaz.
- Her türün renkleri ve yazı tipi `TicketKind.style` (`Tickets/TicketStyle.swift`). Yeni tür = yeni `TicketKind` case + stil + poster. Tasarım incelemesi: uygulamayı `-ticketGallery` ile aç (DEBUG).
- Gün sayımı takvim günüdür (yarın her zaman 1); `DayCount` dışında gün hesabı yapma.
- Pro bitince hiçbir veri silinmez: hangi biletlerin açık olduğu tek yerde, `TicketAccess.unlockedIDs` (en yakın 3 yaklaşan + geçmişler). Fotoğraf gizleme `TicketEvent.snapshot` içinde (`TicketAccess.isPro`).
- Satın alma: `ProStore` (RevenueCat), entitlement `tixday_pro`, ücretsiz sınır 3 bilet. DEBUG'da anahtar yoksa sahte ürünler; `-resetPro` ücretsize, `-proScreenshots` Pro'ya zorlar. Test anahtarı asla Release'e girmemeli. Pro bayrağı App Group'ta (`AppGroup.proUnlockedKey`), widget kilit ekranı boyutlarını buna göre açar.
- Bir etkinlik kaydedildiğinde/silindiğinde `WidgetCenter.shared.reloadAllTimelines()` çağrılır. Hatırlatmalar `TicketListView`'daki `.task(id: reminderSignature)` ile otomatik yeniden planlanır; ayrıca çağırmaya gerek yok.
- Kullanıcıya görünen metinler String Catalog'da: `Tixday/Resources/Localizable.xcstrings` (uygulama ve widget ortak). EN kaynak + 11 dil (TR, DE, FR, ES, IT, PT-BR, JA, KO, ZH-Hans, RU, AR). Yeni metin ekleyince build al, `find build \( -path '*Tixday.build*' -o -path '*TixdayWidget.build*' \) -name '*.stringsdata' -not -path '*Tests*' -print0 | xargs -0 xcrun xcstringstool sync Tixday/Resources/Localizable.xcstrings --stringsdata` ile katalogu güncelle ve 11 dile çevir.
- Gün birimleri ("%lld DAYS", "%lld DAYS TO GO", "%lld days to go") çoğul varyasyonlu; Xcode her biçimde sayıyı şart koştuğu için çeviride sayı var, ekranda `CountLabel.unit` onu siler (sayı ayrıca büyük çizilir). RU/AR'de tüm çoğul biçimlerini doldur.
- Bilet tasarımı (tek tasarım, `TicketView`): gövde = `poster-<tür>-wide/square` varsa poster (beyaz yazı + karartma), yoksa türün kâğıt rengi + `art-<tür>` köşe dekoru; sağda/altta `stubFill` renkli koçan. Posterler `design/poster-<tür>-*.png` → `sips -s format jpeg -Z` ile 900/600 px olarak `TicketArt.xcassets`'e.
- Bilet etiketleri küçük widget'a sığmalı (≈18 karakter); uzun çevirilerde kısa karşılık seç. Büyük harfe çevirirken `uppercased(with: .current)` kullan (Türkçe i → İ). Arapça sağdan sola: düzen değişikliklerini Arapçada da kontrol et.
