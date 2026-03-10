import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final responseToMe = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      "service_id": "service_3d9xwvb",
      "template_id": "template_zqvb6bh",
      "user_id": "d-I1mrXXWnxMgFTOM",
      "template_params": {
        "name": "Test",
        "email": "test@test.com",
        "message": "test msg",
        "subject": "test subj",
      },
    }),
  );
  print('Status: ${responseToMe.statusCode}');
  print('Body: ${responseToMe.body}');
}
