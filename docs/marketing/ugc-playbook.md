# UGC playbook: hooks, hook tests, the 2-minute "decision video"

Every claim here has to match the app. Facts to stay inside:
- Free: up to 3 tickets, Home Screen widgets, reminders, yearly birthdays, iCloud sync.
- Pro: unlimited tickets, your own photos on tickets and widgets, Lock Screen widgets.
  Yearly $9.99 / ₺299,99 with a 1-week free trial; Lifetime $24.99 / ₺799,99.
- No account and no analytics; tickets live on the phone and in the user's own iCloud.
- iPhone only, iOS 17 or later.

## Hook bank

One formula per row, two tries each. **Social proof stays out until the App Store shows real numbers.** Before that, use the honest version (a personal number from your own use).

| Formula | English | Türkçe |
|---|---|---|
| Curiosity | The countdown trick nobody tells you about | Kimsenin söylemediği geri sayım taktiği |
| | Why my Home Screen looks like a ticket wallet | Ana ekranım neden bilet cüzdanına benziyor |
| Result | I stopped forgetting birthdays, with one widget | Tek bir widget'la doğum günlerini unutmayı bıraktım |
| | 6 big days, one glance, zero calendar digging | 6 önemli gün, tek bakış, takvimde arama yok |
| Contrast | Stop counting days in your Notes app. Try this. | Notlar uygulamasında gün saymayı bırak, bunu dene |
| | Stop re-adding birthdays every year | Doğum günlerini her yıl yeniden ekleme |
| Question | Still no countdown on your Home Screen? | Ana ekranında hâlâ geri sayım yok mu? |
| | How many days until your trip? You should know at a glance | Tatiline kaç gün kaldı? Bir bakışta bilmelisin |
| Social proof (honest, for now) | I've had this widget for a month. Here's what changed | Bu widget'ı bir aydır kullanıyorum, değişen şu |
| | My friends keep asking what this widget is | Arkadaşlarım sürekli bu widget'ı soruyor |
| Challenge | Set up a birthday countdown in under 20 seconds | 20 saniyede doğum günü geri sayımı kur |
| | Bet you can't name how many days until Christmas | Yılbaşına kaç gün kaldığını bilemezsin |

## Hook test: episode 2, one variable

The body is identical in every file; only the hook card and the first voice line change. Post one per day at the same time with the same caption, wait for 1,000+ views, then compare 3-second hold and completion rate.

| File | Formula | Hook |
|---|---|---|
| `tutorial/episode-2.mp4` | Result (control) | Never forget a birthday again |
| `tutorial/hooks/episode-2-b-contrast.mp4` | Contrast | Stop re-adding birthdays every year |
| `tutorial/hooks/episode-2-c-question.mp4` | Question | Still no birthday countdown on your iPhone? |
| `tutorial/hooks/episode-2-d-challenge.mp4` | Challenge | Set this up in under 20 seconds |

Clone the winner: write 5 versions of the winning hook, same body, test again. Log everything in `content-log.csv`.

## The 2-minute decision video

For people who already saw a short video and are deciding. Shot by you: face to camera for the story, a screen recording for the demo.

The objections to answer:
1. "Another subscription?" → free plan, one-time Lifetime option, a 1-week free trial for Yearly.
2. "What happens to my data?" → no account, no analytics, your own iCloud.
3. "Is it worth setting up?" → 20 seconds per ticket, widgets update themselves.

| Time | Part | English | Türkçe | On screen |
|---|---|---|---|---|
| 0:00 | Hook | "I used a countdown app for a month. Here's my honest take." | "Bir ay boyunca bir geri sayım uygulaması kullandım, dürüst yorumum bu." | Face, then the Home Screen with widgets |
| 0:05 | Problem | "My trip, my mom's birthday, a concert: all buried in my calendar. I kept opening it just to count days, and I still almost missed a birthday." | "Tatilim, annemin doğum günü, bir konser… hepsi takvimde kaybolmuştu. Sırf gün saymak için takvimi açıyordum, yine de bir doğum gününü az kalsın kaçırıyordum." | Face; a messy calendar or a Notes list |
| 0:25 | Discovery | "I wanted something I'd see without opening anything. I found Tixday: every date becomes a vintage ticket, right on your Home Screen." | "Hiçbir şey açmadan göreceğim bir şey istedim. Tixday'i buldum: her tarih vintage bir bilete dönüşüyor, direkt ana ekranında." | App Store page, then the app's home |
| 0:45 | Demo 1 | "Add a ticket: name, date, done. It picks the poster for you." | "Bilet ekle: isim, tarih, bitti. Posteri kendisi seçiyor." | `create` clip (episode 1) |
| 1:00 | Demo 2 | "Birthdays repeat every year by themselves, and you get a reminder before the day." | "Doğum günleri her yıl kendiliğinden tekrarlıyor, günden önce hatırlatma geliyor." | `birthday` clip (episode 2) |
| 1:15 | Demo 3 | "Then the widget: long-press the Home Screen, add Tixday, pick the ticket." | "Sonra widget: ana ekrana basılı tut, Tixday'i ekle, bileti seç." | `widgets` clip |
| 1:30 | Result | "A month later: I check the days without opening a single app, and I didn't miss one birthday." | "Bir ay sonra: hiçbir uygulama açmadan günleri görüyorum ve tek bir doğum gününü kaçırmadım." | Before / after: the calendar vs. the Home Screen |
| 1:40 | Honest limits | "What's not free: more than 3 tickets, your own photos, and Lock Screen widgets. That's Pro, yearly or a one-time payment. It's iPhone only for now." | "Ücretsiz olmayanlar: 3'ten fazla bilet, kendi fotoğrafın ve kilit ekranı widget'ları. Bunlar Pro'da, yıllık ya da tek seferlik ödeme. Şimdilik sadece iPhone'da." | The paywall screen |
| 1:50 | CTA | "The free plan is enough to try it. No account needed, your data stays in your iCloud. Link in bio." | "Denemek için ücretsiz plan yeterli. Hesap gerekmiyor, verilerin kendi iCloud'unda kalıyor. Link profilde." | Closing card / app icon |

The 0:45–1:30 demo can be cut from the tutorial clips (`build/tutorial/en`); the "one month" lines are only true once you have actually used it for a month.

Re-use it: post the full video on YouTube, cut the three demos into Reels, and turn the script into a blog post on the site.

**Metrics:** average watch time 40%+, link clicks 1–2%, more questions in the comments.

## Ethics

- Paid collaborations: use the platform's paid partnership label (#reklam / #ad).
- Label AI content: the macOS voiceover is synthetic, so turn on TikTok's "AI-generated" label when you post the voiced versions.
- Music: only from the platform's own library.
- Promises: nothing the app doesn't do.
