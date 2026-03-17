import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/calendar_service.dart';
import '../services/email_service.dart';
import '../services/review_service.dart';
import '../services/content_service.dart';

class HomeViewModel extends ChangeNotifier {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  List<DateTime> _bookedDates = [];
  bool _isLoading = false;

  List<ReviewModel> _reviews = [];
  bool _reviewsLoading = false;

  List<GalleryImage> _gallery = [];
  bool _galleryLoading = false;

  List<Activity> _activities = [];
  bool _activitiesLoading = false;

  List<SliderImage> _sliderImages = [];
  bool _sliderLoading = false;
  String _sliderStatus = 'Inizializzazione...';
  String _sliderError = '';

  String _heroTitle = 'Fuga Romantica tra i Monti di Prato Spilla';
  String _heroDescription =
      "Vivi un'esperienza indimenticabile al confine tra Emilia-Romagna e Toscana. "
      "Questi accoglienti alloggi sono il rifugio perfetto per staccare dal caos cittadino. "
      "Immersa nella natura incontaminata, potrai svegliarti col canto degli uccellini, "
      "fare trekking nei boschi circostanti, o semplicemente rilassarti e dedicarti ai tuoi hobby.";

  int _draftReviewRating = 5;
  int get draftReviewRating => _draftReviewRating;
  void setDraftReviewRating(int rating) {
    _draftReviewRating = rating;
    notifyListeners();
  }

  DateTime? get checkInDate => _checkInDate;
  DateTime? get checkOutDate => _checkOutDate;
  List<DateTime> get bookedDates => _bookedDates;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _calendarService.isSignedIn;
  List<ReviewModel> get reviews => List.unmodifiable(_reviews);
  bool get reviewsLoading => _reviewsLoading;
  List<GalleryImage> get gallery => List.unmodifiable(_gallery);
  bool get galleryLoading => _galleryLoading;
  List<Activity> get activities => List.unmodifiable(_activities);
  bool get activitiesLoading => _activitiesLoading;
  List<SliderImage> get sliderImages => List.unmodifiable(_sliderImages);
  bool get sliderLoading => _sliderLoading;
  String get sliderStatus => _sliderStatus;
  String get sliderError => _sliderError;
  String get heroTitle => _heroTitle;
  String get heroDescription => _heroDescription;

  final CalendarService _calendarService = CalendarService();
  final EmailService _emailService = EmailService();
  final ReviewService _reviewService = ReviewService();
  final ContentService _contentService = ContentService();

  HomeViewModel() {
    _loadBookedDates();
    _loadReviews();
    _loadGallery();
    _loadActivities();
    _loadSliderImages();
    _loadHeroText();
  }

