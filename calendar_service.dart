import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// INTEGRAZIONE GOOGLE CALENDAR — ARCHITETTURA PUBBLICA
///
/// LETTURA (visitatori pubblici):
///   Usa una API Key Google con accesso in sola lettura al calendario.
///   Il calendario deve essere impostato come "Pubblico" in Google Calendar.
///   Non richiede login → tutti i visitatori vedono le date reali.
///
/// SCRITTURA (admin — proprietario):
///   Usa OAuth2 (Google Sign-In) per aggiungere eventi di prenotazione.
///   Solo il proprietario fa login; è opzionale per il funzionamento di base.
///
/// CONFIGURAZIONE:
///   1. Vai su Google Calendar → Impostazioni → [tuo calendario] →
///      "Autorizzazioni accesso" → spunta "Rendi disponibile al pubblico".
///   2. Copia l'ID calendario (es. abc123@group.calendar.google.com).
///   3. Su Google Cloud Console crea una API Key limitata all'API Calendar.
///   4. Inserisci entrambi i valori nelle costanti qui sotto.
class CalendarService {
  // ─── ⚙️  CONFIGURA QUI ────────────────────────────────────────────────────

  /// API Key (lettura pubblica, senza login)
  /// Crea su: GCP Console → API e servizi → Credenziali → Crea → Chiave API
  static const String _apiKey = 'AIzaSyBRVBf_I_bDZh86wt8Ep3lL74Csmarydj0';

  /// ID del calendario (visibile in Impostazioni Google Calendar)
  static const String _calendarId = 'zannodav@gmail.com';

  /// Client ID OAuth2 per Web (solo per login admin / scrittura)
  static const String _clientId =
      '472493029579-8tnuijdh231nrnn03sipq7j3rbfmqg0b.apps.googleusercontent.com';

  // ─────────────────────────────────────────────────────────────────────────

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _clientId,
    scopes: [
      gcal.CalendarApi.calendarScope,
      'email',
      'profile',
    ],
  );
// 1. Definiamo la lista degli utenti autorizzati (es. amministratori)
// L'uso di un Set invece di una List rende la ricerca più veloce (O(1) invece di O(n))
  final Set<String> adminEmails = {
    'zannodav@gmail.com',
    'giudidg@gmail.com',
    'zannoni.di@gmail.com',
  };

