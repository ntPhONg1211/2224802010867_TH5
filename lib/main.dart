import 'package:flutter/material.dart';

import 'data/note_storage.dart';
import 'models/note.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF176B5B);
    return MaterialApp(
      title: 'Ghi chú cá nhân',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF5F7F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F4),
          foregroundColor: Color(0xFF18332D),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFE4EAE5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
      home: const NotesHomePage(),
    );
  }
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({super.key});

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final _searchController = TextEditingController();
  List<Note> _notes = [];
  bool _isLoading = true;
  String _query = '';

  List<Note> get _visibleNotes {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _notes;
    return _notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final notes = await NoteStorage.instance.getAllNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _openEditor([Note? note]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
    );
    if (saved == true) await _loadNotes();
  }

  Future<bool> _confirmDelete(Note note) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa ghi chú?'),
            content: Text('Bạn có chắc muốn xóa “${note.title}” không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteNote(Note note) async {
    final id = note.id;
    if (id == null) return;
    await NoteStorage.instance.deleteNote(id);
    if (!mounted) return;
    setState(() => _notes.removeWhere((item) => item.id == id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa ghi chú')),
    );
  }

  Future<void> _showNoteActions(Note note) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline, color: Color(0xFFB5473C)),
          title: const Text('Xóa ghi chú'),
          onTap: () => Navigator.pop(context, true),
        ),
      ),
    );
    if (shouldDelete == true && await _confirmDelete(note)) {
      await _deleteNote(note);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'thg 1',
      'thg 2',
      'thg 3',
      'thg 4',
      'thg 5',
      'thg 6',
      'thg 7',
      'thg 8',
      'thg 9',
      'thg 10',
      'thg 11',
      'thg 12',
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = _visibleNotes;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ghi chú',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Ghi chú mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Góc riêng của bạn',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF18332D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              '${_notes.length} ghi chú đã lưu',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Tìm trong ghi chú',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa nội dung tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleNotes.isEmpty
                      ? _EmptyState(
                          isSearching: _query.trim().isNotEmpty,
                          onCreate: () => _openEditor(),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: visibleNotes.length,
                            separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final note = visibleNotes[index];
                            return Dismissible(
                              key: ValueKey(note.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 22),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8E7E3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFB5473C),
                                ),
                              ),
                              confirmDismiss: (_) => _confirmDelete(note),
                              onDismissed: (_) => _deleteNote(note),
                              child: _NoteTile(
                                note: note,
                                dateLabel: _formatDate(note.createdAt),
                                onTap: () => _openEditor(note),
                                onLongPress: () => _showNoteActions(note),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.dateLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final Note note;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5EAE5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C9B81),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF18332D),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Tạo ngày $dateLabel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching, required this.onCreate});

  final bool isSearching;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.sticky_note_2_outlined,
            size: 42,
            color: const Color(0xFF5C8174),
          ),
          const SizedBox(height: 12),
          Text(
            isSearching ? 'Không tìm thấy ghi chú' : 'Chưa có ghi chú nào',
            style: const TextStyle(
              color: Color(0xFF18332D),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 5),
            Text(
              'Bắt đầu bằng một ý tưởng nhỏ.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Tạo ghi chú'),
            ),
          ],
        ],
      ),
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (_isEditing) {
        await NoteStorage.instance.updateNote(note);
      } else {
        await NoteStorage.instance.insertNote(note);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu ghi chú. Vui lòng thử lại.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa ghi chú' : 'Ghi chú mới'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveNote,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Ghi chú về điều gì?',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tiêu đề'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 10,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                hintText: 'Viết nội dung ghi chú tại đây...',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập nội dung'
                  : null,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              Text(
                'Tạo ngày ${widget.note!.createdAt.day}/${widget.note!.createdAt.month}/${widget.note!.createdAt.year}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
