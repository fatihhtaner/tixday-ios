# App Privacy (gizlilik etiketi)

App Store Connect → Tixday → **App Privacy** (sol menü, "Trust & Safety" altında). Bu form API ile doldurulamıyor; adımlar aşağıda.

## 1. Privacy Policy URL
`https://fatihhtaner.github.io/tixday-site/privacy.html` (fastlane metadata ile zaten girildi; dokunma)

## 2. Data Collection → "Get Started"
**Do you or your third-party partners collect data from this app?** → **Yes, we collect data from this app**

Sebep: RevenueCat satın alma geçmişini kendi sunucusunda tutuyor. Tixday'in kendisi veri toplamıyor:
- Biletler ve fotoğraflar cihazda ve kullanıcının **kendi özel iCloud'unda** (CloudKit) duruyor; biz erişemiyoruz → Apple'a göre "toplanan veri" sayılmaz.
- Hatırlatmalar cihazda planlanıyor.
- Analitik, reklam ve çökme raporu SDK'sı yok (Xcode Organizer'daki Apple çökme raporları bu forma girmez).

## 3. Data types → yalnızca bunu işaretle
**Purchases → Purchase History** ✅

Diğer her şey (Contact Info, Health, Financial Info, Location, User Content, Identifiers, Usage Data, Diagnostics…) **boş** kalacak. "User Content → Photos" işaretlenmez: fotoğraflar bize gelmiyor, kullanıcının kendi iCloud'unda kalıyor.

## 4. Purchase History soruları
| Soru | Cevap |
|---|---|
| How is this data used? | **App Functionality** (yalnızca bu) |
| Is this data linked to the user's identity? | **No** (RevenueCat anonim, rastgele bir kullanıcı kimliği kullanıyor; hesap/e-posta yok) |
| Is this data used for tracking? | **No** |

## 5. Publish
Özet ekranında şunu görmelisin:
- **Data Not Linked to You:** Purchases
- **Data Used to Track You:** yok

Sağ üstten **Publish**.

## Uygulamadaki karşılığı
- `Tixday/Resources/PrivacyInfo.xcprivacy` ve `TixdayWidget/PrivacyInfo.xcprivacy`: takip yok, toplanan veri yok, UserDefaults kullanım sebebi (CA92.1 uygulamanın kendi ayarları, 1C8F.1 App Group ile widget paylaşımı).
- RevenueCat kendi `PrivacyInfo.xcprivacy` dosyasını SDK içinde getiriyor (satın alma geçmişi).
- Sitedeki gizlilik politikası (`tools/build_site.py`) aynı şeyi söylüyor: hesap yok, takip yok, satın almalar RevenueCat üzerinden.
