# Tixday — Görsel Promptları

Promptlar İngilizce (görsel araçları İngilizcede daha iyi sonuç veriyor). Her prompt **tek başına eksiksiz**: olduğu gibi kopyala, yapıştır.
Çıkan görseli `design/` klasörüne tablodaki **dosya adıyla** kaydet, uygulamaya ben yerleştiririm.

**Kurallar**
- Görsellerde **hiç yazı, harf, rakam olmamalı.** Harfe benzeyen bir şey çıkarsa o görseli tekrar üret.
- Yazılar, kalan gün, kesik çizgi ve çentikleri kod çiziyor; görseller sadece **zemin**.
- Aynı türün geniş ve kare sürümünü **aynı sohbette** üret ki stil tutarlı olsun.

## Durum
| # | Görsel | Dosya | Durum |
|---|---|---|---|
| — | Uygulama ikonu | `app-icon-1024.png` | ✅ Bitti |
| — | 6 köşe dekoru (v1) | `art-*.png` | ✅ Bitti, uygulamada |
| 1–2 | Uçuş zemini | `plate-flight-wide.png`, `plate-flight-square.png` | ✅ Bitti, uygulamada |
| 3–4 | Konser zemini | `plate-concert-wide.png`, `plate-concert-square.png` | ⏳ Sırada |
| 5–6 | Sınav zemini | `plate-exam-wide.png`, `plate-exam-square.png` | ⏳ |
| 7–8 | Düğün zemini | `plate-wedding-wide.png`, `plate-wedding-square.png` | ⏳ |
| 9–10 | Doğum günü zemini | `plate-birthday-wide.png`, `plate-birthday-square.png` | ⏳ |
| 11–12 | Tatil zemini | `plate-holiday-wide.png`, `plate-holiday-square.png` | ⏳ |
| 13 | "Kullanıldı" damgası | `punch-stamp.png` | Sonra |

> Uçuş onaylandı. Kalanları sırayla üret; her türün geniş ve kare sürümü gelince `swift tools/import_plate.swift <tür>` ile uygulamaya alınır.
> Geniş görselde sağdaki koçan alanında hafif bir ton/panel geçişi çıkarsa sorun değil: araç onu bulup tam kesik çizgiden böler.

---

## 1. Uçuş — geniş
**Dosya:** `design/plate-flight-wide.png`
```
A premium printed airline boarding pass, photographed flat from directly above, filling the entire frame edge to edge, with no text at all. Paper: smooth light sky blue card stock #E6F1FB with a fine, realistic paper grain. Decoration: a subtle blind-embossed world map in slightly lighter blue, a thin guilloche security line pattern in #85B7EB, two faint round passport-style ink stamps made only of rings and stars, and a delicate dotted flight path arcing across. Keep the top-left quarter, the bottom 15% strip and the whole right 30% vertical strip calm and plain; put the decoration mainly in the middle and lower-middle of the left 70%. Style: high-end stationery, letterpress and embossing, soft even lighting, subtle and elegant, low contrast so text printed on top stays readable. Wide 2150x1000, fully opaque, no rounded corners, no border, no shadow, no hands, nothing outside the paper. Absolutely no text, letters, numbers, barcodes, QR codes, logos or flags.
```

## 2. Uçuş — kare
**Dosya:** `design/plate-flight-square.png`
```
A premium printed airline boarding pass, photographed flat from directly above, filling the entire square frame edge to edge, with no text at all. Same paper and style as before: smooth light sky blue card stock #E6F1FB with a fine paper grain, a subtle blind-embossed world map, a thin guilloche wave pattern in #85B7EB, one faint round stamp made only of rings and stars, a dotted flight path with a tiny airplane. Keep the top 30% and the bottom 20% of the image calm and plain, and keep the left 55% calm too; put the decoration only in the right-middle area, between 30% and 80% of the height, fading softly into the plain areas. One continuous sheet of paper: no visible panel seams, folds or tone changes. Style: high-end stationery, letterpress and embossing, soft even lighting, subtle, low contrast. Square 1024x1024, fully opaque, no rounded corners, no border, no shadow. Absolutely no text, letters, numbers, barcodes, logos or flags.
```

## 3. Konser — geniş
**Dosya:** `design/plate-concert-wide.png`
```
A premium printed concert ticket, photographed flat from directly above, filling the entire frame edge to edge, with no text at all. Paper: deep indigo card stock #26215C with a soft matte finish. Decoration: an iridescent holographic foil starburst with fine radiating lines in violet #534AB7 and soft pink #F4C0D1, stage spotlight beams rising from the bottom edge, and tiny scattered foil sparkles. Keep the top-left quarter, the bottom 15% strip and the whole right 30% vertical strip calm and plain; put the decoration mainly in the middle and lower-middle of the left 70%. Style: high-end stationery, foil printing, soft even lighting, subtle and elegant, low contrast so text printed on top stays readable. Wide 2150x1000, fully opaque, no rounded corners, no border, no shadow, no hands, nothing outside the paper. Absolutely no text, letters, numbers, barcodes, QR codes, logos or faces.
```