  Future<void> _loadBookedDates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bookedDates = await _calendarService.fetchBookedDates();
    } catch (e) {
      debugPrint("Error loading calendar data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Avvia il login Google OAuth2 e ricarica le date dal calendario reale
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final success = await _calendarService.signIn();
    if (success) {
      // Ricarica le date dal calendario reale ora che siamo autenticati
      await _loadBookedDates();
      // Ricarica le recensioni per vedere quelle in attesa di approvazione
      await _loadReviews();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<void> signOut() async {
    await _calendarService.signOut();
    // Torna alle date pubbliche dopo il logout
    await _loadBookedDates();
    // Torna alle recensioni pubbliche
    await _loadReviews();
    notifyListeners();
  }

  Future<void> _loadReviews() async {
    _reviewsLoading = true;
    notifyListeners();
    try {
      _reviews = await _reviewService.fetchReviews(isAdmin: isSignedIn);
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _reviewsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveReview(String id) async {
    final success = await _reviewService.approveReview(id);
    if (success) {
      await _loadReviews();
    }
    return success;
  }

  Future<bool> deleteReview(String id) async {
    final success = await _reviewService.deleteReview(id);
    if (success) {
      await _loadReviews();
    }
    return success;
  }

  Future<bool> submitReview({
    required String name,
    required int rating,
    required String text,
  }) async {
    final success = await _reviewService.submitReview(
      name: name,
      rating: rating,
      text: text,
    );
    if (success) {
      // Ricarica le recensioni dopo l'invio
      await _loadReviews();
    }
    return success;
  }

  Future<void> _loadGallery() async {
    _galleryLoading = true;
    notifyListeners();
    try {
      _gallery = await _contentService.fetchGallery();
    } catch (e) {
      debugPrint('Error loading gallery: $e');
    } finally {
      _galleryLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadActivities() async {
    _activitiesLoading = true;
    notifyListeners();
    try {
      _activities = await _contentService.fetchActivities();
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      _activitiesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSliderImages() async {
    _sliderLoading = true;
    _sliderError = '';
    notifyListeners();
    try {
      final remoteSlides = await _contentService.fetchSliderImages();
      if (remoteSlides.isEmpty) {
        _sliderStatus = 'Firestore (Collezione vuota)';
        _sliderImages = _contentService.localSliderFallback;
      } else {
        _sliderStatus = 'Firestore (${remoteSlides.length} immagini)';
        _sliderImages = remoteSlides;
      }
    } catch (e) {
      _sliderStatus = 'Errore Firestore';
      _sliderError = e.toString();
      _sliderImages = _contentService.localSliderFallback;
      debugPrint('❌ Errore _loadSliderImages: $e');
    } finally {
      _sliderLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSliderImage(XFile file) async {
    final success = await _contentService.addSliderImage(file);
    if (success) {
      await _loadSliderImages();
    }
    return success;
  }

  Future<bool> deleteSliderImage(String id) async {
    final success = await _contentService.deleteSliderImage(id);
    if (success) {
      await _loadSliderImages();
    }
    return success;
  }

  Future<bool> addGalleryImage(XFile file, String category) async {
    final success = await _contentService.addGalleryImage(file, category);
    if (success) {
      await _loadGallery();
    }
    return success;
  }

  Future<bool> deleteGalleryImage(String id) async {
    final success = await _contentService.deleteGalleryImage(id);
    if (success) {
      await _loadGallery();
    }
    return success;
  }

  Future<bool> updateGalleryImageDescription(
      String id, String description) async {
    final success =
        await _contentService.updateGalleryImageDescription(id, description);
    if (success) {
      await _loadGallery();
    }
    return success;
  }

  Future<bool> addActivity(String title, String description, String icon,
      {XFile? mediaFile}) async {
    final success = await _contentService.addActivity(title, description, icon,
        mediaFile: mediaFile);
    if (success) {
      await _loadActivities();
    }
    return success;
  }

  Future<bool> deleteActivity(String id) async {
    final success = await _contentService.deleteActivity(id);
    if (success) {
      await _loadActivities();
    }
    return success;
  }

  Future<void> _loadHeroText() async {
    final data = await _contentService.fetchHeroText();
    _heroTitle = data['title']!;
    _heroDescription = data['description']!;
    notifyListeners();
  }

  Future<bool> saveHeroText(String title, String description) async {
    final success = await _contentService.saveHeroText(title, description);
    if (success) {
      _heroTitle = title;
      _heroDescription = description;
      notifyListeners();
    }
    return success;
  }

  void selectDates(DateTime start, DateTime? end) {
    _checkInDate = start;
    _checkOutDate = end;
    notifyListeners();
  }

  bool isDateBooked(DateTime date) {
    return _bookedDates.any((bookedDate) =>
        date.year == bookedDate.year &&
        date.month == bookedDate.month &&
        date.day == bookedDate.day);
  }

  Future<bool> submitBookingRequest({
    required String name,
    required String email,
    required int guests,
  }) async {
    if (_checkInDate == null || _checkOutDate == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final emailSuccess = await _emailService.sendBookingEmail(
        name: name,
        email: email,
        guests: guests,
        checkIn: _checkInDate!,
        checkOut: _checkOutDate!,
      );

      final calendarSuccess = await _calendarService.createBookingEvent(
        name: name,
        email: email,
        guests: guests,
        start: _checkInDate!,
        end: _checkOutDate!,
      );

      final success = emailSuccess && calendarSuccess;

      if (success) {
        _checkInDate = null;
        _checkOutDate = null;
      }
      return success;
    } catch (e) {
      debugPrint("Error submitting booking: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
