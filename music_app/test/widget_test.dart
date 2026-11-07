import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/main.dart';
import 'package:music_app/models/song.dart';

void main() {
  test('Song model serializes correctly', () {
    const s = Song(
        id: 1,
        title: 'Test',
        artist: 'Artist',
        album: 'Album',
        data: '/music/test.mp3',
        durationMs: 180000);
    final m = s.toMap();
    final back = Song.fromMap(m);
    expect(back.title, 'Test');
    expect(back.artist, 'Artist');
    expect(back.durationMs, 180000);
  });

  testWidgets('MusicApp builds home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicApp());
    await tester.pump();
    expect(find.text('NhacOffline - N05'), findsOneWidget);
  });
}
