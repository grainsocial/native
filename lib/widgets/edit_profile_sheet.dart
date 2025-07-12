import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grain/app_icons.dart';
import 'package:grain/widgets/plain_text_field.dart';
import 'package:image_picker/image_picker.dart';

Future<void> showEditProfileSheet(
  BuildContext context, {
  required String? initialDisplayName,
  required String? initialDescription,
  required String? initialAvatarUrl,
  required Future<void> Function(String, String, dynamic) onSave,
  required VoidCallback onCancel,
}) async {
  final theme = Theme.of(context);
  await showCupertinoSheet(
    context: context,
    useNestedNavigation: false,
    pageBuilder: (context) => Material(
      type: MaterialType.transparency,
      child: EditProfileSheet(
        initialDisplayName: initialDisplayName,
        initialDescription: initialDescription,
        initialAvatarUrl: initialAvatarUrl,
        onSave: onSave,
        onCancel: onCancel,
      ),
    ),
  );
  // Restore status bar style or any other cleanup
  SystemChrome.setSystemUIOverlayStyle(
    theme.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
  );
}

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
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.initialDisplayName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _displayNameController.addListener(_onInputChanged);
    _descriptionController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    final displayName = _displayNameController.text.trim();
    final initialDisplayName = widget.initialDisplayName ?? '';
    final displayNameChanged = displayName != initialDisplayName;
    final descriptionChanged =
        _descriptionController.text.trim() != (widget.initialDescription ?? '');
    final avatarChanged = _selectedAvatar != null;
    // Only allow Save if displayName is not empty and at least one field changed
    final changed =
        (displayNameChanged || descriptionChanged || avatarChanged) && displayName.isNotEmpty;
    if (_hasChanged != changed) {
      setState(() {
        _hasChanged = changed;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.removeListener(_onInputChanged);
    _descriptionController.removeListener(_onInputChanged);
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
        _onInputChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarRadius = 44.0;
    return CupertinoPageScaffold(
      backgroundColor: theme.colorScheme.surface,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
        middle: Text(
          'Edit profile',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saving ? null : widget.onCancel,
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (!_hasChanged || _saving)
              ? null
              : () async {
                  if (widget.onSave != null) {
                    setState(() {
                      _saving = true;
                    });
                    await widget.onSave!(
                      _displayNameController.text.trim(),
                      _descriptionController.text.trim(),
                      _selectedAvatar,
                    );
                    setState(() {
                      _saving = false;
                    });
                  }
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save',
                style: TextStyle(
                  color: (!_hasChanged || _saving)
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_saving) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    semanticsLabel: 'Saving',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
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
                          : (widget.initialAvatarUrl != null && widget.initialAvatarUrl!.isNotEmpty)
                          ? NetworkImage(widget.initialAvatarUrl!)
                          : null as ImageProvider<Object>?,
                      child:
                          (_selectedAvatar == null &&
                              (widget.initialAvatarUrl == null || widget.initialAvatarUrl!.isEmpty))
                          ? Icon(
                              AppIcons.accountCircle,
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
                        child: Icon(AppIcons.camera, color: Colors.white, size: 12),
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
        ),
      ),
    );
  }
}
