#!/usr/bin/env python3
"""Generates the localized Tixday website into ../site.

English lives at the site root; every other language gets its own folder
(e.g. site/tr/privacy.html). Edit the texts below, then run:

    python3 tools/build_site.py

Publish by copying site/ into the fatihhtaner/tixday-site repository (GitHub Pages).
"""
import html
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent / "site"
BASE_URL = "https://fatihhtaner.github.io/tixday-site/"
EMAIL = "ibrahimfatihtanerbsns@gmail.com"
RC_URL = "https://www.revenuecat.com/privacy"

# (folder, html lang, native name)
LANGUAGES = [
    ("", "en", "English"),
    ("tr", "tr", "Türkçe"),
    ("de", "de", "Deutsch"),
    ("fr", "fr", "Français"),
    ("es", "es", "Español"),
    ("it", "it", "Italiano"),
    ("pt-br", "pt-BR", "Português (Brasil)"),
    ("ja", "ja", "日本語"),
    ("ko", "ko", "한국어"),
    ("zh-hans", "zh-Hans", "简体中文"),
    ("ru", "ru", "Русский"),
    ("ar", "ar", "العربية"),
]
RTL = {"ar"}

TEXT = {
"en": dict(
    home_title="Tixday — Countdown Widgets",
    meta="Every date you're waiting for, as a beautiful ticket that counts down on your Home Screen.",
    hero_h1="Every date is a ticket.",
    hero_p="Tixday turns the days you're waiting for into tickets with vintage poster art — a boarding pass for your trip, a concert ticket, a wedding invitation — and counts them down on your Home Screen and Lock Screen.",
    private_strong="Private by design.",
    private_p="No account, no ads, no tracking. Your tickets stay on your iPhone.",
    support="Support", privacy="Privacy Policy",
    support_intro="Questions, bugs or ideas? We'd love to hear from you.",
    email_label="Email", reply_time="We usually reply within 2 business days.",
    faq_title="Frequently asked questions",
    notif_path="Settings → Notifications → Tixday",
    cancel_path="Settings → [your name] → Subscriptions",
    faq=[
        ("How do I add a widget?", "Touch and hold your Home Screen, tap Edit → Add Widget, search for Tixday and pick a size. To show a specific ticket, touch and hold the widget and tap Edit Widget."),
        ("I'm not getting reminders.", "Open {notif_path} on your iPhone and make sure notifications are allowed. Tixday reminds you a month, a week and a day before each date, and on the day itself at 9:00."),
        ("How do I restore my Pro purchase?", "Open Tixday, tap Pro at the top of the home screen and choose Restore while signed in with the same Apple ID you used to buy Pro."),
        ("How do I cancel Tixday Pro?", "Subscriptions are managed by Apple: {cancel_path} → Tixday."),
        ("What happens to my tickets if Pro ends?", "Nothing is deleted. Your three soonest upcoming tickets keep working; the rest stay saved and unlock again with Pro."),
    ],
    effective="Effective date: October 9, 2026",
    intro='Tixday ("the app") is built to keep your information on your own device. This policy explains what data the app handles and why.',
    sections=[
        ("Data you enter", "Your tickets (titles, dates, details and settings) are stored only on your device. We, the developer, cannot access them."),
        ("Photos", "If you add a photo to a ticket, you choose it with Apple's photo picker, so Tixday receives only that photo and never your photo library. A smaller copy is stored with the ticket on your device."),
        ("No accounts, ads or tracking", "Tixday does not require an account, does not show ads, does not use analytics and does not track you across apps or websites."),
        ("Reminders and widgets", "Reminders are local notifications scheduled on your device, and widgets read your tickets from your device. Neither goes through any server."),
        ("Purchases", "Tixday Pro is purchased through Apple's App Store; we never receive your payment details. We use {rc_link} to verify purchases and unlock Pro. RevenueCat receives an anonymous app user identifier, your purchase history for Tixday, and basic device and app information. It does not receive your name, email address or your tickets."),
        ("Children", "Tixday is not directed to children under 13 and does not knowingly collect information from them."),
        ("Deleting your data", "Deleting a ticket in the app removes it, including its photo. Deleting the app removes all data stored on your device."),
        ("Changes", "If this policy changes, we will update this page and the effective date above."),
        ("Contact", "{email}"),
    ],
),
"tr": dict(
    home_title="Tixday — Geri Sayım Widget'ı",
    meta="Beklediğin her gün, ana ekranında geri sayan güzel bir bilet.",
    hero_h1="Her tarih bir bilet.",
    hero_p="Tixday beklediğin günleri vintage posterli biletlere dönüştürür — seyahatin için biniş kartı, konser bileti, düğün davetiyesi — ve ana ekranında, kilit ekranında geri sayar.",
    private_strong="Gizlilik öncelikli.",
    private_p="Hesap yok, reklam yok, takip yok. Biletlerin iPhone'unda kalır.",
    support="Destek", privacy="Gizlilik Politikası",
    support_intro="Soruların, hata bildirimlerin ya da fikirlerin mi var? Senden haber almayı çok isteriz.",
    email_label="E-posta", reply_time="Genellikle 2 iş günü içinde yanıt veriyoruz.",
    faq_title="Sık sorulan sorular",
    notif_path="Ayarlar → Bildirimler → Tixday",
    cancel_path="Ayarlar → [adın] → Abonelikler",
    faq=[
        ("Widget nasıl eklerim?", "Ana ekranına basılı tut, Düzenle → Araç Takımı Ekle'ye dokun, Tixday'i ara ve bir boyut seç. Belirli bir bileti göstermek için widget'a basılı tutup Araç Takımını Düzenle'ye dokun."),
        ("Hatırlatma almıyorum.", "iPhone'unda {notif_path} bölümünü açıp bildirimlere izin verildiğinden emin ol. Tixday her tarihten bir ay, bir hafta ve bir gün önce, bir de o gün saat 09:00'da hatırlatır."),
        ("Pro satın alımımı nasıl geri yüklerim?", "Pro'yu satın aldığın Apple Kimliği ile oturum açıkken Tixday'i aç, ana ekranın üstündeki Pro'ya dokun ve Geri yükle'yi seç."),
        ("Tixday Pro'yu nasıl iptal ederim?", "Abonelikler Apple tarafından yönetilir: {cancel_path} → Tixday."),
        ("Pro biterse biletlerime ne olur?", "Hiçbir şey silinmez. En yakın üç biletin çalışmaya devam eder; diğerleri saklı kalır ve Pro ile yeniden açılır."),
    ],
    effective="Yürürlük tarihi: 9 Ekim 2026",
    intro='Tixday ("uygulama"), bilgilerini kendi cihazında tutmak için tasarlandı. Bu politika, uygulamanın hangi verileri neden işlediğini açıklar.',
    sections=[
        ("Girdiğin veriler", "Biletlerin (başlıklar, tarihler, ayrıntılar ve ayarlar) yalnızca cihazında saklanır. Geliştirici olarak biz bu verilere erişemeyiz."),
        ("Fotoğraflar", "Bir bilete fotoğraf eklersen onu Apple'ın fotoğraf seçicisiyle seçersin; Tixday yalnızca o fotoğrafı alır, fotoğraf arşivine hiçbir zaman erişmez. Fotoğrafın küçültülmüş bir kopyası biletle birlikte cihazında saklanır."),
        ("Hesap, reklam ve takip yok", "Tixday hesap gerektirmez, reklam göstermez, analiz aracı kullanmaz ve seni uygulamalar ya da web siteleri arasında takip etmez."),
        ("Hatırlatmalar ve widget'lar", "Hatırlatmalar cihazında planlanan yerel bildirimlerdir; widget'lar biletlerini cihazından okur. İkisi de herhangi bir sunucudan geçmez."),
        ("Satın alımlar", "Tixday Pro, Apple'ın App Store'u üzerinden satın alınır; ödeme bilgilerin hiçbir zaman bize ulaşmaz. Satın alımları doğrulamak ve Pro'yu açmak için {rc_link} kullanırız. RevenueCat'e anonim bir uygulama kullanıcı kimliği, Tixday satın alma geçmişin ve temel cihaz ile uygulama bilgileri iletilir. Adın, e-posta adresin veya biletlerin iletilmez."),
        ("Çocuklar", "Tixday 13 yaşın altındaki çocuklara yönelik değildir ve bilerek onlardan bilgi toplamaz."),
        ("Verilerini silme", "Uygulamada bir bileti silmek onu fotoğrafıyla birlikte kaldırır. Uygulamayı silmek, cihazında saklanan tüm verileri kaldırır."),
        ("Değişiklikler", "Bu politika değişirse bu sayfayı ve yukarıdaki yürürlük tarihini güncelleriz."),
        ("İletişim", "{email}"),
    ],
),
"de": dict(
    home_title="Tixday — Countdown-Widgets",
    meta="Jeder Tag, auf den du wartest, als schönes Ticket, das auf deinem Home-Bildschirm herunterzählt.",
    hero_h1="Jedes Datum ist ein Ticket.",
    hero_p="Tixday macht aus den Tagen, auf die du wartest, Tickets mit Vintage-Postern – eine Bordkarte für die Reise, ein Konzertticket, eine Hochzeitseinladung – und zählt sie auf deinem Home- und Sperrbildschirm herunter.",
    private_strong="Privat von Grund auf.",
    private_p="Kein Konto, keine Werbung, kein Tracking. Deine Tickets bleiben auf deinem iPhone.",
    support="Support", privacy="Datenschutzerklärung",
    support_intro="Fragen, Fehler oder Ideen? Wir freuen uns, von dir zu hören.",
    email_label="E-Mail", reply_time="Wir antworten in der Regel innerhalb von 2 Werktagen.",
    faq_title="Häufige Fragen",
    notif_path="Einstellungen → Mitteilungen → Tixday",
    cancel_path="Einstellungen → [dein Name] → Abonnements",
    faq=[
        ("Wie füge ich ein Widget hinzu?", "Halte den Home-Bildschirm gedrückt, tippe auf Bearbeiten → Widget hinzufügen, suche nach Tixday und wähle eine Größe. Um ein bestimmtes Ticket zu zeigen, halte das Widget gedrückt und tippe auf Widget bearbeiten."),
        ("Ich erhalte keine Erinnerungen.", "Öffne auf deinem iPhone {notif_path} und stelle sicher, dass Mitteilungen erlaubt sind. Tixday erinnert dich einen Monat, eine Woche und einen Tag vorher sowie am Tag selbst um 9:00 Uhr."),
        ("Wie stelle ich meinen Pro-Kauf wieder her?", "Öffne Tixday, tippe oben auf dem Startbildschirm auf Pro und wähle Wiederherstellen – angemeldet mit der Apple-ID, mit der du Pro gekauft hast."),
        ("Wie kündige ich Tixday Pro?", "Abos werden von Apple verwaltet: {cancel_path} → Tixday."),
        ("Was passiert mit meinen Tickets, wenn Pro endet?", "Nichts wird gelöscht. Deine drei nächsten Tickets funktionieren weiter; die übrigen bleiben gespeichert und werden mit Pro wieder freigeschaltet."),
    ],
    effective="Gültig ab: 9. Oktober 2026",
    intro="Tixday („die App“) ist so gebaut, dass deine Informationen auf deinem eigenen Gerät bleiben. Diese Erklärung beschreibt, welche Daten die App verarbeitet und warum.",
    sections=[
        ("Von dir eingegebene Daten", "Deine Tickets (Titel, Daten, Details und Einstellungen) werden nur auf deinem Gerät gespeichert. Wir als Entwickler haben keinen Zugriff darauf."),
        ("Fotos", "Wenn du einem Ticket ein Foto hinzufügst, wählst du es über Apples Fotoauswahl aus. Tixday erhält nur dieses Foto, nie deine Mediathek. Eine verkleinerte Kopie wird mit dem Ticket auf deinem Gerät gespeichert."),
        ("Kein Konto, keine Werbung, kein Tracking", "Tixday benötigt kein Konto, zeigt keine Werbung, nutzt keine Analysetools und verfolgt dich nicht über Apps oder Websites hinweg."),
        ("Erinnerungen und Widgets", "Erinnerungen sind lokale Mitteilungen, die auf deinem Gerät geplant werden, und Widgets lesen deine Tickets von deinem Gerät. Beides läuft über keinen Server."),
        ("Käufe", "Tixday Pro wird über Apples App Store gekauft; deine Zahlungsdaten erhalten wir nie. Wir nutzen {rc_link}, um Käufe zu prüfen und Pro freizuschalten. RevenueCat erhält eine anonyme App-Nutzer-ID, deinen Kaufverlauf für Tixday sowie grundlegende Geräte- und App-Informationen. Deinen Namen, deine E-Mail-Adresse oder deine Tickets erhält RevenueCat nicht."),
        ("Kinder", "Tixday richtet sich nicht an Kinder unter 13 Jahren und erhebt wissentlich keine Daten von ihnen."),
        ("Daten löschen", "Wenn du ein Ticket in der App löschst, wird es samt Foto entfernt. Wenn du die App löschst, werden alle auf deinem Gerät gespeicherten Daten entfernt."),
        ("Änderungen", "Wenn sich diese Erklärung ändert, aktualisieren wir diese Seite und das oben genannte Datum."),
        ("Kontakt", "{email}"),
    ],
),
"fr": dict(
    home_title="Tixday — Widgets compte à rebours",
    meta="Chaque date que vous attendez, sous forme d'un beau billet qui fait le compte à rebours sur votre écran d'accueil.",
    hero_h1="Chaque date est un billet.",
    hero_p="Tixday transforme les jours que vous attendez en billets illustrés d'affiches vintage — une carte d'embarquement pour votre voyage, un billet de concert, une invitation de mariage — et fait le compte à rebours sur votre écran d'accueil et votre écran verrouillé.",
    private_strong="Confidentiel par nature.",
    private_p="Pas de compte, pas de publicité, pas de pistage. Vos billets restent sur votre iPhone.",
    support="Assistance", privacy="Politique de confidentialité",
    support_intro="Une question, un bug ou une idée ? Écrivez-nous.",
    email_label="E-mail", reply_time="Nous répondons généralement sous 2 jours ouvrés.",
    faq_title="Questions fréquentes",
    notif_path="Réglages → Notifications → Tixday",
    cancel_path="Réglages → [votre nom] → Abonnements",
    faq=[
        ("Comment ajouter un widget ?", "Maintenez le doigt sur l'écran d'accueil, touchez Modifier → Ajouter un widget, recherchez Tixday et choisissez une taille. Pour afficher un billet précis, maintenez le widget et touchez Modifier le widget."),
        ("Je ne reçois pas de rappels.", "Ouvrez {notif_path} sur votre iPhone et vérifiez que les notifications sont autorisées. Tixday vous prévient un mois, une semaine et un jour avant chaque date, puis le jour même à 9 h."),
        ("Comment restaurer mon achat Pro ?", "Ouvrez Tixday, touchez Pro en haut de l'écran d'accueil et choisissez Restaurer, en étant connecté avec l'identifiant Apple utilisé pour acheter Pro."),
        ("Comment résilier Tixday Pro ?", "Les abonnements sont gérés par Apple : {cancel_path} → Tixday."),
        ("Que deviennent mes billets si Pro prend fin ?", "Rien n'est supprimé. Vos trois prochains billets continuent de fonctionner ; les autres restent enregistrés et se débloquent à nouveau avec Pro."),
    ],
    effective="Date d'entrée en vigueur : 9 octobre 2026",
    intro="Tixday (« l'app ») est conçue pour que vos informations restent sur votre propre appareil. Cette politique explique quelles données l'app traite et pourquoi.",
    sections=[
        ("Données que vous saisissez", "Vos billets (titres, dates, détails et réglages) sont stockés uniquement sur votre appareil. Nous, le développeur, n'y avons pas accès."),
        ("Photos", "Si vous ajoutez une photo à un billet, vous la choisissez avec le sélecteur de photos d'Apple : Tixday ne reçoit que cette photo, jamais votre photothèque. Une copie réduite est stockée avec le billet sur votre appareil."),
        ("Ni compte, ni publicité, ni pistage", "Tixday ne nécessite aucun compte, n'affiche pas de publicité, n'utilise aucun outil d'analyse et ne vous suit pas à travers les apps ou les sites web."),
        ("Rappels et widgets", "Les rappels sont des notifications locales planifiées sur votre appareil, et les widgets lisent vos billets sur votre appareil. Rien ne transite par un serveur."),
        ("Achats", "Tixday Pro s'achète via l'App Store d'Apple ; nous ne recevons jamais vos informations de paiement. Nous utilisons {rc_link} pour vérifier les achats et débloquer Pro. RevenueCat reçoit un identifiant utilisateur anonyme, votre historique d'achats Tixday ainsi que des informations de base sur l'appareil et l'app. RevenueCat ne reçoit ni votre nom, ni votre adresse e-mail, ni vos billets."),
        ("Enfants", "Tixday ne s'adresse pas aux enfants de moins de 13 ans et ne collecte pas sciemment d'informations les concernant."),
        ("Suppression de vos données", "Supprimer un billet dans l'app le retire, photo comprise. Supprimer l'app efface toutes les données stockées sur votre appareil."),
        ("Modifications", "Si cette politique change, nous mettrons à jour cette page et la date ci-dessus."),
        ("Contact", "{email}"),
    ],
),
"es": dict(
    home_title="Tixday — Widgets de cuenta atrás",
    meta="Cada fecha que esperas, como un boleto precioso que hace la cuenta atrás en tu pantalla de inicio.",
    hero_h1="Cada fecha es un boleto.",
    hero_p="Tixday convierte los días que esperas en boletos con pósters vintage —una tarjeta de embarque para tu viaje, una entrada de concierto, una invitación de boda— y hace la cuenta atrás en tu pantalla de inicio y de bloqueo.",
    private_strong="Privado por diseño.",
    private_p="Sin cuenta, sin anuncios y sin rastreo. Tus boletos se quedan en tu iPhone.",
    support="Soporte", privacy="Política de privacidad",
    support_intro="¿Preguntas, errores o ideas? Nos encantará saber de ti.",
    email_label="Correo electrónico", reply_time="Normalmente respondemos en 2 días laborables.",
    faq_title="Preguntas frecuentes",
    notif_path="Ajustes → Notificaciones → Tixday",
    cancel_path="Ajustes → [tu nombre] → Suscripciones",
    faq=[
        ("¿Cómo añado un widget?", "Mantén pulsada la pantalla de inicio, toca Editar → Añadir widget, busca Tixday y elige un tamaño. Para mostrar un boleto concreto, mantén pulsado el widget y toca Editar widget."),
        ("No recibo recordatorios.", "Abre {notif_path} en tu iPhone y asegúrate de que las notificaciones estén permitidas. Tixday te avisa un mes, una semana y un día antes de cada fecha, y el mismo día a las 9:00."),
        ("¿Cómo restauro mi compra de Pro?", "Abre Tixday, toca Pro en la parte superior de la pantalla principal y elige Restaurar, con la sesión iniciada en el mismo Apple ID con el que compraste Pro."),
        ("¿Cómo cancelo Tixday Pro?", "Las suscripciones las gestiona Apple: {cancel_path} → Tixday."),
        ("¿Qué pasa con mis boletos si termina Pro?", "No se borra nada. Tus tres próximos boletos siguen funcionando; el resto se queda guardado y se desbloquea de nuevo con Pro."),
    ],
    effective="Fecha de entrada en vigor: 9 de octubre de 2026",
    intro='Tixday ("la app") está diseñada para que tu información se quede en tu propio dispositivo. Esta política explica qué datos maneja la app y por qué.',
    sections=[
        ("Datos que introduces", "Tus boletos (títulos, fechas, detalles y ajustes) se guardan solo en tu dispositivo. Nosotros, como desarrolladores, no podemos acceder a ellos."),
        ("Fotos", "Si añades una foto a un boleto, la eliges con el selector de fotos de Apple: Tixday solo recibe esa foto, nunca tu fototeca. Una copia reducida se guarda con el boleto en tu dispositivo."),
        ("Sin cuentas, anuncios ni rastreo", "Tixday no requiere una cuenta, no muestra anuncios, no usa herramientas de análisis y no te rastrea entre apps ni sitios web."),
        ("Recordatorios y widgets", "Los recordatorios son notificaciones locales programadas en tu dispositivo, y los widgets leen tus boletos desde tu dispositivo. Nada pasa por ningún servidor."),
        ("Compras", "Tixday Pro se compra a través del App Store de Apple; nunca recibimos tus datos de pago. Usamos {rc_link} para verificar las compras y desbloquear Pro. RevenueCat recibe un identificador de usuario anónimo, tu historial de compras de Tixday e información básica del dispositivo y de la app. No recibe tu nombre, tu correo electrónico ni tus boletos."),
        ("Menores", "Tixday no está dirigida a menores de 13 años y no recopila conscientemente información de ellos."),
        ("Eliminar tus datos", "Al eliminar un boleto en la app, se borra junto con su foto. Al eliminar la app, se borran todos los datos guardados en tu dispositivo."),
        ("Cambios", "Si esta política cambia, actualizaremos esta página y la fecha indicada arriba."),
        ("Contacto", "{email}"),
    ],
),
"it": dict(
    home_title="Tixday — Widget conto alla rovescia",
    meta="Ogni data che aspetti, come un bel biglietto che fa il conto alla rovescia nella schermata Home.",
    hero_h1="Ogni data è un biglietto.",
    hero_p="Tixday trasforma i giorni che aspetti in biglietti con poster vintage — una carta d'imbarco per il viaggio, un biglietto per il concerto, un invito di nozze — e fa il conto alla rovescia nella schermata Home e di blocco.",
    private_strong="Privacy by design.",
    private_p="Nessun account, niente pubblicità, nessun tracciamento. I tuoi biglietti restano sul tuo iPhone.",
    support="Assistenza", privacy="Informativa sulla privacy",
    support_intro="Domande, bug o idee? Saremo felici di sentirti.",
    email_label="Email", reply_time="Di solito rispondiamo entro 2 giorni lavorativi.",
    faq_title="Domande frequenti",
    notif_path="Impostazioni → Notifiche → Tixday",
    cancel_path="Impostazioni → [il tuo nome] → Abbonamenti",
    faq=[
        ("Come aggiungo un widget?", "Tieni premuto sulla schermata Home, tocca Modifica → Aggiungi widget, cerca Tixday e scegli una dimensione. Per mostrare un biglietto specifico, tieni premuto il widget e tocca Modifica widget."),
        ("Non ricevo i promemoria.", "Apri {notif_path} sul tuo iPhone e assicurati che le notifiche siano consentite. Tixday ti avvisa un mese, una settimana e un giorno prima di ogni data, e il giorno stesso alle 9:00."),
        ("Come ripristino il mio acquisto Pro?", "Apri Tixday, tocca Pro in alto nella schermata principale e scegli Ripristina, con l'accesso effettuato con lo stesso ID Apple usato per acquistare Pro."),
        ("Come annullo Tixday Pro?", "Gli abbonamenti sono gestiti da Apple: {cancel_path} → Tixday."),
        ("Cosa succede ai miei biglietti se Pro termina?", "Non viene eliminato nulla. I tuoi tre biglietti più vicini continuano a funzionare; gli altri restano salvati e si sbloccano di nuovo con Pro."),
    ],
    effective="Data di entrata in vigore: 9 ottobre 2026",
    intro="Tixday (\"l'app\") è progettata per mantenere le tue informazioni sul tuo dispositivo. Questa informativa spiega quali dati gestisce l'app e perché.",
    sections=[
        ("Dati che inserisci", "I tuoi biglietti (titoli, date, dettagli e impostazioni) sono salvati solo sul tuo dispositivo. Noi, in quanto sviluppatori, non possiamo accedervi."),
        ("Foto", "Se aggiungi una foto a un biglietto, la scegli con il selettore di foto di Apple: Tixday riceve solo quella foto, mai la tua libreria. Una copia ridotta viene salvata con il biglietto sul tuo dispositivo."),
        ("Nessun account, pubblicità o tracciamento", "Tixday non richiede un account, non mostra pubblicità, non usa strumenti di analisi e non ti traccia tra app o siti web."),
        ("Promemoria e widget", "I promemoria sono notifiche locali programmate sul tuo dispositivo e i widget leggono i tuoi biglietti dal tuo dispositivo. Nulla passa attraverso un server."),
        ("Acquisti", "Tixday Pro si acquista tramite l'App Store di Apple; non riceviamo mai i tuoi dati di pagamento. Usiamo {rc_link} per verificare gli acquisti e sbloccare Pro. RevenueCat riceve un identificativo utente anonimo, la cronologia dei tuoi acquisti di Tixday e informazioni di base sul dispositivo e sull'app. Non riceve il tuo nome, il tuo indirizzo email né i tuoi biglietti."),
        ("Minori", "Tixday non è rivolta a minori di 13 anni e non raccoglie consapevolmente informazioni su di loro."),
        ("Eliminazione dei dati", "Eliminando un biglietto nell'app, viene rimosso insieme alla sua foto. Eliminando l'app, vengono rimossi tutti i dati salvati sul tuo dispositivo."),
        ("Modifiche", "Se questa informativa cambia, aggiorneremo questa pagina e la data indicata sopra."),
        ("Contatti", "{email}"),
    ],
),
"pt-BR": dict(
    home_title="Tixday — Widgets de contagem regressiva",
    meta="Cada data que você espera, como um ingresso bonito que faz a contagem regressiva na sua Tela de Início.",
    hero_h1="Cada data é um ingresso.",
    hero_p="O Tixday transforma os dias que você espera em ingressos com pôsteres vintage — um cartão de embarque para a viagem, um ingresso de show, um convite de casamento — e faz a contagem regressiva na Tela de Início e na Tela Bloqueada.",
    private_strong="Privado por natureza.",
    private_p="Sem conta, sem anúncios e sem rastreamento. Seus ingressos ficam no seu iPhone.",
    support="Suporte", privacy="Política de Privacidade",
    support_intro="Dúvidas, bugs ou ideias? Vamos adorar ouvir você.",
    email_label="E-mail", reply_time="Normalmente respondemos em até 2 dias úteis.",
    faq_title="Perguntas frequentes",
    notif_path="Ajustes → Notificações → Tixday",
    cancel_path="Ajustes → [seu nome] → Assinaturas",
    faq=[
        ("Como adiciono um widget?", "Toque e segure na Tela de Início, toque em Editar → Adicionar Widget, procure Tixday e escolha um tamanho. Para mostrar um ingresso específico, toque e segure o widget e toque em Editar Widget."),
        ("Não estou recebendo lembretes.", "Abra {notif_path} no seu iPhone e verifique se as notificações estão permitidas. O Tixday avisa um mês, uma semana e um dia antes de cada data, e no próprio dia às 9h."),
        ("Como restauro minha compra do Pro?", "Abra o Tixday, toque em Pro no topo da tela inicial e escolha Restaurar, com a sessão iniciada no mesmo Apple ID usado para comprar o Pro."),
        ("Como cancelo o Tixday Pro?", "As assinaturas são gerenciadas pela Apple: {cancel_path} → Tixday."),
        ("O que acontece com meus ingressos se o Pro acabar?", "Nada é apagado. Seus três próximos ingressos continuam funcionando; os demais ficam salvos e voltam a ser liberados com o Pro."),
    ],
    effective="Data de vigência: 9 de outubro de 2026",
    intro='O Tixday ("o app") foi criado para manter suas informações no seu próprio aparelho. Esta política explica quais dados o app utiliza e por quê.',
    sections=[
        ("Dados que você insere", "Seus ingressos (títulos, datas, detalhes e ajustes) ficam armazenados apenas no seu aparelho. Nós, como desenvolvedores, não temos acesso a eles."),
        ("Fotos", "Se você adicionar uma foto a um ingresso, você a escolhe com o seletor de fotos da Apple: o Tixday recebe só essa foto, nunca a sua fototeca. Uma cópia reduzida fica armazenada com o ingresso no seu aparelho."),
        ("Sem contas, anúncios ou rastreamento", "O Tixday não exige conta, não exibe anúncios, não usa ferramentas de análise e não rastreia você entre apps ou sites."),
        ("Lembretes e widgets", "Os lembretes são notificações locais agendadas no seu aparelho, e os widgets leem seus ingressos no seu aparelho. Nada passa por servidores."),
        ("Compras", "O Tixday Pro é comprado pela App Store da Apple; nunca recebemos seus dados de pagamento. Usamos o {rc_link} para verificar compras e liberar o Pro. O RevenueCat recebe um identificador de usuário anônimo, seu histórico de compras do Tixday e informações básicas do aparelho e do app. Ele não recebe seu nome, seu e-mail nem seus ingressos."),
        ("Crianças", "O Tixday não é direcionado a menores de 13 anos e não coleta intencionalmente informações deles."),
        ("Como apagar seus dados", "Apagar um ingresso no app o remove, junto com a foto. Apagar o app remove todos os dados armazenados no seu aparelho."),
        ("Alterações", "Se esta política mudar, atualizaremos esta página e a data de vigência acima."),
        ("Contato", "{email}"),
    ],
),
"ja": dict(
    home_title="Tixday — カウントダウンウィジェット",
    meta="待ち遠しい日を、ホーム画面でカウントダウンする美しいチケットに。",
    hero_h1="すべての日付は、一枚のチケット。",
    hero_p="Tixdayは待ち遠しい日を、ヴィンテージポスター風のチケットに変えます。旅行には搭乗券、ライブにはチケット、結婚式には招待状。ホーム画面とロック画面でカウントダウンします。",
    private_strong="プライバシー重視。",
    private_p="アカウント不要、広告なし、トラッキングなし。チケットはiPhoneの中だけに保存されます。",
    support="サポート", privacy="プライバシーポリシー",
    support_intro="ご質問、不具合のご報告、アイデアなど、お気軽にお寄せください。",
    email_label="メール", reply_time="通常、2営業日以内にご返信します。",
    faq_title="よくある質問",
    notif_path="設定 → 通知 → Tixday",
    cancel_path="設定 → [ユーザ名] → サブスクリプション",
    faq=[
        ("ウィジェットを追加するには？", "ホーム画面を長押しし、編集 → ウィジェットを追加 をタップ、Tixdayを検索してサイズを選びます。特定のチケットを表示するには、ウィジェットを長押しして「ウィジェットを編集」をタップします。"),
        ("リマインダーが届きません。", "iPhoneの{notif_path}を開き、通知が許可されていることを確認してください。Tixdayは各日付の1か月前、1週間前、前日、そして当日の9:00にお知らせします。"),
        ("Proの購入を復元するには？", "Proを購入したときと同じApple IDでサインインした状態でTixdayを開き、ホーム画面上部のProをタップして「復元」を選んでください。"),
        ("Tixday Proを解約するには？", "サブスクリプションはAppleが管理しています：{cancel_path} → Tixday。"),
        ("Proが終了したらチケットはどうなりますか？", "何も削除されません。直近の3枚はそのまま使え、残りは保存されたままProで再び利用できます。"),
    ],
    effective="施行日：2026年10月9日",
    intro="Tixday（以下「本アプリ」）は、お客様の情報をお客様自身のデバイスに保存するよう設計されています。本ポリシーでは、本アプリが扱うデータとその理由について説明します。",
    sections=[
        ("入力されたデータ", "チケット（タイトル、日付、詳細、設定）はデバイス内にのみ保存されます。開発者である私たちがアクセスすることはできません。"),
        ("写真", "チケットに写真を追加する場合は、Appleの写真ピッカーで選択します。Tixdayが受け取るのは選んだ写真だけで、写真ライブラリにはアクセスしません。縮小したコピーがチケットとともにデバイスに保存されます。"),
        ("アカウント・広告・トラッキングなし", "Tixdayはアカウントを必要とせず、広告を表示せず、分析ツールを使用せず、アプリやWebサイトをまたいでお客様を追跡しません。"),
        ("リマインダーとウィジェット", "リマインダーはデバイス上でスケジュールされるローカル通知で、ウィジェットはデバイス上のチケットを読み込みます。どちらもサーバーを経由しません。"),
        ("購入", "Tixday ProはAppleのApp Storeを通じて購入されます。お支払い情報が私たちに届くことはありません。購入の確認とProの有効化には{rc_link}を使用しています。RevenueCatには、匿名のアプリユーザーID、Tixdayの購入履歴、および基本的なデバイス・アプリ情報が送信されます。お名前、メールアドレス、チケットの情報は送信されません。"),
        ("お子様について", "Tixdayは13歳未満のお子様を対象としておらず、意図的にお子様の情報を収集することはありません。"),
        ("データの削除", "アプリでチケットを削除すると、写真も含めて削除されます。アプリを削除すると、デバイスに保存されたすべてのデータが削除されます。"),
        ("変更", "本ポリシーを変更する場合は、このページと上記の施行日を更新します。"),
        ("お問い合わせ", "{email}"),
    ],
),
"ko": dict(
    home_title="Tixday — 카운트다운 위젯",
    meta="기다리는 모든 날을 홈 화면에서 카운트다운하는 아름다운 티켓으로.",
    hero_h1="모든 날짜는 한 장의 티켓.",
    hero_p="Tixday는 기다리는 날들을 빈티지 포스터 티켓으로 바꿔 줍니다. 여행에는 탑승권, 공연에는 티켓, 결혼식에는 초대장. 홈 화면과 잠금 화면에서 카운트다운합니다.",
    private_strong="프라이버시 우선 설계.",
    private_p="계정도, 광고도, 추적도 없습니다. 티켓은 iPhone에만 저장됩니다.",
    support="지원", privacy="개인정보 처리방침",
    support_intro="질문, 버그 제보, 아이디어가 있으신가요? 언제든 연락 주세요.",
    email_label="이메일", reply_time="보통 영업일 기준 2일 이내에 답변드립니다.",
    faq_title="자주 묻는 질문",
    notif_path="설정 → 알림 → Tixday",
    cancel_path="설정 → [사용자 이름] → 구독",
    faq=[
        ("위젯은 어떻게 추가하나요?", "홈 화면을 길게 누르고 편집 → 위젯 추가를 탭한 뒤 Tixday를 검색해 크기를 고르세요. 특정 티켓을 표시하려면 위젯을 길게 누르고 '위젯 편집'을 탭하세요."),
        ("알림이 오지 않아요.", "iPhone에서 {notif_path}을(를) 열고 알림이 허용되어 있는지 확인하세요. Tixday는 각 날짜의 한 달 전, 일주일 전, 하루 전, 그리고 당일 오전 9시에 알려 드립니다."),
        ("Pro 구매를 복원하려면 어떻게 하나요?", "Pro를 구매한 Apple ID로 로그인한 상태에서 Tixday를 열고 홈 화면 상단의 Pro를 탭한 뒤 '복원'을 선택하세요."),
        ("Tixday Pro를 해지하려면 어떻게 하나요?", "구독은 Apple에서 관리합니다: {cancel_path} → Tixday."),
        ("Pro가 끝나면 티켓은 어떻게 되나요?", "아무것도 삭제되지 않습니다. 가장 가까운 티켓 3장은 계속 사용할 수 있고, 나머지는 저장된 채로 Pro와 함께 다시 열립니다."),
    ],
    effective="시행일: 2026년 10월 9일",
    intro='Tixday(이하 "앱")는 사용자의 정보가 사용자 기기에 머물도록 설계되었습니다. 이 방침은 앱이 어떤 데이터를 왜 처리하는지 설명합니다.',
    sections=[
        ("입력한 데이터", "티켓(제목, 날짜, 세부 정보, 설정)은 기기에만 저장됩니다. 개발자인 저희는 이 데이터에 접근할 수 없습니다."),
        ("사진", "티켓에 사진을 추가할 때는 Apple 사진 선택기로 고릅니다. Tixday는 선택한 사진만 받으며 사진 보관함에는 접근하지 않습니다. 축소된 사본이 티켓과 함께 기기에 저장됩니다."),
        ("계정, 광고, 추적 없음", "Tixday는 계정이 필요 없고, 광고를 표시하지 않으며, 분석 도구를 사용하지 않고, 앱이나 웹사이트 간에 사용자를 추적하지 않습니다."),
        ("알림과 위젯", "알림은 기기에서 예약되는 로컬 알림이고, 위젯은 기기에 있는 티켓을 읽습니다. 어느 것도 서버를 거치지 않습니다."),
        ("구매", "Tixday Pro는 Apple App Store를 통해 구매하며, 결제 정보는 저희에게 전달되지 않습니다. 구매 확인 및 Pro 잠금 해제를 위해 {rc_link}을(를) 사용합니다. RevenueCat은 익명 앱 사용자 ID, Tixday 구매 내역, 기본적인 기기 및 앱 정보를 받습니다. 이름, 이메일 주소, 티켓 정보는 전달되지 않습니다."),
        ("아동", "Tixday는 13세 미만 아동을 대상으로 하지 않으며, 아동의 정보를 고의로 수집하지 않습니다."),
        ("데이터 삭제", "앱에서 티켓을 삭제하면 사진과 함께 삭제됩니다. 앱을 삭제하면 기기에 저장된 모든 데이터가 삭제됩니다."),
        ("변경 사항", "이 방침이 변경되면 이 페이지와 위의 시행일을 업데이트합니다."),
        ("문의", "{email}"),
    ],
),
"zh-Hans": dict(
    home_title="Tixday — 倒数小组件",
    meta="把每个期待的日子，变成在主屏幕上倒数的精美票券。",
    hero_h1="每个日子，都是一张票。",
    hero_p="Tixday 把你期待的日子变成带有复古海报的票券——旅行的登机牌、演唱会门票、婚礼请柬——并在主屏幕和锁定屏幕上倒数。",
    private_strong="隐私至上。",
    private_p="无需账户，没有广告，没有追踪。你的票券只保存在 iPhone 上。",
    support="支持", privacy="隐私政策",
    support_intro="有问题、发现错误或有好点子？欢迎联系我们。",
    email_label="电子邮件", reply_time="我们通常会在 2 个工作日内回复。",
    faq_title="常见问题",
    notif_path="设置 → 通知 → Tixday",
    cancel_path="设置 → [你的姓名] → 订阅",
    faq=[
        ("如何添加小组件？", "长按主屏幕，轻点“编辑”→“添加小组件”，搜索 Tixday 并选择尺寸。若要显示特定票券，长按小组件并轻点“编辑小组件”。"),
        ("我收不到提醒。", "在 iPhone 上打开{notif_path}，确认已允许通知。Tixday 会在每个日子的前一个月、前一周、前一天以及当天 9:00 提醒你。"),
        ("如何恢复我的 Pro 购买？", "使用购买 Pro 时的同一个 Apple 账户登录，打开 Tixday，轻点主屏幕顶部的 Pro，然后选择“恢复”。"),
        ("如何取消 Tixday Pro？", "订阅由 Apple 管理：{cancel_path} → Tixday。"),
        ("Pro 结束后我的票券会怎样？", "不会删除任何内容。最近的三张票券继续可用，其余票券会被保留，重新开通 Pro 后即可解锁。"),
    ],
    effective="生效日期：2026 年 10 月 9 日",
    intro="Tixday（以下简称“本应用”）的设计初衷是让你的信息保留在你自己的设备上。本政策说明本应用处理哪些数据以及原因。",
    sections=[
        ("你输入的数据", "你的票券（标题、日期、详情和设置）仅存储在你的设备上。作为开发者，我们无法访问这些数据。"),
        ("照片", "如果你为票券添加照片，需要通过 Apple 的照片选择器选择；Tixday 只会收到你选择的那张照片，绝不会访问你的照片图库。缩小后的副本会与票券一起存储在你的设备上。"),
        ("无账户、无广告、无追踪", "Tixday 无需账户，不显示广告，不使用分析工具，也不会跨应用或网站追踪你。"),
        ("提醒和小组件", "提醒是在你设备上安排的本地通知，小组件从你的设备读取票券。两者都不经过任何服务器。"),
        ("购买", "Tixday Pro 通过 Apple 的 App Store 购买，我们从不会收到你的付款信息。我们使用 {rc_link} 来验证购买并解锁 Pro。RevenueCat 会收到一个匿名应用用户标识符、你的 Tixday 购买记录以及基本的设备和应用信息，但不会收到你的姓名、电子邮件地址或你的票券。"),
        ("儿童", "Tixday 不面向 13 岁以下儿童，也不会有意收集他们的信息。"),
        ("删除你的数据", "在应用中删除票券会将其连同照片一起移除。删除应用会移除设备上存储的所有数据。"),
        ("变更", "如本政策有变更，我们将更新此页面及上方的生效日期。"),
        ("联系我们", "{email}"),
    ],
),
"ru": dict(
    home_title="Tixday — виджеты обратного отсчёта",
    meta="Каждый долгожданный день — как красивый билет с обратным отсчётом на экране «Домой».",
    hero_h1="Каждая дата — это билет.",
    hero_p="Tixday превращает дни, которых вы ждёте, в билеты с винтажными постерами — посадочный талон для поездки, билет на концерт, приглашение на свадьбу — и ведёт обратный отсчёт на экране «Домой» и экране блокировки.",
    private_strong="Приватность прежде всего.",
    private_p="Без аккаунта, без рекламы и слежки. Ваши билеты остаются на iPhone.",
    support="Поддержка", privacy="Политика конфиденциальности",
    support_intro="Вопросы, ошибки или идеи? Будем рады вашему письму.",
    email_label="Эл. почта", reply_time="Обычно отвечаем в течение 2 рабочих дней.",
    faq_title="Частые вопросы",
    notif_path="Настройки → Уведомления → Tixday",
    cancel_path="Настройки → [ваше имя] → Подписки",
    faq=[
        ("Как добавить виджет?", "Нажмите и удерживайте экран «Домой», коснитесь «Править» → «Добавить виджет», найдите Tixday и выберите размер. Чтобы показать конкретный билет, удерживайте виджет и коснитесь «Изменить виджет»."),
        ("Мне не приходят напоминания.", "Откройте {notif_path} на iPhone и убедитесь, что уведомления разрешены. Tixday напоминает за месяц, за неделю и за день до каждой даты, а также в сам день в 9:00."),
        ("Как восстановить покупку Pro?", "Откройте Tixday, коснитесь Pro вверху главного экрана и выберите «Восстановить», войдя с тем же Apple ID, с которым покупали Pro."),
        ("Как отменить Tixday Pro?", "Подписками управляет Apple: {cancel_path} → Tixday."),
        ("Что будет с билетами, если Pro закончится?", "Ничего не удаляется. Три ближайших билета продолжают работать, остальные сохраняются и снова открываются с Pro."),
    ],
    effective="Дата вступления в силу: 9 октября 2026 г.",
    intro="Tixday («приложение») создано так, чтобы ваши данные оставались на вашем устройстве. Здесь объясняется, какие данные обрабатывает приложение и зачем.",
    sections=[
        ("Данные, которые вы вводите", "Ваши билеты (названия, даты, подробности и настройки) хранятся только на вашем устройстве. У нас, разработчика, нет к ним доступа."),
        ("Фото", "Если вы добавляете фото к билету, вы выбираете его в системном окне выбора фото Apple: Tixday получает только это фото и никогда — вашу медиатеку. Уменьшенная копия хранится вместе с билетом на устройстве."),
        ("Без аккаунтов, рекламы и слежки", "Tixday не требует аккаунта, не показывает рекламу, не использует аналитику и не отслеживает вас в других приложениях и на сайтах."),
        ("Напоминания и виджеты", "Напоминания — это локальные уведомления, запланированные на устройстве, а виджеты читают билеты с вашего устройства. Ничего не проходит через сервер."),
        ("Покупки", "Tixday Pro покупается через App Store от Apple; мы никогда не получаем ваши платёжные данные. Для проверки покупок и включения Pro мы используем {rc_link}. RevenueCat получает анонимный идентификатор пользователя приложения, историю ваших покупок в Tixday и базовые сведения об устройстве и приложении. Он не получает ваше имя, адрес эл. почты или ваши билеты."),
        ("Дети", "Tixday не предназначен для детей младше 13 лет и сознательно не собирает их данные."),
        ("Удаление данных", "Удаление билета в приложении удаляет его вместе с фото. Удаление приложения удаляет все данные на устройстве."),
        ("Изменения", "Если политика изменится, мы обновим эту страницу и дату вступления в силу выше."),
        ("Контакты", "{email}"),
    ],
),
"ar": dict(
    home_title="Tixday — أدوات العد التنازلي",
    meta="كل يوم تنتظره، كتذكرة جميلة تعدّ تنازليًا على شاشتك الرئيسية.",
    hero_h1="كل تاريخ تذكرة.",
    hero_p="يحوّل Tixday الأيام التي تنتظرها إلى تذاكر بملصقات عتيقة — بطاقة صعود لرحلتك، وتذكرة حفلة، ودعوة زفاف — ويعدّها تنازليًا على الشاشة الرئيسية وشاشة القفل.",
    private_strong="الخصوصية أولًا.",
    private_p="لا حساب، ولا إعلانات، ولا تتبّع. تبقى تذاكرك على iPhone الخاص بك.",
    support="الدعم", privacy="سياسة الخصوصية",
    support_intro="أسئلة أو أخطاء أو أفكار؟ يسعدنا أن نسمع منك.",
    email_label="البريد الإلكتروني", reply_time="نرد عادةً خلال يومي عمل.",
    faq_title="الأسئلة الشائعة",
    notif_path="الإعدادات ← الإشعارات ← Tixday",
    cancel_path="الإعدادات ← [اسمك] ← الاشتراكات",
    faq=[
        ("كيف أضيف أداة؟", "اضغط مطولًا على الشاشة الرئيسية، ثم اضغط تعديل ← إضافة أداة، وابحث عن Tixday واختر الحجم. لعرض تذكرة معيّنة، اضغط مطولًا على الأداة ثم اختر تعديل الأداة."),
        ("لا تصلني التذكيرات.", "افتح {notif_path} على iPhone وتأكد من السماح بالإشعارات. يذكّرك Tixday قبل كل تاريخ بشهر وأسبوع ويوم، وفي اليوم نفسه الساعة 9:00."),
        ("كيف أستعيد عملية شراء Pro؟", "افتح Tixday واضغط Pro أعلى الشاشة الرئيسية ثم اختر استعادة، وأنت مسجّل الدخول بنفس الـ Apple ID الذي اشتريت به Pro."),
        ("كيف ألغي Tixday Pro؟", "تدير Apple الاشتراكات: {cancel_path} ← Tixday."),
        ("ماذا يحدث لتذاكري إذا انتهى Pro؟", "لا يُحذف شيء. تبقى أقرب ثلاث تذاكر تعمل، وتُحفظ البقية وتُفتح مجددًا مع Pro."),
    ],
    effective="تاريخ السريان: 9 أكتوبر 2026",
    intro="صُمّم Tixday («التطبيق») لإبقاء معلوماتك على جهازك. توضح هذه السياسة البيانات التي يتعامل معها التطبيق وسبب ذلك.",
    sections=[
        ("البيانات التي تُدخلها", "تُخزَّن تذاكرك (العناوين والتواريخ والتفاصيل والإعدادات) على جهازك فقط. لا يمكننا، نحن المطوّر، الوصول إليها."),
        ("الصور", "إذا أضفت صورة إلى تذكرة، فإنك تختارها عبر أداة اختيار الصور من Apple، فلا يتلقى Tixday سوى تلك الصورة ولا يصل أبدًا إلى مكتبة صورك. تُحفظ نسخة مصغّرة مع التذكرة على جهازك."),
        ("لا حسابات ولا إعلانات ولا تتبّع", "لا يتطلب Tixday حسابًا، ولا يعرض إعلانات، ولا يستخدم أدوات تحليل، ولا يتتبّعك عبر التطبيقات أو المواقع."),
        ("التذكيرات والأدوات", "التذكيرات إشعارات محلية مجدولة على جهازك، والأدوات تقرأ تذاكرك من جهازك. لا يمر أي منهما عبر خادم."),
        ("المشتريات", "يُشترى Tixday Pro عبر App Store من Apple، ولا نتلقى بيانات الدفع الخاصة بك أبدًا. نستخدم {rc_link} للتحقق من المشتريات وتفعيل Pro. يتلقى RevenueCat معرّف مستخدم مجهول الهوية للتطبيق، وسجل مشترياتك في Tixday، ومعلومات أساسية عن الجهاز والتطبيق. ولا يتلقى اسمك أو بريدك الإلكتروني أو تذاكرك."),
        ("الأطفال", "Tixday غير موجّه للأطفال دون سن 13 عامًا، ولا يجمع معلوماتهم عن قصد."),
        ("حذف بياناتك", "حذف تذكرة في التطبيق يزيلها مع صورتها. وحذف التطبيق يزيل كل البيانات المخزّنة على جهازك."),
        ("التغييرات", "إذا تغيّرت هذه السياسة، فسنحدّث هذه الصفحة وتاريخ السريان أعلاه."),
        ("التواصل", "{email}"),
    ],
),
}

