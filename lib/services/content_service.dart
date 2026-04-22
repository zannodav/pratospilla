import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb

class GalleryImage {
  final String id;
  final String url;
  final String category;
  final DateTime date;
  final String? description;
  final bool isVisible;
  final int orderIndex;

  GalleryImage({
    required this.id,
    required this.url,
    required this.category,
    required this.date,
    this.description,
    this.isVisible = true,
    this.orderIndex = 0,
  });

  factory GalleryImage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryImage(
      id: doc.id,
      url: data['url'] as String? ?? '',
      category: data['category'] as String? ?? 'tutti',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String?,
      isVisible: data['isVisible'] as bool? ?? true,
      orderIndex: data['orderIndex'] as int? ?? 0,
    );
  }
}

class Activity {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime date;
  final String? mediaUrl;
  final String? mediaType;
  final bool isVisible;
  final int orderIndex;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.date,
    this.mediaUrl,
    this.mediaType,
    this.isVisible = true,
    this.orderIndex = 0,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'hiking',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      isVisible: data['isVisible'] as bool? ?? true,
      orderIndex: data['orderIndex'] as int? ?? 0,
    );
  }
}

class SliderImage {
  final String id;
  final String url;
  final DateTime date;
  final bool isVisible;

  SliderImage({
    required this.id,
    required this.url,
    required this.date,
    this.isVisible = true,
  });

  factory SliderImage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SliderImage(
      id: doc.id,
      url: data['url'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVisible: data['isVisible'] as bool? ?? true,
    );
  }
}

class ContentService {
  // Accedi alle istanze tramite getter per evitare errori se chiamate troppo presto
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  final bool _firestoreAvailable = true;

  // Mock data as fallback
  final List<GalleryImage> _localGallery = [
    GalleryImage(
        id: '1',
        url:
            'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800',
        category: 'Interni',
        date: DateTime.now()),
    GalleryImage(
        id: '2',
        url: 'https://images.unsplash.com/photo-1542718610-a1d656d1884c?w=800',
        category: 'Interni',
        date: DateTime.now()),
    GalleryImage(
        id: '3',
        url:
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
        category: 'Territorio',
        date: DateTime.now()),
    GalleryImage(
        id: '4',
        url:
            'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800',
        category: 'Territorio',
        date: DateTime.now()),
  ];

  final List<Activity> _localActivities = [
    Activity(
        id: '1',
        title: 'Trekking',
        description: 'Sentieri boschivi',
        icon: 'hiking',
        date: DateTime.now()),
    Activity(
        id: '2',
        title: 'E-Bike',
        description: 'Percorsi ciclabili',
        icon: 'pedal_bike',
        date: DateTime.now()),
  ];

  final List<SliderImage> localSliderFallback = [
    SliderImage(id: 's1', url: 'assets/slide1.jpg', date: DateTime.now()),
    SliderImage(id: 's2', url: 'assets/slide2.jpg', date: DateTime.now()),
    SliderImage(id: 's3', url: 'assets/slide3.jpg', date: DateTime.now()),
    SliderImage(id: 's4', url: 'assets/slide4.jpg', date: DateTime.now()),
    SliderImage(id: 's5', url: 'assets/slide5.jpg', date: DateTime.now()),
  ];

  /// --- SLIDER ---

  Future<List<SliderImage>> fetchSliderImages({bool isAdmin = true}) async {
    if (!_firestoreAvailable) return localSliderFallback;
    try {
      final snapshot = await _firestore.collection('slider').get();
      final items =
          snapshot.docs.map((doc) => SliderImage.fromFirestore(doc)).toList();

      // Sort by date
      items.sort((a, b) => b.date.compareTo(a.date));

      if (!isAdmin) {
        return items.where((i) => i.isVisible).toList();
      }
      return items;
    } catch (e) {
      debugPrint('Firestore slider fetch failed: $e');
      return localSliderFallback;
    }
  }

