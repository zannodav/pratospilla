import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../view_models/home_view_model.dart';
import '../services/content_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'gallery_page.dart';
import 'activity_details_page.dart';
import 'reviews_page.dart';
import 'activity_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeViewModel _viewModel = HomeViewModel();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _guestsController = TextEditingController();

  String _selectedGalleryCategory = 'tutti';

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'hiking':
        return Icons.hiking;
      case 'pedal_bike':
        return Icons.pedal_bike;
      case 'festival':
        return Icons.festival;
      case 'water':
        return Icons.water;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_activity':
        return Icons.local_activity;
      default:
        return Icons.star;
    }
  }

  final List<String> imgList = [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',
    'assets/slide4.jpg',
    'assets/slide5.jpg',
  ];

  DateTime _focusedDay = DateTime.now();

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _guestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.jpg',
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Appennino che Emozione!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Tooltip(
            message: 'Visita visitmonchiodellecorti.it',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final url = Uri.parse('https://visitmonchiodellecorti.it');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Image.asset(
                  'assets/logo_visitmonchio.png',
                  height: 36,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.facebook),
            tooltip: 'Pagina Facebook',
            onPressed: () async {
              final url = Uri.parse(
                  'https://facebook.com'); // Sostituisci con il link corretto
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera),
            tooltip: 'Pagina Instagram',
            onPressed: () async {
              final url = Uri.parse(
                  'https://instagram.com'); // Sostituisci con il link corretto
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isSignedIn) {
                // Mostra icona verde + opzione logout
                return PopupMenuButton<String>(
                  tooltip: 'Account Google',
                  icon: const Icon(Icons.account_circle, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await _viewModel.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Disconnesso da Google Calendar')),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      enabled: false,
                      child: Row(children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text('Calendario connesso',
                            style: TextStyle(fontSize: 13)),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Disconnetti'),
                      ]),
                    ),
                  ],
                );
              }

              // Non loggato: mostra pulsante login
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: _viewModel.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : TextButton.icon(
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text('Accedi',
                            style: TextStyle(color: Colors.white)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final success = await _viewModel.signInWithGoogle();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? '✅ Connesso! Calendario aggiornato con i dati reali.'
                                    : '❌ Login fallito. Riprova.'),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Photo Gallery Header
            _buildPhotoGallery(),

            // Layout Container (Responsive centering)
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Title and Description
                    _buildDescriptionSection(),
                    const Divider(height: 60),

                    // 3. Amenities
                    _buildAmenities(),
                    const Divider(height: 60),

                    // 4. Galleria fotografica
                    _buildGallerySection(),
                    const Divider(height: 60),

                    // 5. Annunci Airbnb
                    _buildAirbnbSection(),
                    const Divider(height: 60),

                    // ViewModel listener per il Form e il Calendario
                    ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, child) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              // Desktop View
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildCalendar(),
                                  ),
                                  const SizedBox(width: 40),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _buildBookingForm(),
                                        const SizedBox(height: 24),
                                        _buildLocationWidget(),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                            // Mobile View
                            return Column(
                              children: [
                                _buildCalendar(),
                                const SizedBox(height: 40),
                                _buildBookingForm(),
                                const SizedBox(height: 24),
                                _buildLocationWidget(),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const Divider(height: 60),
                    // 4. Attività & Territorio
                    _buildActivitiesSection(),

                    const Divider(height: 60),
                    // 5. Recensioni
                    _buildReviewsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 400.0,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 0.85,
      ),
      items: imgList
          .map((item) => Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                  image: DecorationImage(
                    image: AssetImage(item),
                    fit: BoxFit.cover,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildGallerySection() {
    final categories = [
      {'key': 'tutti', 'label': 'Tutte'},
      {'key': 'Interni', 'label': '🛏  Interni'},
      {'key': 'Territorio', 'label': '🌿  Territorio'},
    ];

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final galleryPosts = _viewModel.gallery;
        final filtered = _selectedGalleryCategory == 'tutti'
            ? galleryPosts
            : galleryPosts
                .where((img) => img.category == _selectedGalleryCategory)
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Galleria Fotografica',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Esplora gli spazi della baita e i paesaggi del territorio',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
                if (_viewModel.isSignedIn)
                  ElevatedButton.icon(
                    onPressed: () => _showAddImageDialog(context),
                    icon: const Icon(Icons.add_a_photo, size: 20),
                    label: const Text('Carica'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedGalleryCategory == cat['key'];
                return ChoiceChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedGalleryCategory = cat['key']!;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_viewModel.galleryLoading)
              const Center(child: CircularProgressIndicator())
            else
              LayoutBuilder(builder: (context, constraints) {
                final cols = constraints.maxWidth > 700
                    ? 3
                    : constraints.maxWidth > 400
                        ? 2
                        : 1;
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: filtered.length > 3 ? 3 : filtered.length,
                      itemBuilder: (context, index) {
                        final img = filtered[index];
                        return GestureDetector(
                          onTap: () =>
                              _showImageLightbox(context, filtered, index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                img.url.startsWith('https')
                                    ? Image.network(
                                        img.url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : Image.asset(
                                        img.url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                              Icons.image_not_supported),
                                        ),
                                      ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.6),
                                          Colors.transparent
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      img.category,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                if (_viewModel.isSignedIn) ...[
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _confirmDeleteImage(context, img.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (filtered.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GalleryPage(images: filtered),
                              ),
                            );
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Vedi tutte le foto'),
                        ),
                      ),
                  ],
                );
              }),
          ],
        );
      },
    );
  }

  void _confirmDeleteImage(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questa foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              final success = await _viewModel.deleteGalleryImage(id);
              if (success) {
                if (context.mounted) Navigator.pop(context);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Errore durante l\'eliminazione')),
                  );
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddImageDialog(BuildContext context) {
    String category = 'Interni';
    XFile? pickedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aggiungi Foto alla Galleria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pickedFile != null)
                const Icon(Icons.check_circle, color: Colors.green, size: 40)
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final file =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (file != null) {
                      setDialogState(() => pickedFile = file);
                    }
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Seleziona Immagine'),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: ['Interni', 'Territorio']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla')),
            ElevatedButton(
              onPressed: pickedFile == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final ok = await _viewModel.addGalleryImage(
                          pickedFile!, category);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Foto caricata!'
                                : 'Errore nel caricamento')));
                      }
                    },
              child: const Text('Carica'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageLightbox(
      BuildContext context, List<GalleryImage> images, int initialIndex) {
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final img = images[currentIndex];
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Immagine principale
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: img.url.startsWith('http')
                      ? Image.network(img.url, fit: BoxFit.contain)
                      : Image.asset(img.url, fit: BoxFit.contain),
                ),
                // Label in basso
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${img.category}  •  ${currentIndex + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
                // Freccia sinistra
                if (currentIndex > 0)
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 40),
                      onPressed: () => setDialogState(() => currentIndex--),
                    ),
                  ),
                // Freccia destra
                if (currentIndex < images.length - 1)
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 40),
                      onPressed: () => setDialogState(() => currentIndex++),
                    ),
                  ),
                // Chiudi
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Flexible(
              child: Text(
                'Fuga Romantica tra i Monti di Prato Spilla',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Baita Esclusiva',
                style:
                    TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Vivi un\'esperienza indimenticabile al confine tra Emilia-Romagna e Toscana. '
          'Questa accogliente baita è il rifugio perfetto per staccare dal caos cittadino. '
          'Immersa nella natura incontaminata, potrai svegliarti col canto degli uccellini, '
          'fare trekking nei boschi circostanti, o semplicemente rilassarti e dedicarti ai tuoi hobby.',
          style: TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('I Nostri Servizi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 40,
          runSpacing: 20,
          children: [
            _buildAmenity(Icons.wifi, 'Wi-Fi Veloce'),
            _buildAmenity(Icons.bed_outlined, '6+5 Posti Letto'),
            _buildAmenity(Icons.deck, 'Ampia Terrazza'),
            _buildAmenity(Icons.kitchen, 'Cucina Attrezzata'),
            _buildAmenity(Icons.nature_people, 'Percorsi Trekking'),
            _buildAmenity(Icons.local_parking, 'Parcheggio Gratuito'),
            _buildAmenity(Icons.house_rounded, 'Intero Appartamento'),
            _buildAmenity(Icons.bathroom_outlined, 'Bagno Privato'),
            _buildAmenity(Icons.ac_unit, 'Riscaldamento Autonomo'),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenity(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Seleziona le Date',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_viewModel.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                rangeStartDay: _viewModel.checkInDate,
                rangeEndDay: _viewModel.checkOutDate,
                onDaySelected: (selectedDay, focusedDay) {
                  // Previene selezione giorni passati
                  if (selectedDay.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)))) {
                    return;
                  }

                  // Se premi un giorno disattivato, non succede niente
                  if (_viewModel.isDateBooked(selectedDay)) return;

                  setState(() {
                    _focusedDay = focusedDay;
                    // Logica selezione range (Start e End)
                    if (_viewModel.checkInDate == null ||
                        (_viewModel.checkInDate != null &&
                            _viewModel.checkOutDate != null)) {
                      _viewModel.selectDates(selectedDay, null);
                    } else if (selectedDay.isAfter(_viewModel.checkInDate!)) {
                      // Verifica se ci sono giorni prenotati nel mezzo
                      bool hasBookedDaysInBetween = false;
                      for (DateTime d = _viewModel.checkInDate!;
                          d.isBefore(selectedDay);
                          d = d.add(const Duration(days: 1))) {
                        if (_viewModel.isDateBooked(d)) {
                          hasBookedDaysInBetween = true;
                          break;
                        }
                      }

                      if (!hasBookedDaysInBetween) {
                        _viewModel.selectDates(
                            _viewModel.checkInDate!, selectedDay);
                      } else {
                        // Se c'è un giorno occupato, resetta start al giorno cliccato
                        _viewModel.selectDates(selectedDay, null);
                      }
                    } else {
                      _viewModel.selectDates(selectedDay, null);
                    }
                  });
                },
                enabledDayPredicate: (day) {
                  // Disabilita date prenotate nel calendario così non si possono cliccare
                  return true; //!_viewModel.isDateBooked(day);
                },
                calendarStyle: CalendarStyle(
                  disabledTextStyle: const TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough),
                  disabledDecoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  rangeStartDecoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  withinRangeDecoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.teal.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDateIndication(
                    'Check-In',
                    _viewModel.checkInDate != null
                        ? DateFormat('dd MMM yyyy')
                            .format(_viewModel.checkInDate!)
                        : '--/--/----'),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
                _buildDateIndication(
                    'Check-Out',
                    _viewModel.checkOutDate != null
                        ? DateFormat('dd MMM yyyy')
                            .format(_viewModel.checkOutDate!)
                        : '--/--/----'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateIndication(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildBookingForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Richiedi Prenotazione',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome e Cognome',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.contains('@') ? null : 'Email non valida',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guestsController,
                decoration: InputDecoration(
                  labelText: 'Numero di Ospiti',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _viewModel.isLoading
                    ? null
                    : () async {
                        if (_viewModel.checkInDate == null ||
                            _viewModel.checkOutDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Seleziona date di check-in e check-out')),
                          );
                          return;
                        }

                        if (_formKey.currentState!.validate()) {
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await _viewModel.submitBookingRequest(
                            name: _nameController.text,
                            email: _emailController.text,
                            guests: int.tryParse(_guestsController.text) ?? 1,
                          );

                          if (success) {
                            _nameController.clear();
                            _emailController.clear();
                            _guestsController.clear();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Richiesta inviata con successo! Un\'email è stata mandata a [Tua Email].'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Errore nell\'invio della richiesta.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _viewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Invia Richiesta',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final activities = _viewModel.activities;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attività & Eventi',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cosa fare e cosa succede intorno alla baita',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                  ],
                ),
                if (_viewModel.isSignedIn)
                  ElevatedButton.icon(
                    onPressed: () => _showAddActivityDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (_viewModel.activitiesLoading)
              const Center(child: CircularProgressIndicator())
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                  return Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 3.5,
                        ),
                        itemCount:
                            activities.length > 4 ? 4 : activities.length,
                        itemBuilder: (context, index) {
                          final item = activities[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ActivityDetailsPage(activity: item),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(_getActivityIcon(item.icon),
                                        color: Colors.teal, size: 32),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.description,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_viewModel.isSignedIn)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.redAccent, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _confirmDeleteActivity(
                                            context, item.id),
                                      )
                                    else
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 16, color: Colors.teal),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (activities.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Naviga a una pagina "Tutte le attività"
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AllActivitiesPage(activities: activities),
                                ),
                              );
                              // We could navigate to an AllActivities page here, but for now just showing button
                              // The user request specified max 3, clickable images.
                              // We will just do nothing or we can skip this button for activities.
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal,
                              side: const BorderSide(color: Colors.teal),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.list),
                            label: const Text('Vedi tutte le attività'),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _confirmDeleteActivity(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Attività'),
        content: const Text('Sei sicuro di voler eliminare questa attività?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _viewModel.deleteActivity(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Attività eliminata con successo!'
                        : 'Errore nell\'eliminazione dell\'attività.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String icon = 'hiking';
    XFile? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aggiungi Attività / Evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titolo'),
                ),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  minLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Descrizione (supporta testi lunghi)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: icon,
                  decoration: const InputDecoration(labelText: 'Icona'),
                  items: [
                    'hiking',
                    'pedal_bike',
                    'festival',
                    'water',
                    'restaurant'
                  ]
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => icon = v!),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(selectedFile == null
                      ? 'Allega Locandina (JPG/PNG/PDF)'
                      : 'File: ${selectedFile!.name}'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
                      withData: true, // Need data for Web
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      setDialogState(() {
                        if (file.bytes != null) {
                          selectedFile =
                              XFile.fromData(file.bytes!, name: file.name);
                        } else if (file.path != null) {
                          selectedFile = XFile(file.path!, name: file.name);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Annulla')),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty ||
                          descCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Compila tutti i campi')));
                        return;
                      }

                      setDialogState(() => isUploading = true);

                      final ok = await _viewModel.addActivity(
                          titleCtrl.text.trim(), descCtrl.text.trim(), icon,
                          mediaFile: selectedFile);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Attività aggiunta!'
                                : 'Errore durante il salvataggio')));
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final reviews = _viewModel.reviews;
        final avgRating = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length;

        // Take only the first 4 reviews
        final displayedReviews = reviews.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recensioni degli Ospiti',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                if (reviews.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            color: Colors.amber.shade700, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${avgRating.toStringAsFixed(1)} · ${reviews.length} recensioni',
                          style: TextStyle(
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Griglia recensioni
            if (_viewModel.reviewsLoading)
              const Center(child: CircularProgressIndicator())
            else if (reviews.isEmpty)
              const Text('Nessuna recensione ancora. Sii il primo!',
                  style: TextStyle(color: Colors.grey))
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 600 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: displayedReviews.length,
                    itemBuilder: (context, index) {
                      final review = displayedReviews[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _viewModel.isSignedIn && !review.approved
                                ? Colors.orange.shade300
                                : Colors.grey.shade200,
                            width: _viewModel.isSignedIn && !review.approved
                                ? 2
                                : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.teal.shade100,
                                      child: Text(
                                        review.name.isNotEmpty
                                            ? review.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                            color: Colors.teal.shade800,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              review.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            if (_viewModel.isSignedIn &&
                                                !review.approved) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'DA APPROVARE',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.orange.shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          DateFormat('MMMM yyyy', 'it')
                                              .format(review.date),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: List.generate(
                                    review.rating,
                                    (_) => Icon(Icons.star,
                                        color: Colors.amber.shade600, size: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                review.text,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.5),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_viewModel.isSignedIn) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!review.approved)
                                    TextButton.icon(
                                      onPressed: () async {
                                        final ok = await _viewModel
                                            .approveReview(review.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(ok
                                                      ? 'Recensione approvata!'
                                                      : 'Errore approvazione')));
                                        }
                                      },
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Approva'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.green),
                                    ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final ok = await _viewModel
                                          .deleteReview(review.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(ok
                                                    ? 'Recensione eliminata!'
                                                    : 'Errore eliminazione')));
                                      }
                                    },
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: const Text('Elimina'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              if (reviews.length > 4) ...[
                const SizedBox(height: 16),
                Center(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewsPage(reviews: reviews),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Vedi tutte le recensioni'),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            // Form scrittura recensione
            WriteReviewForm(viewModel: _viewModel),
          ],
        );
      },
    );
  }

  Widget _buildLocationWidget() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal),
                SizedBox(width: 8),
                Text('Dove Siamo',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bastia di Rigoso - Pratospilla (PR)\nAppennino Tosco-Emiliano',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=44.374572%2C10.133257&destination=Via+per+pratospilla%2C2+Bastia+Rigoso+PR&travelmode=driving');
                //https://www.google.com/maps/@?api=1&map_action=pano&query=44.374572%2C10.133257
                if (!await launchUrl(url)) {
                  debugPrint('Impossibile aprire la mappa.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.map),
              label: const Text('Apri Mappa / Calcola Percorso'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sezione Airbnb
// ---------------------------------------------------------------------------

Widget _buildAirbnbSection() {
  const airbnbColor = Color(0xFFFF5A5F);

  final listings = [
    {
      'url': 'https://www.airbnb.it/rooms/1080466501353690034',
      'title': 'Casa Dani',
      'type': 'Alloggio in affitto',
      'location': 'Monchio delle Corti, Emilia-Romagna',
      'rating': '5,0',
      'rooms': '2 camere da letto',
      'beds': '5 letti',
      'baths': '1 bagno',
    },
    {
      'url': 'https://www.airbnb.it/rooms/15417465',
      'title': 'Casa Giuli',
      'type': 'Appartamento',
      'location': 'Monchio delle Corti, Emilia-Romagna',
      'rating': '4,73',
      'rooms': '2 camere da letto',
      'beds': '5 letti',
      'baths': '1 bagno',
    },
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prenota su Airbnb',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Disponibili su Airbnb con recensioni verificate dagli ospiti',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cards =
            listings.map((l) => _buildAirbnbCard(l, airbnbColor)).toList();
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        }
        return Column(
          children: [
            cards[0],
            const SizedBox(height: 16),
            cards[1],
          ],
        );
      }),
    ],
  );
}

