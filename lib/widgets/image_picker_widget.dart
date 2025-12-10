// lib/widgets/image_picker_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String?) onImageSelected;
  final String label;
  final bool compact;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    required this.onImageSelected,
    this.label = 'Add Image',
    this.compact = false,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  String? _imageUrl;
  File? _localImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update internal state when parent changes initialImageUrl
    if (widget.initialImageUrl != oldWidget.initialImageUrl) {
      setState(() {
        _imageUrl = widget.initialImageUrl;
        _localImage = null;
        _isUploading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _localImage = File(pickedFile.path);
        _isUploading = true;
      });

      // Upload to Cloudinary
      final uploadedUrl = await _cloudinaryService.uploadImage(_localImage!);

      setState(() {
        _isUploading = false;
        if (uploadedUrl != null) {
          _imageUrl = uploadedUrl;
          widget.onImageSelected(uploadedUrl);
        } else {
          _localImage = null;
          _showError('Failed to upload image. Please try again.');
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _localImage = null;
      });
      _showError('Error selecting image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _localImage = null;
    });
    widget.onImageSelected(null);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    if (_imageUrl != null || _localImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _localImage != null
                ? Image.file(_localImage!, height: 60, width: 60, fit: BoxFit.cover)
                : Image.network(_imageUrl!, height: 60, width: 60, fit: BoxFit.cover),
          ),
          if (_isUploading)
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
              onPressed: _removeImage,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Icon(Icons.add_photo_alternate, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildFullView() {
    if (_imageUrl != null || _localImage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _localImage != null
                    ? Image.file(_localImage!, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(_imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              if (_isUploading)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Uploading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _removeImage,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: _showImageSourceDialog,
      icon: const Icon(Icons.add_photo_alternate),
      label: Text(widget.label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        side: BorderSide(color: AppTheme.borderColor),
      ),
    );
  }
}
