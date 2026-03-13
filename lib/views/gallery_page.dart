import 'package:flutter/material.dart';
import '../services/content_service.dart';

class GalleryPage extends StatefulWidget {
  final List<GalleryImage> images;
  final bool isAdmin;
  final Function(String)? onDelete;

  const GalleryPage({
    super.key,
    required this.images,
    this.isAdmin = false,
    this.onDelete,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  String _selectedGalleryCategory = 'tutti';
  late List<GalleryImage> _currentImages;

  @override
  void initState() {
    super.initState();
    _currentImages = List.from(widget.images);
  }

  void _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questa foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.onDelete != null) {
      widget.onDelete!(id);
      setState(() {
        _currentImages.removeWhere((img) => img.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'key': 'tutti', 'label': 'Tutte'},
      {'key': 'Interni', 'label': '🛏  Interni'},
      {'key': 'Territorio', 'label': '🌿  Territorio'},
    ];

    final filtered = _selectedGalleryCategory == 'tutti'
        ? _currentImages
        : _currentImages
            .where((img) => img.category == _selectedGalleryCategory)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Galleria Completa'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final cols = constraints.maxWidth > 700
                  ? 4
                  : constraints.maxWidth > 400
                      ? 2
                      : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final img = filtered[index];
                  return GestureDetector(
                    onTap: () => _showImageLightbox(context, filtered, index),
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
                                    child:
                                        const Icon(Icons.image_not_supported),
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
                                    Colors.black.withValues(alpha: 0.6),
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
                          if (widget.isAdmin)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _handleDelete(img.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: img.url.startsWith('http')
                      ? Image.network(img.url, fit: BoxFit.contain)
                      : Image.asset(img.url, fit: BoxFit.contain),
                ),
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
                if (currentIndex > 0)
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 40),
                      onPressed: () => setDialogState(() => currentIndex--),
                    ),
                  ),
                if (currentIndex < images.length - 1)
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 40),
                      onPressed: () => setDialogState(() => currentIndex++),
                    ),
                  ),
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
}
