# Uygulama içi satın alma ürünleri

| | Yıllık | Ömür boyu |
|---|---|---|
| Tür | Otomatik yenilenen abonelik | Tüketilemeyen (Non-Consumable) |
| Referans adı | `Tixday Pro Yearly` | `Tixday Pro Lifetime` |
| Ürün kimliği | `tixday_pro_yearly` | `tixday_pro_lifetime` |
| Süre | 1 yıl | — |
| Fiyat | 9,99 USD (diğer ülkeler otomatik) | 24,99 USD (diğer ülkeler otomatik) |
| Tanıtım teklifi | 1 hafta ücretsiz deneme (yeni aboneler) | — |
| Abonelik grubu | `Tixday Pro` (grup görünen adı her dilde "Tixday Pro", "Use App Name") | — |
| Aile Paylaşımı | Kapalı (açılınca geri alınamaz) | Kapalı |

## Yerelleştirmeler (görünen ad ≤ 30, açıklama ≤ 45 karakter)
| Dil | Yıllık adı | Yıllık açıklaması | Ömür boyu adı | Ömür boyu açıklaması |
|---|---|---|---|---|
| `en-US` | Tixday Pro Yearly | Unlimited tickets, photos, Lock Screen | Tixday Pro Lifetime | All Pro features forever, one payment |
| `tr` | Tixday Pro Yıllık | Sınırsız bilet, fotoğraf ve kilit ekranı | Tixday Pro Ömür Boyu | Tüm Pro özellikleri, tek ödemeyle |
| `de-DE` | Tixday Pro Jährlich | Unbegrenzte Tickets, Fotos, Sperrbildschirm | Tixday Pro Lebenslang | Alle Pro-Funktionen, einmal zahlen |
| `fr-FR` | Tixday Pro Annuel | Billets illimités, photos, écran verrouillé | Tixday Pro À vie | Tout Pro pour toujours, paiement unique |
| `es-ES` | Tixday Pro Anual | Boletos ilimitados, fotos, pantalla bloqueo | Tixday Pro De por vida | Todo Pro para siempre, un solo pago |
| `it` | Tixday Pro Annuale | Biglietti illimitati, foto, blocco schermo | Tixday Pro A vita | Tutto Pro per sempre, un solo pagamento |
| `pt-BR` | Tixday Pro Anual | Ingressos ilimitados, fotos, tela bloqueada | Tixday Pro Vitalício | Todo o Pro para sempre, pagamento único |
| `ja` | Tixday Pro 年額 | チケット無制限・写真・ロック画面 | Tixday Pro 買い切り | すべてのPro機能をずっと、1回の支払いで |
| `ko` | Tixday Pro 연간 | 무제한 티켓, 사진, 잠금 화면 | Tixday Pro 평생 | 한 번 결제로 모든 Pro 기능 평생 이용 |
| `zh-Hans` | Tixday Pro 年度 | 无限票券、照片和锁定屏幕 | Tixday Pro 终身 | 一次付费，永久使用全部 Pro 功能 |
| `ru` | Tixday Pro на год | Безлимит билетов, фото, экран блокировки | Tixday Pro навсегда | Все функции Pro навсегда, один платёж |
| `ar-SA` | Tixday Pro سنوي | تذاكر غير محدودة وصور وشاشة القفل | Tixday Pro مدى الحياة | كل ميزات Pro للأبد بدفعة واحدة |

## İnceleme bilgileri (her iki ürün)
- **Ekran görüntüsü:** paywall ekranı (`docs/app-store/review-paywall.png`)
- **İnceleme notu:** "Tixday Pro unlocks unlimited tickets (free plan: 3), your own photos on tickets and widgets, and Lock Screen widgets. Tap Pro at the top of the home screen, or try to add a fourth ticket."

## RevenueCat (Subloom ile aynı adımlar)
1. Yeni proje **Tixday** → App Store uygulaması ekle (`com.ibrahimfatihtaner.tixday`), Subloom'daki In-App Purchase anahtarıyla.
2. Products → App Store ürünlerini içe aktar.
3. Entitlements → `tixday_pro` → iki ürünü bağla.
4. Offerings → `default` → **Annual** paketine `tixday_pro_yearly`, **Lifetime** paketine `tixday_pro_lifetime`.
5. API Keys → Test Store (`test_…`, yalnızca DEBUG) ve App Store (`appl_…`, Release) anahtarları → `Tixday/Support/AppConfig.swift`.
