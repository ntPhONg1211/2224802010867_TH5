// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:personal_notes_app/data/note_storage.dart';
import 'package:personal_notes_app/models/note.dart';
import 'package:personal_notes_app/main.dart';

void main() {
  test('Notes support create, read, update and delete', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = NoteStorage.instance;
    final now = DateTime(2026, 10, 11);

    final id = await storage.insertNote(
      Note(
        title: 'Tiêu đề',
        content: 'Nội dung',
        createdAt: now,
        updatedAt: now,
      ),
    );
    var notes = await storage.getAllNotes();
    expect(notes, hasLength(1));
    expect(notes.single.id, id);

    await storage.updateNote(
      Note(
        id: id,
        title: 'Tiêu đề đã sửa',
        content: 'Nội dung mới',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );
    notes = await storage.getAllNotes();
    expect(notes.single.title, 'Tiêu đề đã sửa');

    await storage.deleteNote(id);
    expect(await storage.getAllNotes(), isEmpty);
  });

  testWidgets('Editor requires a title and note content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NoteEditorPage()),
    );

    expect(find.text('Ghi chú mới'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
    expect(find.text('Vui lòng nhập nội dung'), findsOneWidget);
  });
}
