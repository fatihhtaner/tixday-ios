# Tixday — Görsel ve Asset Promptları

Promptlar İngilizce, çünkü görsel üretim araçları İngilizcede daha iyi sonuç veriyor.
Hazırladığın dosyaları `design/` klasörüne aşağıdaki **dosya adlarıyla** koyman yeterli, entegrasyonu ben yapacağım.
Subloom'daki gibi ChatGPT'de **gerçek şeffaf PNG** iste; damalı desen çizilmiş dosya gelirse kenarları temizlerim.

## Önemli: biletin kendisini yapay zekâ üretmiyor
Biletlerin iskeleti, yazıları (isim, tarih, kalan gün) ve çentikleri kodla çiziliyor, çünkü her kullanıcıda farklı ve her gün değişiyor.
Yapay zekâdan istediğimiz şey her bilet türünün **yazısız dekor katmanı**: biletin boş kalan köşesine, aynı renk tonunda, düşük kontrastla yerleşecek bir süsleme.
Bu yüzden promptlarda **hiç yazı, harf, rakam olmamalı.** Sonuçta yine de harf benzeri şekiller çıkarsa o görseli kullanmayalım.

## Marka rehberi
- **Tema:** "Every date is a ticket" — her tarih bir bilet. Gerçek bir bilet/biniş kartı/davetiye hissi: kâğıt, mürekkep, delik, damga.
- **Stil:** Düz vektör çizgi illüstrasyon (line art), ince ve zarif çizgiler, **tek renk ton üstüne ton**. 3D yok, gradyan yok, fotoğraf yok, karikatür maskot yok.
- **Kaçınılacaklar:** Yazı, harf, rakam, gerçek havayolu/marka logoları, bayraklar.

Her bilet promptunun sonuna eklenecek ortak stil:
```
Style: elegant flat vector line art, thin consistent strokes, single color tone-on-tone, low visual weight so it can sit behind text, generous empty space on the left half. Wide 2:1 canvas, artwork concentrated in the right half and bottom edge, fading out toward the left. Transparent background, export as PNG with a real alpha channel: no background color, no checkerboard pattern, no shadow. Absolutely no text, no letters, no numbers, no logos.
```

---

## 1. Uygulama ikonu ⭐ (en önemli)
**Dosya:** `design/app-icon-1024.png` · 1024×1024 PNG · **köşeleri yuvarlatılmamış, şeffaflık yok**

```
App icon for an iOS countdown app called "Tixday". A single bold ticket stub, tilted about 12 degrees, cream paper color #F3F1EC, with a dashed perforation line across it and two half-circle notches cut into its sides. One perfectly round hole is punched through the middle of the stub, like a ticket that has been validated. Background: deep ink navy #16161A. Minimal, modern, premium, flat with very subtle paper grain, centered, generous padding, no text, no letters, no numbers, square 1024x1024, no rounded corners on the canvas.
```

**Alternatif (renkli):**
```
Same ticket stub icon, but the stub is split into colored bands: blue #185FA5, violet #26215C, pink #FBEAF0, amber #FAC775, red #791F1F, like a stack of different tickets fanned out. Cream #F3F1EC background. Flat, minimal, no text, no numbers, square 1024x1024, no rounded corners.
```

> Birkaç varyasyon üret, en iyi 2–3 tanesini birlikte seçelim.

---

## 2. Bilet dekorları (6 adet)
**Dosyalar:** `design/art-flight.png`, `art-concert.png`, `art-exam.png`, `art-wedding.png`, `art-birthday.png`, `art-holiday.png`
**Boyut:** 1600×800 PNG · **şeffaf arka plan** · altısı aynı çizgi kalınlığında ve stilde olmalı

**Seyahat — uçuş kartı** (çizgi rengi `#85B7EB`, bilet zemini açık mavi)
```
Line art of a minimal world map made of dots, with two curved dashed flight paths and a tiny airplane silhouette, plus two round passport-style stamps made only of concentric circles, stars and wavy lines (no lettering). Line color light sky blue #85B7EB.
```

**Konser — sahne bileti** (çizgi rengi `#534AB7`, bilet zemini koyu mor)
```
Line art of stage spotlight beams fanning upward from the bottom edge, a few small stars and sparkles, and a subtle holographic starburst pattern of fine radiating lines. Line color muted violet #534AB7, with a few accent sparkles in soft pink #F4C0D1.
```

**Sınav — giriş belgesi** (çizgi rengi `#B4B2A9`, bilet zemini kırık beyaz)
```
Guilloche security pattern like on a banknote or official certificate: interlacing fine wavy lines forming a rosette, plus a light ruled-line grid fading out. Line color warm gray #B4B2A9.
```

**Düğün — davetiye** (çizgi rengi `#ED93B1`, bilet zemini açık pembe)
```
Delicate botanical line art: an olive branch and small five-petal flowers curving along the bottom-right corner, with a few tiny leaves and dots, like letterpress wedding stationery. Line color dusty pink #ED93B1.
```

**Doğum günü — parti bileti** (çizgi rengi `#EF9F27`, bilet zemini krem)
```
Playful line art of party confetti: small circles, triangles, squiggles and curly streamers, with two small balloons on strings in the corner. Line color warm amber #EF9F27, a few filled confetti pieces in #FAC775.
```

**Tatil — tren bileti** (çizgi rengi `#E24B4A`, bilet zemini koyu kırmızı)
```
Line art of a snowy winter scene along the bottom edge: a row of small pine trees, a tiny vintage steam train silhouette with a curl of smoke, and scattered snowflakes above. Line color soft red #E24B4A with snowflakes in pale pink #F7C1C1.
```

---

## 3. Kâğıt dokusu
**Dosya:** `design/paper-grain.png` · 1024×1024 PNG · **döşenebilir (seamless)**
Biletlerin üstüne çok düşük opaklıkla bindirilecek, gerçek kâğıt hissi verecek.

```
Seamless tileable texture of fine paper grain with subtle fibers, light gray on pure white, very low contrast, evenly distributed with no visible seams or focal points, no text, square 1024x1024.
```

---

## 4. Etkinlik günü — "delindi" damgası
**Dosya:** `design/punch-stamp.png` · 1000×1000 PNG · **şeffaf arka plan**
Etkinlik günü biletin üzerine basılacak damga (yazıyı kodla ekleyeceğim).

```
A worn rubber stamp impression: a circle with a double outer ring and a small star at the top and bottom, the inside left empty, with realistic uneven ink texture and slight smudges, single ink color deep red #A32D2D, flat, transparent background, PNG with real alpha, no text, no letters, no numbers.
```