  Future<bool> addSliderImage(XFile file) async {
    try {
      String fileName =
          'slider/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      Reference ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(file.path));
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      await _firestore.collection('slider').add({
        'url': url,
        'date': Timestamp.now(),
        'isVisible': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error uploading slider image: $e');
      return false;
    }
  }

  Future<bool> deleteSliderImage(String id) async {
    try {
      await _firestore.collection('slider').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting slider image: $e');
      return false;
    }
  }

  Future<bool> updateSliderImageVisibility(String id, bool isVisible) async {
    try {
      await _firestore.collection('slider').doc(id).update({
        'isVisible': isVisible,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating slider image visibility: $e');
      return false;
    }
  }

  /// --- GALLERY ---

  Future<List<GalleryImage>> fetchGallery({bool isAdmin = true}) async {
    if (!_firestoreAvailable) return _localGallery;
    try {
      final snapshot = await _firestore.collection('gallery').get();
      final items =
          snapshot.docs.map((doc) => GalleryImage.fromFirestore(doc)).toList();

      // Sort by orderIndex then date
      items.sort((a, b) {
        int cmp = a.orderIndex.compareTo(b.orderIndex);
        if (cmp == 0) return b.date.compareTo(a.date);
        return cmp;
      });

      if (!isAdmin) {
        return items.where((i) => i.isVisible).toList();
      }
      return items;
    } catch (e) {
      debugPrint('Firestore gallery fetch failed: $e');
      return _localGallery;
    }
  }

  Future<bool> addGalleryImage(XFile file, String category) async {
    try {
      String fileName =
          'gallery/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      Reference ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(file.path));
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      await _firestore.collection('gallery').add({
        'url': url,
        'category': category,
        'date': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return false;
    }
  }

  Future<bool> deleteGalleryImage(String id) async {
    try {
      await _firestore.collection('gallery').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting gallery image: $e');
      return false;
    }
  }

  Future<bool> updateGalleryImageDescription(
      String id, String description) async {
    try {
      await _firestore.collection('gallery').doc(id).update({
        'description': description.trim().isEmpty ? null : description.trim(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating gallery image description: $e');
      return false;
    }
  }

  Future<bool> updateGalleryImageVisibility(String id, bool isVisible) async {
    try {
      await _firestore.collection('gallery').doc(id).update({
        'isVisible': isVisible,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating gallery image visibility: $e');
      return false;
    }
  }

  /// --- ACTIVITIES ---

  Future<List<Activity>> fetchActivities({bool isAdmin = true}) async {
    if (!_firestoreAvailable) return _localActivities;
    try {
      // Fetch all and sort/filter in-memory to avoid index issues for guests
      final snapshot = await _firestore.collection('activities').get();
      final items =
          snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();

      // Sort by orderIndex then date
      items.sort((a, b) {
        int cmp = a.orderIndex.compareTo(b.orderIndex);
        if (cmp == 0) return b.date.compareTo(a.date);
        return cmp;
      });

      if (!isAdmin) {
        return items.where((i) => i.isVisible).toList();
      }
      return items;
    } catch (e) {
      debugPrint('Firestore activities fetch failed: $e');
      return _localActivities;
    }
  }

  Future<bool> addActivity(String title, String description, String icon,
      {XFile? mediaFile}) async {
    try {
      String? mediaUrl;
      String? mediaType;

      if (mediaFile != null) {
        String fileName =
            'activities/${DateTime.now().millisecondsSinceEpoch}_${mediaFile.name}';
        Reference ref = _storage.ref().child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = ref.putData(await mediaFile.readAsBytes());
        } else {
          uploadTask = ref.putFile(File(mediaFile.path));
        }

        final snapshot = await uploadTask;
        mediaUrl = await snapshot.ref.getDownloadURL();

        // Basic check for PDF extension
        if (mediaFile.name.toLowerCase().endsWith('.pdf')) {
          mediaType = 'pdf';
        } else {
          mediaType = 'image';
        }
      }

      await _firestore.collection('activities').add({
        'title': title,
        'description': description,
        'icon': icon,
        'date': Timestamp.now(),
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaType != null) 'mediaType': mediaType,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding activity: $e');
      return false;
    }
  }

  Future<bool> deleteActivity(String id) async {
    try {
      await _firestore.collection('activities').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return false;
    }
  }

  Future<bool> updateActivityVisibility(String id, bool isVisible) async {
    try {
      await _firestore
          .collection('activities')
          .doc(id)
          .update({'isVisible': isVisible});
      return true;
    } catch (e) {
      debugPrint('Error updating activity visibility: $e');
      return false;
    }
  }

  Future<bool> updateGalleryImageOrder(String id, int orderIndex) async {
    try {
      await _firestore
          .collection('gallery')
          .doc(id)
          .update({'orderIndex': orderIndex});
      return true;
    } catch (e) {
      debugPrint('Error updating gallery image order: $e');
      return false;
    }
  }

  Future<bool> updateActivityOrder(String id, int orderIndex) async {
    try {
      await _firestore
          .collection('activities')
          .doc(id)
          .update({'orderIndex': orderIndex});
      return true;
    } catch (e) {
      debugPrint('Error updating activity order: $e');
      return false;
    }
  }

  /// --- HERO TEXT ---

  static const String _heroDefaultTitle =
      'Fuga Romantica tra i Monti di Prato Spilla';
  static const String _heroDefaultDescription =
      "Vivi un'esperienza indimenticabile al confine tra Emilia-Romagna e Toscana. "
      "Questi accoglienti alloggi sono il rifugio perfetto per staccare dal caos cittadino. "
      "Immersa nella natura incontaminata, potrai svegliarti col canto degli uccellini, "
      "fare trekking nei boschi circostanti, o semplicemente rilassarti e dedicarti ai tuoi hobby.";

  Future<Map<String, String>> fetchHeroText() async {
    try {
      final doc = await _firestore.collection('settings').doc('hero').get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'title': data['title'] as String? ?? _heroDefaultTitle,
          'description':
              data['description'] as String? ?? _heroDefaultDescription,
        };
      }
    } catch (e) {
      debugPrint('Error fetching hero text: $e');
    }
    return {
      'title': _heroDefaultTitle,
      'description': _heroDefaultDescription,
    };
  }

  Future<bool> saveHeroText(String title, String description) async {
    try {
      await _firestore.collection('settings').doc('hero').set({
        'title': title,
        'description': description,
      });
      return true;
    } catch (e) {
      debugPrint('Error saving hero text: $e');
      return false;
    }
  }
}
