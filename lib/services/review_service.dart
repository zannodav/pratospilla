import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String name;
  final int rating;
  final String text;
  final DateTime date;
  final bool approved;

  ReviewModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.text,
    required this.date,
    this.approved = false,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Ospite',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      text: data['text'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approved: data['approved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'rating': rating,
        'text': text,
        'date': Timestamp.fromDate(date),
        'approved': approved,
      };
}

/// Servizio per gestire le recensioni su Firebase Firestore.
class ReviewService {
  static const String _collection = 'reviews';

  bool _firestoreAvailable = true;

  // Recensioni locali come fallback se Firestore non è configurato
  final List<ReviewModel> _localReviews = [
    ReviewModel(
      id: '1',
      name: 'Marco R.',
      rating: 5,
      text:
          'Posto meraviglioso! La baita è accogliente, pulita e ben attrezzata. La terrazza con vista sui monti è stupenda. Torneremo sicuramente!',
      date: DateTime(2024, 8, 15),
      approved: true,
    ),
    ReviewModel(
      id: '2',
      name: 'Giulia e Luca',
      rating: 5,
      text:
          'Weekend perfetto. I sentieri nelle vicinanze sono bellissimi e la struttura è esattamente come nelle foto. Host disponibilissimo.',
      date: DateTime(2024, 7, 22),
      approved: true,
    ),
    ReviewModel(
      id: '3',
      name: 'Famiglia Bianchi',
      rating: 4,
      text:
          "Esperienza molto positiva. I bambini hanno adorato i laghetti vicini. La cucina è completamente attrezzata, ci siamo trovati benissimo.",
      date: DateTime(2024, 9, 3),
      approved: true,
    ),
    ReviewModel(
      id: '4',
      name: 'Stefania M.',
      rating: 5,
      text:
          'Silenzio, natura e relax totale. Abbiamo passato 5 giorni qui e non volevamo più andarcene. La terrazza al tramonto è indimenticabile.',
      date: DateTime(2024, 6, 10),
      approved: true,
    ),
  ];

  /// Legge le recensioni da Firestore (o quelle locali come fallback)
  /// Se [isAdmin] è true, restituisce tutte le recensioni, altrimenti solo quelle approvate.
  Future<List<ReviewModel>> fetchReviews({bool isAdmin = false}) async {
    List<ReviewModel> reviews = [];

    if (_firestoreAvailable) {
      try {
        Query query = FirebaseFirestore.instance.collection(_collection);

        if (!isAdmin) {
          query = query.where('approved', isEqualTo: true);
        }

        final snapshot = await query.orderBy('date', descending: true).get();
        reviews =
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
      } catch (e) {
        print('⚠️ Errore Firestore fetch: $e');
        _firestoreAvailable = false;
      }
    }

    // Se Firestore non è disponibile o è vuoto (per i guest), usa i locali filtrati
    if (reviews.isEmpty) {
      if (isAdmin) {
        return List.unmodifiable(_localReviews);
      } else {
        return _localReviews.where((r) => r.approved).toList();
      }
    }

    return reviews;
  }

  /// Approva una recensione (solo admin)
  Future<bool> approveReview(String reviewId) async {
    try {
      if (_firestoreAvailable) {
        await FirebaseFirestore.instance
            .collection(_collection)
            .doc(reviewId)
            .update({'approved': true});
      }

      // Aggiorna anche localmente se presente
      final index = _localReviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        final old = _localReviews[index];
        _localReviews[index] = ReviewModel(
          id: old.id,
          name: old.name,
          rating: old.rating,
          text: old.text,
          date: old.date,
          approved: true,
        );
      }

      return true;
    } catch (e) {
      print('❌ Errore approvazione recensione: $e');
      return false;
    }
  }

  /// Elimina una recensione (solo admin)
  Future<bool> deleteReview(String reviewId) async {
    try {
      if (_firestoreAvailable) {
        await FirebaseFirestore.instance
            .collection(_collection)
            .doc(reviewId)
            .delete();
      }

      // Rimuovi anche dalla lista locale se presente
      _localReviews.removeWhere((r) => r.id == reviewId);

      return true;
    } catch (e) {
      print('❌ Errore eliminazione recensione: $e');
      return false;
    }
  }

  /// Invia una nuova recensione a Firestore (in attesa di approvazione)
  Future<bool> submitReview({
    required String name,
    required int rating,
    required String text,
  }) async {
    final review = ReviewModel(
      id: '',
      name: name,
      rating: rating,
      text: text,
      date: DateTime.now(),
      approved: false,
    );

    if (!_firestoreAvailable) {
      // Modalità offline: aggiungi localmente con ID temporaneo
      _localReviews.insert(
        0,
        ReviewModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          rating: rating,
          text: text,
          date: DateTime.now(),
          approved: false,
        ),
      );
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .add(review.toFirestore());
      print('✅ Recensione inviata a Firestore (in attesa di moderazione)');
      return true;
    } catch (e) {
      print('❌ Errore invio recensione Firestore: $e');
      // Fallback locale
      _firestoreAvailable = false;
      return submitReview(name: name, rating: rating, text: text);
    }
  }
}