Widget _buildAirbnbCard(Map<String, String> listing, Color airbnbColor) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final url = Uri.parse(listing['url']!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: airbnbColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: airbnbColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    listing['type']!,
                    style: TextStyle(
                      color: airbnbColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    listing['title']!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'airbnb',
                  style: TextStyle(
                    color: airbnbColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  listing['location']!,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  listing['rating']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bed_outlined,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 5),
                    Text(listing['rooms']!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.king_bed_outlined,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 5),
                    Text(listing['beds']!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bathroom_outlined,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 5),
                    Text(listing['baths']!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final url = Uri.parse(listing['url']!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: airbnbColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text(
                  'Vedi su Airbnb',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class WriteReviewForm extends StatefulWidget {
  final HomeViewModel viewModel;

  const WriteReviewForm({super.key, required this.viewModel});

  @override
  State<WriteReviewForm> createState() => _WriteReviewFormState();
}

class _WriteReviewFormState extends State<WriteReviewForm> {
  final _reviewNameController = TextEditingController();
  final _reviewTextController = TextEditingController();
  final _reviewFormKey = GlobalKey<FormState>();
  bool _reviewSubmitted = false;
  bool _reviewSubmitting = false;

  @override
  void dispose() {
    _reviewNameController.dispose();
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      padding: const EdgeInsets.all(24),
      child: _reviewSubmitted
          ? const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.teal, size: 48),
                SizedBox(height: 16),
                Text(
                  'Grazie per la tua recensione!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'La tua recensione è stata inviata e sarà pubblicata dopo approvazione.',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Form(
              key: _reviewFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lascia la tua recensione',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hai soggiornato da noi? Raccontaci la tua esperienza!',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // Selezione stelle
                  Row(
                    children: [
                      const Text('Valutazione:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      ...List.generate(5, (i) {
                        final rating = i + 1;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            widget.viewModel.setDraftReviewRating(rating);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < widget.viewModel.draftReviewRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber.shade600,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reviewNameController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Inserisci il tuo nome' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reviewTextController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'La tua recensione',
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.rate_review),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    validator: (v) => v!.trim().length < 10
                        ? 'Scrivi almeno 10 caratteri'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _reviewSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: Text(
                          _reviewSubmitting ? 'Invio...' : 'Invia Recensione'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _reviewSubmitting
                          ? null
                          : () async {
                              if (!_reviewFormKey.currentState!.validate()) {
                                return;
                              }
                              setState(() {
                                _reviewSubmitting = true;
                              });
                              final ok = await widget.viewModel.submitReview(
                                name: _reviewNameController.text.trim(),
                                rating: widget.viewModel.draftReviewRating,
                                text: _reviewTextController.text.trim(),
                              );
                              if (ok) {
                                // Se è andata bene, resetta il voto a 5 per la prossima volta
                                widget.viewModel.setDraftReviewRating(5);
                              }
                              if (mounted) {
                                setState(() {
                                  _reviewSubmitting = false;
                                  _reviewSubmitted = ok;
                                });
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
