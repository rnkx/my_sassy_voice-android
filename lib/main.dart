import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'playlist_viewmodel.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlaylistViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Sassy Voice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MenuScreen(),
    );
  }
}

// ===============================
// MENU SCREEN
// ===============================

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Sassy Voice')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('Playlist'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistMenuScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle),
            title: const Text('Now Playing'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===============================
// PLAYLIST MENU SCREEN
// ===============================

class PlaylistMenuScreen extends StatelessWidget {
  const PlaylistMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PlaylistViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Playlist')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.deepPurple),
            title: const Text('Prayer Playlist'),
            subtitle: const Text('Prayer and worship songs'),
            onTap: () {
              vm.selectPlaylist('prayer');

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.piano, color: Colors.deepPurple),
            title: const Text('Scott Joplin Playlist'),
            subtitle: const Text('Scott Joplin Collection'),
            onTap: () {
              vm.selectPlaylist('scott');

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===============================
// PLAYLIST SCREEN
// ===============================

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PlaylistViewModel>(context);
    final playlist = vm.currentPlaylistSongs;

    return Scaffold(
      appBar: AppBar(title: Text(vm.currentPlaylistTitle)),
      body: ListView.builder(
        itemCount: playlist.length,
        itemBuilder: (context, index) {
          final song = playlist[index];

          final bool isCurrentSong =
              vm.currentSong?.audioPath == song.audioPath;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  song.albumArt,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                song.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(song.artist),
              trailing: IconButton(
                icon: Icon(
                  isCurrentSong && vm.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.deepPurple,
                  size: 34,
                ),
                onPressed: () async {
                  if (isCurrentSong && vm.isPlaying) {
                    await vm.pauseSong();
                  } else {
                    await vm.playSong(index);
                  }

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()),
                    );
                  }
                },
              ),
              onTap: () async {
                await vm.playSong(index);

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// ===============================
// PLAYER SCREEN
// ===============================

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PlaylistViewModel>(context);
    final song = vm.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play All Songs'),
            onPressed: () async {
              await vm.playAllSongsFromStart();
            },
          ),
        ),
      );
    }

    final double maxSeconds =
    vm.duration.inSeconds > 0 ? vm.duration.inSeconds.toDouble() : 1.0;

    final double currentSeconds =
    vm.position.inSeconds.toDouble().clamp(0.0, maxSeconds);

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  song.albumArt,
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                song.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                song.artist,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),

              Slider(
                min: 0,
                max: maxSeconds,
                value: currentSeconds,
                activeColor: Colors.deepPurple,
                inactiveColor: Colors.grey.shade400,
                onChangeStart: (_) {
                  vm.startSeek();
                },
                onChanged: (value) {
                  vm.updateSeekPreview(Duration(seconds: value.toInt()));
                },
                onChangeEnd: (value) async {
                  await vm.finishSeek(Duration(seconds: value.toInt()));
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(vm.position)),
                  Text(_formatDuration(vm.duration)),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () async {
                      await vm.previousSong();
                    },
                  ),
                  IconButton(
                    iconSize: 72,
                    color: Colors.deepPurple,
                    icon: Icon(
                      vm.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                    ),
                    onPressed: () async {
                      if (vm.isPlaying) {
                        await vm.pauseSong();
                      } else {
                        await vm.resumeSong();
                      }
                    },
                  ),
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.skip_next),
                    onPressed: () async {
                      await vm.nextSong();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      vm.shuffle ? Icons.shuffle_on : Icons.shuffle,
                      color: vm.shuffle ? Colors.deepPurple : Colors.grey,
                    ),
                    onPressed: vm.toggleShuffle,
                  ),
                  IconButton(
                    icon: Icon(
                      vm.repeatMode == PlaybackRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: vm.repeatMode == PlaybackRepeatMode.off
                          ? Colors.grey
                          : Colors.deepPurple,
                    ),
                    onPressed: vm.cycleRepeatMode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_circle),
                    color: Colors.redAccent,
                    onPressed: () async {
                      await vm.stopSong();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}