## 4. Konser — kare
**Dosya:** `design/plate-concert-square.png`
```
A premium printed concert ticket, photographed flat from directly above, filling the entire square frame edge to edge, with no text at all. Same paper and style as before: deep indigo card stock #26215C, an iridescent holographic foil starburst in violet #534AB7 and soft pink #F4C0D1, spotlight beams, tiny foil sparkles. Keep the top-left area (left 65%, top 55%) and the bottom 20% strip calm and plain, because large text sits there; put the decoration on the right side, between 25% and 80% of the height, fading softly into the plain areas. One continuous sheet of paper: no visible panel seams, folds or tone changes. Style: high-end stationery, foil printing, soft even lighting, subtle, low contrast. Square 1024x1024, fully opaque, no rounded corners, no border, no shadow. Absolutely no text, letters, numbers, logos or faces.
```

## 5. Sınav — geniş
**Dosya:** `design/plate-exam-wide.png`
```
A premium official exam admission card, photographed flat from directly above, filling the entire frame edge to edge, with no text at all. Paper: warm off-white security paper #F1EFE8 with visible fine fibers. Decoration: an intricate guilloche rosette like on a banknote in warm gray #B4B2A9, a faint microline pattern, a subtle watermark of concentric circles, and very light ruled lines fading out. Keep the top-left quarter, the bottom 15% strip and the whole right 30% vertical strip calm and plain; put the decoration mainly in the middle and lower-middle of the left 70%. Style: high-end security printing, soft even lighting, subtle and elegant, low contrast so text printed on top stays readable. Wide 2150x1000, fully opaque, no rounded corners, no border, no shadow, no hands, nothing outside the paper. Absolutely no text, letters, numbers, seals with writing, barcodes or logos.
```

## 6. Sınav — kare
**Dosya:** `design/plate-exam-square.png`
```
A premium official exam admission card, photographed flat from directly above, filling the entire square frame edge to edge, with no text at all. Same paper and style as before: warm off-white security paper #F1EFE8 with fine fibers, an intricate guilloche rosette in warm gray #B4B2A9, a faint microline pattern and a subtle watermark of concentric circles. Keep the top 45% and the left 55% calm and plain, because text sits there; put the decoration in the lower-right area, fading softly into the plain areas. One continuous sheet of paper: no visible panel seams, folds or tone changes. Style: high-end stationery, security printing, soft even lighting, subtle, low contrast. Square 1024x1024, fully opaque, no rounded corners, no border, no shadow. Absolutely no text, letters, numbers, seals with writing or logos.
```

## 7. Düğün — geniş
**Dosya:** `design/plate-wedding-wide.png`
```
A premium letterpress wedding invitation, photographed flat from directly above, filling the entire frame edge to edge, with no text at all. Paper: blush pink cotton paper #FBEAF0 with a soft deckled texture. Decoration: delicate blind-debossed olive branches and small five-petal flowers in dusty pink #ED93B1, touches of rose-gold foil on a few leaves, and a fine thin inset frame line. Keep the top-left quarter, the bottom 15% strip and the whole right 30% vertical strip calm and plain; put the decoration mainly in the middle and lower-middle of the left 70%. Style: high-end wedding stationery, letterpress and foil, soft even lighting, subtle and elegant, low contrast so text printed on top stays readable. Wide 2150x1000, fully opaque, no rounded corners, no border, no shadow, no hands, nothing outside the paper. Absolutely no text, letters, numbers, monograms or logos.
```

## 8. Düğün — kare
**Dosya:** `design/plate-wedding-square.png`
```
A premium letterpress wedding invitation, photographed flat from directly above, filling the entire square frame edge to edge, with no text at all. Same paper and style as before: blush pink cotton paper #FBEAF0, blind-debossed olive branches and small flowers in dusty pink #ED93B1, touches of rose-gold foil. Text is centered, so keep the whole middle of the card calm and plain; put the decoration only in the top-right and bottom-left corners as delicate corner sprays. Do not draw any frame line, the app draws its own. One continuous sheet of paper: no visible panel seams, folds or tone changes. Style: high-end stationery, wedding stationery, letterpress and foil, soft even lighting, subtle, low contrast. Square 1024x1024, fully opaque, no rounded corners, no border, no shadow. Absolutely no text, letters, numbers, monograms or logos.
```

## 9. Doğum günü — geniş
**Dosya:** `design/plate-birthday-wide.png`
```
A premium party admission ticket, photographed flat from directly above, filling the entire frame edge to edge, with no text at all. Paper: warm cream card stock #FAEEDA with a fine grain. Decoration: playful confetti, curly streamers and two small balloons printed in warm amber #EF9F27 and #FAC775, a few pieces in shiny gold foil, and a subtle pattern of tiny dots. Keep the top-left quarter, the bottom 15% strip and the whole right 30% vertical strip calm and plain; put the decoration mainly in the middle and lower-middle of the left 70%. Style: high-end stationery, letterpress and foil, soft even lighting, joyful but elegant, low contrast so text printed on top stays readable. Wide 2150x1000, fully opaque, no rounded corners, no border, no shadow, no hands, nothing outside the paper. Absolutely no text, letters, numbers, barcodes or logos.
```

