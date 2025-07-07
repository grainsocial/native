import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grain/widgets/app_button.dart';
import 'package:grain/widgets/plain_text_field.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileSheet extends StatefulWidget {
  final String? initialDisplayName;
  final String? initialDescription;
  final String? initialAvatarUrl;
  final Future<void> Function(String displayName, String description, XFile? avatar)? onSave;
  final VoidCallback? onCancel;

  const EditProfileSheet({
    super.key,
    this.initialDisplayName,
    this.initialDescription,
    this.initialAvatarUrl,
    this.onSave,
    this.onCancel,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;
  XFile? _selectedAvatar;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.initialDisplayName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _selectedAvatar = picked;
      });
    }
  }

  void _onSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    if (widget.onSave != null) {
      await widget.onSave!(
        _displayNameController.text.trim(),
        _descriptionController.text.trim(),
        _selectedAvatar,
      );
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarRadius = 44.0;
    final double maxHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: theme.colorScheme.surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppButton(
                          label: 'Cancel',
                          size: AppButtonSize.small,
                          variant: AppButtonVariant.text,
                          disabled: _saving,
                          onPressed: widget.onCancel ?? () => Navigator.of(context).maybePop(),
                        ),
                        Text(
                          'Edit profile',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        AppButton(
                          label: 'Save',
                          variant: AppButtonVariant.primary,
                          loading: _saving,
                          onPressed: _saving ? null : _onSave,
                          height: 36,
                          fontSize: 15,
                          borderRadius: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            backgroundImage: _selectedAvatar != null
                                ? FileImage(File(_selectedAvatar!.path))
                                : (widget.initialAvatarUrl != null &&
                                      widget.initialAvatarUrl!.isNotEmpty)
                                ? NetworkImage(widget.initialAvatarUrl!)
                                : null as ImageProvider<Object>?,
                            child:
                                (_selectedAvatar == null &&
                                    (widget.initialAvatarUrl == null ||
                                        widget.initialAvatarUrl!.isEmpty))
                                ? Icon(
                                    Icons.account_circle,
                                    size: avatarRadius * 2,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(FontAwesomeIcons.camera, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            PlainTextField(
                              label: 'Display Name',
                              controller: _displayNameController,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 12),
                            PlainTextField(
                              label: 'Description',
                              controller: _descriptionController,
                              maxLines: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
