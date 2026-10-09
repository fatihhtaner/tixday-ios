# TODO

## Bitti
- [x] Proje iskeleti: XcodeGen, uygulama + widget + test hedefleri, App Group
- [x] `TicketEvent` SwiftData modeli, `TicketKind`, `TicketSnapshot`, `DayCount`
- [x] 6 bilet türünün küçük ve orta boy tasarımı (`TicketView`)
- [x] Bilet listesi (yaklaşan / kullanılmış), boş durum, düzenleyici (canlı önizleme)
- [x] "Next ticket" widget'ı (küçük + orta), gece yarısı yenileme
- [x] `DayCount` birim testleri
- [x] Modern arayüz: kâğıt zemin, genişletilmiş başlık fontu, "Next up" + 2 sütunlu bilet duvarı, yüzen "New ticket" butonu, gerçek kesik çentikler ve gölge
- [x] Bilet detay ekranı: canlı gün/saat/dakika/saniye sayacı, düzenle, görsel olarak paylaş, sil
- [x] Düzenleyici yeniden tasarlandı: renkli tür seçici, kart alanlar, türe göre renk alan zemin
- [x] `docs/ASSET_PROMPTS.md`: ikon, 6 bilet dekoru, kâğıt dokusu, damga promptları
- [x] 6 bilet dekoru entegre edildi (`Tixday/Tickets/TicketArt.xcassets`, uygulama ve widget ortak; tür başına opaklık `artOpacity`)
- [x] Uygulama ikonu: zımbalı günler bileti (`design/app-icon-1024.png`; ilk sürüm `app-icon-v1.png`)
- [x] Widget'ta bilet seçme: `SelectTicketIntent` + `TicketEntity` (boş bırakılırsa en yakın bilet); widget kind'ı "NextTicket" korundu
- [x] Modern arayüz v2: kaydırılabilir 3D bilet destesi, odaktaki bilete göre renk alan zemin, dev sayaç başlığı, kompakt liste, Liquid Glass buton ve kutular (iOS 26, öncesinde materyal), zoom geçişi (iOS 18+)
- [x] Yerelleştirme: 12 dil (EN, TR, DE, FR, ES, IT, PT-BR, JA, KO, ZH-Hans, RU, AR), çoğul biçimleri, widget ve widget ayarları dahil; TR/AR/RU simülatörde kontrol edildi
- [x] Kilit ekranı widget'ları: yuvarlak (ilerleme halkası + gün), dikdörtgen, satır içi; aynı "Ticket" widget'ının aileleri, bilet seçimi ortak
- [x] Bildirimler: 30/7/1 gün kala ve etkinlik günü 09:00; izin ilk kayıtta; her değişiklikte en yakın 60 hatırlatma yeniden planlanır (`TicketNotifications`), birim testli
- [x] Bilet zeminleri (plate) altyapısı + uçuş zemini; `tools/import_plate.swift`; DEBUG bilet galerisi (`-ticketGallery`)
- [x] Bilet tasarımı v3: poster gövde + düz renkli koçan (`PosterTicketView`), uçuş posteri; poster olmayan türler v1/v2 tasarımına düşer
- [x] Ana ekran sadeleştirildi: deste + dev sayı + liste yerine alt alta biletler (Wallet gibi); tüm türler tek bilet düzeninde, eski v1/v2 tasarım kodu ve kâğıt zeminleri kaldırıldı
- [x] Ana ekran v3: üstte "Next up" kahraman bilet (poster + koçanda canlı saat), altında Wallet gibi üst üste dizilmiş biletler (renkli başlık şeridi görünür, son kart tam açık); sabit başlık + iOS 26 yumuşak kaydırma kenarı
- [x] Wallet destesi: kapalı kartlar başlık rengiyle dolu (köşelerden alttaki görsel sızmıyor); kapalı karta dokununca yerinde yaylanarak açılır, açık karta dokununca detay
- [x] 6 türün tamamının posteri uygulamada; tatil koçanı postere uyması için çam yeşili
- [x] Ana ekran başlığı: uygulama adı yerine tarih + "N bilet seni bekliyor" (çoğul, 12 dil)
- [x] Düzenleyici yeniden tasarlandı: seçili türün bulanık posteri arka plan (koyu tema), büyük canlı önizleme, poster küçük resimli tür seçici, cam kartlar, tarihin yanında göreli süre
- [x] Widget'lar ana ekranda yeni posterlerle kontrol edildi (orta boy, konser ve uçuş)
- [x] Ana ekran ve detay ekranı da posterin bulanık atmosferinde (koyu tema, `PosterBackdrop`); detayda cam "bekleme" kartı (tarih, % geride kalan)

## Sıradaki
- [ ] Telefonda kahraman bilete dokununca detayın açıldığını doğrula (simülatörde anlık dokunuş saniyelik saat yüzünden yutulabiliyor)
- [ ] Widget ayarında bilet seçilmemişken "Bilet" yerine "En yakın bilet" yazsın
- [ ] Açık renkli posterlerde (doğum günü gökyüzü) beyaz başlık zayıf kalıyor; gerekirse o türde karartmayı artır
- [ ] Fotoğraf seçme: kullanıcı fotoğrafı posterin yerine geçer (PhotosPicker, App Group'ta küçültülmüş JPEG, widget'ta da)
- [ ] Kilit ekranı widget'larını simülatörde/cihazda görsel kontrol et
- [ ] Ayarlar: bildirim saati ve hatırlatmaları kapatma
- [ ] Çevirileri ana dili konuşan biriyle gözden geçir (özellikle AR, JA, KO, ZH); DE/FR/ES/IT/PT/JA/KO/ZH simülatörde görsel kontrol
- [ ] App Store açıklama ve anahtar kelimelerini 12 dilde hazırla
- [ ] Widget bilet seçimini simülatörde/cihazda elle test et (widget ekle → düzenle → bilet seç)
- [ ] Kâğıt dokusu ve damga görselleri (henüz üretilmedi)
- [ ] Uçuş küçük biletinde damga "HND" yazısına biraz giriyor; gerekirse dekoru küçült
- [ ] Widget'ı ana ekranda gerçek cihazda/simülatörde kontrol et (çentik rengi, kenar boşlukları)
- [ ] Pro / paywall (RevenueCat, Subloom'daki `ProStore` yaklaşımı), ücretsiz 3 etkinlik sınırı
- [ ] Live Activity (son 24 saat)
- [ ] Etkinlik günü delme animasyonu + paylaşım kartı
- [ ] Destek sitesi + gizlilik politikası (tixday.app alınırsa)
- [ ] App Store Connect'te "Tixday – Countdown Widgets" adını rezerve et
