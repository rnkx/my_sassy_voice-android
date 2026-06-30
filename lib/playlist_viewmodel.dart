import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'song_model.dart';

enum PlaybackRepeatMode {
  off,
  one,
  all,
}

class PlaylistViewModel extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();

  final List<Song> prayerPlaylist = [
    const Song(
      title: 'Amazing Grace',
      artist: 'Prayer',
      audioPath: 'assets/audio/Amazing_Grace.mp3',
      albumArt: 'assets/images/Amazing_Grace.png',
    ),
    const Song(
      title: 'Furusato',
      artist: 'Prayer',
      audioPath: 'assets/audio/Furusato.mp3',
      albumArt: 'assets/images/Furusato.png',
    ),
  ];

  final List<Song> scottPlaylist = [
    const Song(
      title: 'The Entertainer',
      artist: 'Scott Joplin',
      audioPath: 'assets/audio/entertainer.mp3',
      albumArt: 'assets/images/entertainer.png',
    ),
    const Song(
      title: 'Maple Leaf Rag',
      artist: 'Scott Joplin',
      audioPath: 'assets/audio/maple_leaf_rag.mp3',
      albumArt: 'assets/images/maple_leaf_rag.png',
    ),
    const Song(
      title: 'The Easy Winners',
      artist: 'Scott Joplin',
      audioPath: 'assets/audio/easy_winners.mp3',
      albumArt: 'assets/images/easy_winners.png',
    ),
    const Song(
      title: 'Pineapple Rag',
      artist: 'Scott Joplin',
      audioPath: 'assets/audio/pineapple_rag.mp3',
      albumArt: 'assets/images/pineapple_rag.png',
    ),
    const Song(
      title: 'Elite Syncopations',
      artist: 'Scott Joplin',
      audioPath: 'assets/audio/elite_syncopations.mp3',
      albumArt: 'assets/images/elite_syncopations.png',
    ),
    const Song(
      title: 'Searchlight Rag',
      artist: 'Scott Joplin',
      audioPath: 'assets/audio/Searchlight_Rag.mp3',
      albumArt: 'assets/images/searchlight_rag.png',
    ),
    const Song(
      title: 'Original Rags',
      artist: 'Scott Joplin',
      audioPath: 'assets/audio/Original_Rags.mp3',
      albumArt: 'assets/images/Original_Rags.png',
    ),
  ];

  String selectedPlaylist = 'prayer';
  List<Song> activeSongs = [];

  int currentIndex = -1;
  bool isPlaying = false;
  bool shuffle = false;
  bool isSeeking = false;

  PlaybackRepeatMode repeatMode = PlaybackRepeatMode.off;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  PlaylistViewModel() {
    audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    audioPlayer.setReleaseMode(ReleaseMode.stop);

    audioPlayer.onPositionChanged.listen((newPosition) {
      if (!isSeeking) {
        position = newPosition;
        notifyListeners();
      }
    });

    audioPlayer.onDurationChanged.listen((newDuration) {
      duration = newDuration;
      notifyListeners();
    });

    audioPlayer.onPlayerComplete.listen((event) async {
      await _handleSongComplete();
    });
  }

  List<Song> get allSongs => [
        ...prayerPlaylist,
        ...scottPlaylist,
      ];

  List<Song> get currentPlaylistSongs {
    return selectedPlaylist == 'prayer' ? prayerPlaylist : scottPlaylist;
  }

  String get currentPlaylistTitle {
    return selectedPlaylist == 'prayer'
        ? '🙏 Prayer Playlist'
        : '🎹 Scott Joplin Playlist';
  }

  Song? get currentSong {
    if (currentIndex < 0 || currentIndex >= activeSongs.length) {
      return null;
    }

    return activeSongs[currentIndex];
  }

  void selectPlaylist(String playlistName) {
    selectedPlaylist = playlistName;
    notifyListeners();
  }

  String _assetAudioPath(String path) {
    return path.startsWith('assets/')
        ? path.replaceFirst('assets/', '')
        : path;
  }

  Future<void> _playCurrentAudio() async {
    final song = currentSong;
    if (song == null) return;

    final wasSeeking = isSeeking;
    isSeeking = false;

    await audioPlayer.stop();

    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();

    await audioPlayer.play(
      AssetSource(_assetAudioPath(song.audioPath)),
    );

    isSeeking = wasSeeking;
  }

  Future<void> playSong(int index) async {
    activeSongs = List<Song>.from(currentPlaylistSongs);
    currentIndex = index;
    isPlaying = true;
    isSeeking = false;
    position = Duration.zero;
    duration = Duration.zero;

    notifyListeners();

    await _playCurrentAudio();
  }

  Future<void> playAllSongsFromStart() async {
    activeSongs = List<Song>.from(allSongs);
    currentIndex = 0;
    isPlaying = true;
    isSeeking = false;
    position = Duration.zero;
    duration = Duration.zero;

    notifyListeners();

    await _playCurrentAudio();
  }

  Future<void> pauseSong() async {
    await audioPlayer.pause();

    isPlaying = false;
    notifyListeners();
  }

  Future<void> resumeSong() async {
    if (currentIndex == -1 || activeSongs.isEmpty) {
      await playAllSongsFromStart();
      return;
    }

    await audioPlayer.resume();

    isPlaying = true;
    notifyListeners();
  }

  Future<void> stopSong() async {
    await audioPlayer.stop();

    currentIndex = -1;
    isPlaying = false;
    isSeeking = false;
    position = Duration.zero;
    duration = Duration.zero;

    notifyListeners();
  }

  Future<void> nextSong() async {
    if (activeSongs.isEmpty || currentIndex == -1) {
      await playAllSongsFromStart();
      return;
    }

    if (shuffle) {
      currentIndex = Random().nextInt(activeSongs.length);
    } else {
      currentIndex++;

      if (currentIndex >= activeSongs.length) {
        if (repeatMode == PlaybackRepeatMode.all) {
          currentIndex = 0;
        } else {
          await stopSong();
          return;
        }
      }
    }

    isPlaying = true;
    isSeeking = false;
    position = Duration.zero;
    duration = Duration.zero;

    notifyListeners();

    await _playCurrentAudio();
  }

  Future<void> previousSong() async {
    if (activeSongs.isEmpty || currentIndex == -1) {
      await playAllSongsFromStart();
      return;
    }

    currentIndex--;

    if (currentIndex < 0) {
      currentIndex = activeSongs.length - 1;
    }

    isPlaying = true;
    isSeeking = false;
    position = Duration.zero;
    duration = Duration.zero;

    notifyListeners();

    await _playCurrentAudio();
  }

  void startSeek() {
    if (duration == Duration.zero) return;

    isSeeking = true;
  }

  void updateSeekPreview(Duration newPosition) {
    if (duration == Duration.zero) return;

    position = _clampDuration(newPosition);
    notifyListeners();
  }

  Future<void> finishSeek(Duration newPosition) async {
    if (duration == Duration.zero) return;

    final safePosition = _clampDuration(newPosition);

    position = safePosition;
    notifyListeners();

    await audioPlayer.seek(safePosition);

    isSeeking = false;
    notifyListeners();

    if (isPlaying) {
      await audioPlayer.resume();
    }
  }

  Future<void> seekTo(Duration newPosition) async {
    if (duration == Duration.zero) return;

    final safePosition = _clampDuration(newPosition);

    position = safePosition;
    notifyListeners();

    await audioPlayer.seek(safePosition);

    if (isPlaying) {
      await audioPlayer.resume();
    }
  }

  Duration _clampDuration(Duration value) {
    if (value < Duration.zero) return Duration.zero;
    if (duration != Duration.zero && value > duration) return duration;
    return value;
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void cycleRepeatMode() {
    if (repeatMode == PlaybackRepeatMode.off) {
      repeatMode = PlaybackRepeatMode.one;
    } else if (repeatMode == PlaybackRepeatMode.one) {
      repeatMode = PlaybackRepeatMode.all;
    } else {
      repeatMode = PlaybackRepeatMode.off;
    }

    notifyListeners();
  }

  Future<void> _handleSongComplete() async {
    if (repeatMode == PlaybackRepeatMode.one) {
      await _playCurrentAudio();
      return;
    }

    await nextSong();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