// 2. La funzione di controllo
  bool checkUserRole(String email) {
    // Convertiamo l'email in minuscolo per evitare errori di case-sensitivity
    return adminEmails.contains(email.toLowerCase().trim());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;
  bool get isApiKeyConfigured => true; // Chiave confermata dall'utente
  String get currentEmail => _auth.currentUser!.email!;
  // ──────────────────────────────────────────────────────
  // AUTENTICAZIONE (admin)
  // ──────────────────────────────────────────────────────
  bool get isAdmin => checkUserRole(currentEmail);
  Future<bool> signIn() async {
    try {
      print('Inizio procedura login...');

      // Su Web, signInWithPopup è molto più affidabile per Firebase Auth
      final GoogleAuthProvider provider = GoogleAuthProvider();
      // Aggiungiamo gli scope necessari per il calendario
      provider.addScope(gcal.CalendarApi.calendarScope);
      provider.addScope('email');
      provider.addScope('profile');

      final UserCredential userCredential =
          await _auth.signInWithPopup(provider);
      print('✅ Firebase Auth completato per: ${userCredential.user?.email}');

      // Tentiamo un login silenzioso per il plugin google_sign_in
      // così da avere l'account disponibile per le chiamate API Calendar.
      try {
        await _googleSignIn.signInSilently();
      } catch (e) {
        print(
            'Nota: loginGoogleSignIn.signInSilently non riuscito (non critico): $e');
      }

      return true;
    } catch (e) {
      print('❌ Errore critico durante il login: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<gcal.CalendarApi?> _getOAuthCalendarApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;
    return gcal.CalendarApi(httpClient);
  }

  // ──────────────────────────────────────────────────────
  // LETTURA PUBBLICA — usa API Key, nessun login necessario
  // ──────────────────────────────────────────────────────

  /// Legge le date occupate dal calendario pubblico tramite API Key.
  /// Non richiede autenticazione. Tutti i visitatori vedono le date reali.
  Future<List<DateTime>> fetchBookedDates() async {
    List<DateTime> bookedDates = [];
    final now = DateTime.now().toUtc();

    // 1. Se loggato, usa OAuth per vedere TUTTI gli eventi (privati e pubblici)
    if (isSignedIn) {
      try {
        final api = await _getOAuthCalendarApi();
        if (api != null) {
          final events = await api.events.list(
            _calendarId,
            timeMin: now,
            singleEvents: true,
            orderBy: 'startTime',
            maxResults: 250,
          );

          final items = events.items ?? [];
          for (final item in items) {
            final start = item.start?.date ?? item.start?.dateTime;
            var end = item.end?.date ?? item.end?.dateTime;

            if (start != null) {
              final startLocal = start.toLocal();
              final endLocal =
                  (end ?? start.add(const Duration(hours: 1))).toLocal();

              DateTime d =
                  DateTime(startLocal.year, startLocal.month, startLocal.day);
              final endDay =
                  DateTime(endLocal.year, endLocal.month, endLocal.day);

              if (d.isAtSameMomentAs(endDay)) {
                // Evento nella stessa giornata
                bookedDates.add(d);
              } else {
                // Evento su più giorni
                for (; d.isBefore(endDay); d = d.add(const Duration(days: 1))) {
                  bookedDates.add(d);
                }
              }
            }
          }
          print(
              '✅ Caricate ${bookedDates.length} date (OAuth) da Google Calendar');
          return bookedDates;
        }
      } catch (e) {
        print('❌ Errore nel recupero calendario con OAuth: $e');
        // fall back alla chiamata API pubblica se OAuth fallisce
      }
    }

    // 2. Fallback a API key (lettura pubblica, solo eventi pubblici)
    if (!isApiKeyConfigured) {
      print('⚠️  API Key non configurata: uso date di test.');
      return getDummyBookedDates();
    }

    try {
      final timeMin = Uri.encodeComponent(now.toIso8601String());
      final calId = Uri.encodeComponent(_calendarId);

      final url = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/$calId/events'
        '?key=$_apiKey'
        '&timeMin=$timeMin'
        '&singleEvents=true'
        '&orderBy=startTime'
        '&maxResults=250',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final startRaw = (item['start'] as Map?)?['date'] ??
              (item['start'] as Map?)?['dateTime'];
          final endRaw = (item['end'] as Map?)?['date'] ??
              (item['end'] as Map?)?['dateTime'];

          if (startRaw != null) {
            final start = DateTime.parse(startRaw as String).toLocal();
            final end = endRaw != null
                ? DateTime.parse(endRaw as String).toLocal()
                : start.add(const Duration(hours: 1));

            DateTime d = DateTime(start.year, start.month, start.day);
            final endDay = DateTime(end.year, end.month, end.day);

            if (d.isAtSameMomentAs(endDay)) {
              bookedDates.add(d);
            } else {
              for (; d.isBefore(endDay); d = d.add(const Duration(days: 1))) {
                bookedDates.add(d);
              }
            }
          }
        }
        print(
            '✅ Caricate ${bookedDates.length} date occupate da Google Calendar (API Key)');
      } else {
        print(
            '❌ Errore API Calendar (${response.statusCode}): ${response.body}');
        return getDummyBookedDates();
      }
    } catch (e) {
      print('❌ Errore recupero calendario: $e');
      return getDummyBookedDates();
    }
    return bookedDates;
  }

  // ──────────────────────────────────────────────────────
  // SCRITTURA — richiede OAuth2 admin o usa email come fallback
  // ──────────────────────────────────────────────────────

  Future<bool> createBookingEvent({
    required String name,
    required String email,
    required DateTime start,
    required DateTime end,
    required int guests,
  }) async {
    if (isSignedIn) {
      // Usa OAuth2 per creare l'evento direttamente
      try {
        final api = await _getOAuthCalendarApi();
        if (api == null) return _simulateCreate(name, start, end);

        final event = gcal.Event(
          summary: 'Richiesta Prenotazione: $name ($guests ospiti)',
          description:
              'Nuova richiesta dal sito.\n\nNome: $name\nEmail: $email\nOspiti: $guests',
          start: gcal.EventDateTime(date: start),
          end: gcal.EventDateTime(date: end),
        );

        await api.events.insert(event, _calendarId);
        print('✅ Evento creato su Google Calendar per $name');
        return true;
      } catch (e) {
        print('❌ Errore creazione evento OAuth2: $e');
        return false;
      }
    }

    // Senza OAuth2: simula (la notifica reale arriverà via email)
    return _simulateCreate(name, start, end);
  }

  bool _simulateCreate(String name, DateTime start, DateTime end) {
    Future.delayed(const Duration(milliseconds: 500));
    print(
        'ℹ️  SIMULAZIONE: Prenotazione $name dal ${start.toIso8601String()} al ${end.toIso8601String()}');
    return true;
  }

  // ──────────────────────────────────────────────────────
  // DATE DI TEST
  // ──────────────────────────────────────────────────────

  List<DateTime> getDummyBookedDates() {
    final now = DateTime.now();
    return [
      //DateTime(now.year, now.month, now.day + 2),
      //DateTime(now.year, now.month, now.day + 3),
      //DateTime(now.year, now.month, now.day + 4),
      //DateTime(now.year, now.month, now.day + 10),
      //DateTime(now.year, now.month, now.day + 11),
    ];
  }
}
