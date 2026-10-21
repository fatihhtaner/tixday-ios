# Static ads

Six variations per language (en, tr), each in two sizes:
`4x5` (1080×1350, Instagram / Facebook feed) and `9x16` (1080×1920, Stories, Reels, TikTok; the top 250 px and
bottom 330 px are left clear for the platform's own UI).

| # | Layout | English | Turkish |
|---|---|---|---|
| 1 | Benefit | Every big day, one glance away | Önemli günler bir bakışta |
| 2 | Benefit | Never forget a birthday again | Doğum günlerini bir daha unutma |
| 3 | Before / after | Same date. Way more fun. | Aynı tarih. Çok daha keyifli. |
| 4 | Question | Still counting days on your fingers? | Günleri hâlâ parmakla mı sayıyorsun? |
| 5 | Benefit | Your trip, right on your Home Screen | Tatilin ana ekranında geri sayıyor |
| 6 | Brand line | Every date is a ticket | Her tarih bir bilet |

No social-proof ad yet: add one (rating + review count) only once the App Store has real numbers.

Test one promise at a time against the same audience; the winning headline becomes the next TikTok hook.
Watch CTR (1%+ to start), cost per install and frequency (refresh creatives above ~3).

## Re-make

```
tools/capture_store_screens.sh /tmp/adraw en:en_US tr:tr_TR
swift tools/make_static_ads.swift /tmp/adraw docs/marketing/ads
```
Copy lives at the top of `tools/make_static_ads.swift`.