## 10. Doğum günü — kare
**Dosya:** `design/plate-birthday-square.png`
```
A premium party admission ticket, photographed flat from directly above, filling the entire square frame edge to edge, with no text at all. Same paper and style as before: warm cream card stock #FAEEDA, playful confetti, curly streamers and two small balloons in warm amber #EF9F27 and #FAC775, a few pieces of gold foil, tiny dots. Keep the right 20% vertical strip plain (a tear-off stub sits there), and keep the top-left and bottom-left areas calm because text sits there; put the decoration in the center-right area, left of that strip, fading softly into the plain areas. One continuous sheet of paper: no visible panel seams, folds or tone changes. Style: high-end stationery, letterpress and foil, soft even lighting, subtle, low contrast. Square 1024x1024, fully opaque, no rounded corners, no border, no shadow. Absolutely no text, letters, numbers, logos.
```

## 11. Tatil — geniş
**Dosya:** `design/plate-holiday-wide.png`
```
A premium vintage railway ticket for a winter holiday train, photographed flat from directly above, filling the entire frame edge to edge, with no text at all. Paper: deep cranberry red card stock #791F1F with a soft matte finish. Decoration: a snowy pine forest and a small vintage steam train with a curl of smoke along the bottom, gently falling snowflakes, printed in lighter red #E24B4A and pale pink #F7C1C1, with a few snowflakes in silver foil. Keep the top-left quarter, the bottom 15% strip and the whole right 30% vertical strip calm and plain; put the decoration mainly in the middle and lower-middle of the left 70%. Style: high-end stationery, letterpress and foil, soft even lighting, cozy and elegant, low contrast so text printed on top stays readable. Wide 2150x1000, fully opaque, no rounded corners, no border, no shadow, no hands, nothing outside the paper. Absolutely no text, letters, numbers, barcodes or logos.
```

## 12. Tatil — kare
**Dosya:** `design/plate-holiday-square.png`
```
A premium vintage railway ticket for a winter holiday train, photographed flat from directly above, filling the entire square frame edge to edge, with no text at all. Same paper and style as before: deep cranberry red card stock #791F1F, a snowy pine forest and a small vintage steam train with smoke, falling snowflakes in lighter red #E24B4A and pale pink #F7C1C1, a few silver foil snowflakes. Keep the top 30% and the bottom 20% of the image calm and plain, and keep the left 55% calm too; put the decoration only in the right-middle area, between 30% and 80% of the height, fading softly into the plain areas. One continuous sheet of paper: no visible panel seams, folds or tone changes. Style: high-end stationery, letterpress and foil, soft even lighting, subtle, low contrast. Square 1024x1024, fully opaque, no rounded corners, no border, no shadow. Absolutely no text, letters, numbers, logos.
```

---

## 13. "Kullanıldı" damgası (sonra)
**Dosya:** `design/punch-stamp.png` · şeffaf arka plan. Etkinlik günü biletin üstüne basılacak; yazıyı kod ekler.
```
A worn rubber stamp impression: a circle with a double outer ring and a small star at the top and bottom, the inside left empty, with realistic uneven ink texture and slight smudges, single ink color deep red #A32D2D, flat, 1000x1000, transparent background, PNG with a real alpha channel, no checkerboard pattern. No text, no letters, no numbers.
```

---

## Arşiv (bitenler)

**Uygulama ikonu** — `app-icon-1024.png` (ilk deneme `app-icon-v1.png`). Son prompt:
```
Design an iOS app icon for "Tixday", a countdown app where every date is a ticket. Subject: a single bold ticket stub, tilted about 15 degrees counterclockwise, made of warm cream paper #F3F1EC with very subtle paper grain and crisp die-cut rounded corners. A dashed perforation line runs across the ticket about one quarter from its left end. The short left section beyond the perforation is printed in bold warm red #E24B4A. On the cream main part, a single neat horizontal row of five evenly spaced round punch positions: the first three are clean punched holes showing the dark background, the last two are solid filled circles in light warm gray #CFCBC0. Background: solid deep ink navy #16161A with a barely visible radial lift. Centered, the ticket fills about 65% of the canvas. Minimal, modern, premium, flat with a gentle soft shadow. Square 1024x1024, fully opaque, no rounded corners. No text, letters or numbers.
```

**Köşe dekorları (v1)** — `art-flight/concert/exam/wedding/birthday/holiday.png`, 1600×800 şeffaf line art. Uygulamada `Tixday/Tickets/TicketArt.xcassets` içinde. Zeminler (1–12) gelince yerlerini alacaklar.
