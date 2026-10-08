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
Örnek biletlerle açmak için uygulamayı `-sampleData` argümanıyla başlat (yalnızca DEBUG, boş veritabanını doldurur).

## Kurallar
- SwiftData modelleri CloudKit uyumlu kalmalı: her alanın varsayılan değeri olmalı, `@Attribute(.unique)` yok, ilişkiler opsiyonel. Enum'lar `String` raw value olarak saklanır (`kindRaw`).
- Bilet görünümleri `TicketSnapshot` (değer tipi) alır, SwiftData nesnesi almaz.
- Her etkinlik türünün tasarımı `TicketKind.style` (`Tickets/TicketStyle.swift`) ve `TicketView` içindeki küçük boy görünümünde. Yeni tür = yeni `TicketKind` case + stil + küçük boy tasarım.
- Gün sayımı takvim günüdür (yarın her zaman 1); `DayCount` dışında gün hesabı yapma.
- Bir etkinlik kaydedildiğinde/silindiğinde `WidgetCenter.shared.reloadAllTimelines()` çağrılır.
- Kullanıcıya görünen metinler String Catalog'a gidecek (`Localizable.xcstrings`, henüz eklenmedi — bkz. TODO).
