import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

class NoteStorage {
  NoteStorage._();

  static final NoteStorage instance = NoteStorage._();
  static const _storageKey = 'personal_notes';

  Future<List<Note>> getAllNotes() async {
    final preferences = await SharedPreferences.getInstance();
    final storedNotes = preferences.getStringList(_storageKey) ?? [];
    final notes = storedNotes
        .map(
          (value) => Note.fromMap(
            jsonDecode(value) as Map<String, Object?>,
          ),
        )
        .toList();
    notes.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return notes;
  }

  Future<int> insertNote(Note note) async {
    final notes = await getAllNotes();
    var largestId = 0;
    for (final item in notes) {
      if (item.id != null && item.id! > largestId) largestId = item.id!;
    }

    final savedNote = Note(
      id: largestId + 1,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
    notes.add(savedNote);
    await _saveNotes(notes);
    return savedNote.id!;
  }

  Future<void> updateNote(Note note) async {
    final notes = await getAllNotes();
    final index = notes.indexWhere((item) => item.id == note.id);
    if (index == -1) return;
    notes[index] = note;
    await _saveNotes(notes);
  }

  Future<void> deleteNote(int id) async {
    final notes = await getAllNotes();
    notes.removeWhere((note) => note.id == id);
    await _saveNotes(notes);
  }

  Future<void> _saveNotes(List<Note> notes) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      notes.map((note) => jsonEncode(note.toMap())).toList(),
    );
  }
}