PAGES = ["index.html", "support.html", "privacy.html"]


def esc(text):
    return html.escape(text, quote=False)


def fill(text, t):
    """Escapes a paragraph, then inserts links and navigation paths."""
    return esc(text).format(
        rc_link='<a href="%s">RevenueCat</a>' % RC_URL,
        email='<a href="mailto:%s">%s</a>' % (EMAIL, EMAIL),
        notif_path=esc(t["notif_path"]),
        cancel_path=esc(t["cancel_path"]),
    )


def page_url(folder, page):
    return (folder + "/" if folder else "") + ("" if page == "index.html" else page)


def render(folder, lang, page):
    t = TEXT[lang]
    root = "../" if folder else ""
    title = {"index.html": t["home_title"], "support.html": "Tixday — " + t["support"], "privacy.html": "Tixday — " + t["privacy"]}[page]

    alternates = "\n".join(
        '  <link rel="alternate" hreflang="%s" href="%s%s">' % (code, BASE_URL, page_url(f, page))
        for f, code, _ in LANGUAGES
    )
    switcher = " · ".join(
        ('<strong>%s</strong>' % esc(name)) if code == lang else '<a href="%s%s" hreflang="%s">%s</a>' % (root, page_url(f, page) or "./", code, esc(name))
        for f, code, name in LANGUAGES
    )

    if page == "index.html":
        body = """  <section class="hero">
    <img class="poster" src="{root}hero.jpg" alt="">
    <h1>{h1}</h1>
    <p class="muted">{p}</p>
  </section>

  <div class="card">
    <strong>{ps}</strong>
    <p class="muted">{pp}</p>
  </div>

  <nav class="links">
    <a href="support.html">{support}</a>
    <a href="privacy.html">{privacy}</a>
  </nav>""".format(root=root, h1=esc(t["hero_h1"]), p=esc(t["hero_p"]), ps=esc(t["private_strong"]), pp=esc(t["private_p"]),
                   support=esc(t["support"]), privacy=esc(t["privacy"]))
    elif page == "support.html":
        faqs = "\n\n".join(
            '  <div class="card">\n    <strong>%s</strong>\n    <p class="muted">%s</p>\n  </div>' % (esc(q), fill(a, t))
            for q, a in t["faq"]
        )
        body = """  <h1>{title}</h1>
  <p class="muted">{intro}</p>

  <div class="card">
    <strong>{email_label}</strong>
    <p><a href="mailto:{email}">{email}</a></p>
    <p class="muted">{reply}</p>
  </div>

  <h2>{faq_title}</h2>

{faqs}""".format(title=esc(t["support"]), intro=esc(t["support_intro"]), email_label=esc(t["email_label"]),
                 email=EMAIL, reply=esc(t["reply_time"]), faq_title=esc(t["faq_title"]), faqs=faqs)
    else:
        sections = "\n\n".join("  <h2>%s</h2>\n  <p>%s</p>" % (esc(h), fill(p, t)) for h, p in t["sections"])
        body = """  <h1>{title}</h1>
  <p class="muted">{effective}</p>

  <p>{intro}</p>

{sections}""".format(title=esc(t["privacy"]), effective=esc(t["effective"]), intro=esc(t["intro"]), sections=sections)

    footer_links = {
        "index.html": "",
        "support.html": '<a href="privacy.html">%s</a> · ' % esc(t["privacy"]),
        "privacy.html": '<a href="support.html">%s</a> · ' % esc(t["support"]),
    }[page]

    return """<!doctype html>
<html lang="{lang}"{dir}>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="dark">
  <title>{title}</title>
  <meta name="description" content="{meta}">
{alternates}
  <link rel="icon" href="{root}icon.png">
  <link rel="apple-touch-icon" href="{root}icon.png">
  <link rel="stylesheet" href="{root}style.css">
</head>
<body>
<main>
  <header class="brand">
    <img src="{root}icon.png" alt="">
    <a href="{home}">Tixday</a>
  </header>

{body}

  <footer>
    <p>{footer_links}© 2026 Tixday</p>
    <p class="lang-switch">{switcher}</p>
  </footer>
</main>
</body>
</html>
""".format(lang=lang, dir=' dir="rtl"' if lang in RTL else "", title=esc(title), meta=html.escape(t["meta"]), alternates=alternates, root=root,
           home="./", body=body, footer_links=footer_links, switcher=switcher)


def main():
    for folder, lang, _ in LANGUAGES:
        out_dir = SITE / folder if folder else SITE
        out_dir.mkdir(parents=True, exist_ok=True)
        for page in PAGES:
            (out_dir / page).write_text(render(folder, lang, page), encoding="utf-8")
    print("Generated %d pages in %s" % (len(LANGUAGES) * len(PAGES), SITE))


if __name__ == "__main__":
    main()
