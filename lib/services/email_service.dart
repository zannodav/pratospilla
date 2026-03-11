import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EmailService extends ChangeNotifier {
  bool _isSending = false;
  bool get isSending => _isSending;

  Future<bool> sendBookingEmail({
    required String name,
    required String email,
    required int guests,
    required DateTime checkIn,
    required DateTime checkOut,
    //required String message,
    //required String subject,
  }) async {
    _isSending = true;
    notifyListeners();

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final message = "Richiesta di prenotazione:\n\n"
        "Nome: $name\n"
        "Email: $email\n"
        "Ospiti: $guests\n"
        "Check-in: ${checkIn.day}/${checkIn.month}/${checkIn.year}\n"
        "Check-out: ${checkOut.day}/${checkOut.month}/${checkOut.year}";
    final subject = "Richiesta di prenotazione di $name";
    try {
      //This function is used to send email
      final responseToMe = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          //encoding your body
          "service_id": "service_3d9xwvb",
          "template_id": "template_zqvb6bh",
          "user_id": "d-I1mrXXWnxMgFTOM",
          "template_params": {
            "name": name,
            "email": email,
            "message": message,
            "subject": subject,
          },
        }),
      );

      //make sure this template_params should match with your template

      //If you needed create function for acknowledge also

      if (responseToMe.statusCode == 200) {
        _isSending = false;
        notifyListeners();
        return true;
      } else {
        _isSending = false;
        notifyListeners();
        print("Errore nell'invio dell'email: HTTP ${responseToMe.statusCode}");
        print("Dettagli: ${responseToMe.body}");
        return false;
      }
    } catch (e) {
      _isSending = false;
      notifyListeners();
      print("Eccezione nell'invio dell'email: $e");
      return false;
    }
  }
}
/*
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
*/
