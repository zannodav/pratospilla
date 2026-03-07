# Prato Spilla Vacation Rental App

Questa applicazione è stata creata con Flutter Web ed è strutturata secondo il pattern Architetturale **MVVM (Model-View-ViewModel)**.

## Struttura del Progetto

- **`lib/main.dart`**: Entrypoint dell'applicazione.
- **`lib/views/home_page.dart`**: UI principale (View) responsive. Include la galleria, la descrizione, i servizi, il calendario e il form di contatto.
- **`lib/view_models/home_view_model.dart`**: La logica applicativa (ViewModel) che gestisce la selezione delle date, i caricamenti e l'invio del form.
- **`lib/services/calendar_service.dart`**: Servizio per il recupero e il parsing dei file `.ics` da iCal (Airbnb, Booking).
- **`lib/services/email_service.dart`**: Servizio per l'invio delle email simulate.

## Sincronizzazione Centralizzata con Google Calendar

Invece di scaricare iCal separati, l'app utilizza **Google Calendar come Hub Centrale** (quasi un Channel Manager di base).

**Come Configurare:**
1. **Importa iCal su Google:**
   - Prendi i link di esportazione `.ics` da Airbnb e Booking.
   - Vai su Google Calendar > "Altri calendari" (+) > "Da URL" e incolla i link.
2. **Collegamento Flutter <-> Google Calendar:**
   - Vai sulla [Google Cloud Console](https://console.cloud.google.com/), crea un progetto, e abilita la **Google Calendar API**.
   - Crea un **Service Account**, genera una chiave JSON e inseriscila in `lib/services/calendar_service.dart`.
3. **Lettura:** 
   - L'app usa `googleapis` per leggere `calendar.events.list`, recuperando la disponibilità già fusa insieme da Google Calendar (che sincronizza automaticamente Airbnb e Booking).
4. **Scrittura (Prenotazione Diretta):**
   - Quando un utente del sito inoltra una richiesta, l'app genera istantaneamente un nuovo evento su Google usando `api.events.insert` (con un colore dedicato per distinguerlo in stato "pending").

## Sistema Email

Il form interagisce con il file `lib/services/email_service.dart`. Includere librerie serverless (come l'API di **EmailJS**) permette di mandare la mail di notifica alla tua casella ("Tua Email") senza il bisogno di sviluppare un backend proprietario in Node o Python.

## Istruzioni per l'Esecuzione

Poiché al momento Flutter non è installato nel sistema, dovrai eseguire i seguenti passaggi prima di poterlo visualizzare:

1. **Installa Flutter**: Assicurati che Flutter sia installato ([Guida Ufficiale](https://docs.flutter.dev/get-started/install)).
2. **Inizializza il Progetto**:
   Lancia nel terminale in questa cartella (`/home/davide/Documenti/Programming/pratospilla`):
   ```bash
   flutter create --platforms web .
   ```
3. **Ottieni le Dipendenze**:
   ```bash
   flutter pub get
   ```
4. **Esegui**:
   ```bash
   flutter run -d chrome
   ```
