# Tixday – Countdown Widgets · Ürün tanımı

## Fikir
Kullanıcı beklediği bir günü ekler (seyahat, konser, sınav, düğün, doğum günü, tatil). Her etkinlik **kendi türüne özel bir bilet** olarak görünür ve ana ekran / kilit ekranı widget'ında geri sayar. Etkinlik günü bilet "delinir".

## Neden bu ürün (pazar araştırması, Ekim 2026)
- Genel geri sayım uygulamalarının talebi çok yüksek (Countdown Star 216K, Countdown 177K değerlendirme) ama ABD'de araç, üretkenlik, yaşam tarzı, iş ve sağlık kategorilerinde en çok kazanan ilk 200 uygulamada hiç geri sayım uygulaması yok. Fiyatlar 1–2$ civarında. Bu yüzden büyük gelir değil; **az bakım isteyen, mütevazı pasif gelir** hedefleniyor.
- Fark yaratacak şeyler tasarım (bilet teması) ve Apple'ın yeni özellikleri.
- **Doğrudan rakip:** *Daystub: Countdown Widget* (1 Ekim 2026'da çıktı, aynı "her tarih bir bilet" fikri). Bizim farkımız her etkinlik türünün ayrı bir bilet tasarımına sahip olması. Bu fark korunmalı ve pazarlamada öne çıkarılmalı.

## Bilet türleri (v1)
| Tür | Bilet | Yazı | Ayırt edici detay |
|---|---|---|---|
| Seyahat | Uçuş kartı | Monospace | Rota (IST → HND), kapı, koltuk |
| Konser | Sahne bileti | Sıkıştırılmış kalın | Sanatçı adı, bölüm/sıra |
| Sınav | Giriş belgesi | Monospace | Fotoğraf kutusu, "APPROVED" damgası |
| Düğün | Davetiye | Serif italik | Çift adı, iç çerçeve |
| Doğum günü | Parti bileti | Rounded | Dikey koçan numarası |
| Tatil | Tren bileti | Monospace | → hedef, vagon |

Ortak kimlik: yan çentikler, kesik çizgili koçan, büyük gün sayısı.

## Özellikler
**v1 (MVP)**
- Etkinlik oluştur/düzenle/sil, canlı bilet önizlemesi
- Küçük ve orta boy ana ekran widget'ı (en yakın etkinlik)
- Widget'ta hangi etkinliğin gösterileceğini seçme (AppIntent)
- Kilit ekranı widget'ları
- Bildirimler: 30 / 7 / 1 gün kala ve etkinlik günü
- Ücretsiz: 3 etkinlik

**Sonra**
- Live Activity / Dynamic Island (son 24 saat canlı sayaç), StandBy
- Etkinlik günü "bilet delme" animasyonu + paylaşılabilir kart
- Paylaşılan geri sayım (iCloud paylaşımı)
- Yeni bilet türleri (sinema, maç, festival, mezuniyet…) — ücretli paketler
- iCloud senkronu, özel yazı tipleri (OFL lisanslı)

## Gelir modeli
- Pro: sınırsız etkinlik, tüm bilet türleri, Live Activity, paylaşılan geri sayım.
- Yaklaşık 9,99$/yıl veya 14,99$ tek seferlik (bu kategoride kullanıcılar aboneliğe sıcak bakmıyor).

## Pazar
Global, İngilizce kaynak dil. Yerelleştirme sonra (Subloom'daki 12 dil yaklaşımı).
