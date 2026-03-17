import 'package:flutter/material.dart';
import '../services/content_service.dart';

class GalleryPage extends StatefulWidget {
  final List<GalleryImage> images;
  final bool isAdmin;
  final Function(String)? onDelete;
  final Future<bool> Function(String id, String description)?
      onUpdateDescription;

  const GalleryPage({
    super.key,
    required this.images,
    this.isAdmin = false,
    this.onDelete,
    this.onUpdateDescription,
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

  @override
  void didUpdateWidget(covariant GalleryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      setState(() {
        _currentImages = List.from(widget.images);
      });
    }
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

  /// Opens an edit dialog for the description; on save calls the callback and
  /// updates the local list so the lightbox refreshes immediately.
  Future<void> _handleEditDescription(
      BuildContext dialogCtx,
      StateSetter setDialogState,
      GalleryImage img,
      List<GalleryImage> filteredList,
      int index) async {
    final controller =
        TextEditingController(text: img.description ?? '');
    final saved = await showDialog<String>(
      context: dialogCtx,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifica descrizione'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Aggiungi una descrizione alla foto…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (saved == null) return;

    final success = await widget.onUpdateDescription?.call(img.id, saved);
    if (success == true) {
      // Update local list with new description so UI refreshes right away.
      final globalIdx = _currentImages.indexWhere((i) => i.id == img.id);
      if (globalIdx != -1) {
        final updated = GalleryImage(
          id: img.id,
          url: img.url,
          category: img.category,
          date: img.date,
          description: saved.trim().isEmpty ? null : saved.trim(),
        );
        setState(() {
          _currentImages[globalIdx] = updated;
        });
        // Also update the filtered/displayed list for the lightbox
        filteredList[index] = updated;
        setDialogState(() {});
      }
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
                          // Bottom gradient with category (and description if present)
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
                                    Colors.black.withValues(alpha: 0.65),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (img.description != null &&
                                      img.description!.isNotEmpty)
                                    Text(
                                      img.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          height: 1.3),
                                    ),
                                  Text(
                                    img.category,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Admin delete button
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
    // Work on a mutable copy so the lightbox can update descriptions locally.
    final mutableImages = List<GalleryImage>.from(images);
    int currentIndex = initialIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final img = mutableImages[currentIndex];
          final hasDescription =
              img.description != null && img.description!.isNotEmpty;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: img.url.startsWith('http')
                      ? Image.network(img.url, fit: BoxFit.contain)
                      : Image.asset(img.url, fit: BoxFit.contain),
                ),

                // Bottom info bar (description + counter + optional edit icon)
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasDescription)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            img.description!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${img.category}  •  ${currentIndex + 1}/${mutableImages.length}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ),
                          // Admin edit button
                          if (widget.isAdmin &&
                              widget.onUpdateDescription != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _handleEditDescription(
                                  ctx,
                                  setDialogState,
                                  img,
                                  mutableImages,
                                  currentIndex),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Navigation arrows
                if (currentIndex > 0)
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 40),
                      onPressed: () =>
                          setDialogState(() => currentIndex--),
                    ),
                  ),
                if (currentIndex < mutableImages.length - 1)
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white, size: 40),
                      onPressed: () =>
                          setDialogState(() => currentIndex++),
                    ),
                  ),

                // Close button
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
