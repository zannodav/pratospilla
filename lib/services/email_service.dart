class EmailService {
  /// Funzione per inviare l'email con i dettagli della prenotazione.
  Future<bool> sendBookingEmail({
    required String name,
    required String email,
    required int guests,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Simula successo (Mock per demo)
      await Future.delayed(const Duration(seconds: 2));
      print("SIMULAZIONE: Email inviata a giudidgd@gmail.com. Dettagli:");
      print("Nome: $name, Ospiti: $guests, Contatto: $email");
      print("Check-in: ${checkIn.day}/${checkIn.month}/${checkIn.year}");
      print("Check-out: ${checkOut.day}/${checkOut.month}/${checkOut.year}");
      return true;
    } catch (e) {
      print("Errore nell'invio dell'email: $e");
      return false;
    }
  }
}
