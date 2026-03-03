import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetracker/features/notes/models/note.dart';
import 'package:notetracker/features/notes/providers/notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? existingNote;

  const NoteEditorScreen({super.key, this.existingNote});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final QuillController _quillController;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _isPinned = note?.isPinned ?? false;

    if (note != null && note.richContentJson.isNotEmpty) {
      try {
        final doc = Document.fromJson(jsonDecode(note.richContentJson) as List);
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = widget.existingNote ?? Note();
    note.title = _titleController.text.trim();
    note.richContentJson =
        jsonEncode(_quillController.document.toDelta().toJson());
    note.isPinned = _isPinned;

    await ref.read(notesProvider.notifier).saveNote(note);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _save();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Note'),
          actions: [
            IconButton(
              tooltip: _isPinned ? 'Unpin' : 'Pin',
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? theme.colorScheme.primary : null,
              ),
              onPressed: () => setState(() => _isPinned = !_isPinned),
            ),
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.save_outlined),
              onPressed: () async {
                await _save();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _titleController,
                style: theme.textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(height: 1),
            QuillSimpleToolbar(
              controller: _quillController,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showFontSize: true,
                showUnderLineButton: false,
                showStrikeThrough: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showAlignmentButtons: false,
                showLeftAlignment: false,
                showCenterAlignment: false,
                showRightAlignment: false,
                showJustifyAlignment: false,
                showHeaderStyle: false,
                showListNumbers: false,
                showListBullets: false,
                showListCheck: false,
                showCodeBlock: false,
                showQuote: false,
                showIndent: false,
                showLink: false,
                showUndo: false,
                showRedo: false,
                showDirection: false,
                showSearchButton: false,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showClipboardCut: false,
                showClipboardCopy: false,
                showClipboardPaste: false,
                showFontFamily: false,
                showSmallButton: false,
                showDividers: false,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: QuillEditor.basic(
                  controller: _quillController,
                  config: const QuillEditorConfig(
                    placeholder: 'Start writing…',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
