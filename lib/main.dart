import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const AudioPlayerApp());
}

class AudioPlayerApp extends StatelessWidget {
  const AudioPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiple Audio Players',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  // List of audio URLs (you can add more URLs here)
  final List<String> _audioUrls = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
  ];

  // List to hold AudioPlayer instances
  late List<AudioPlayer> _audioPlayers;
  late List<double> _playbackSpeeds;

  @override
  void initState() {
    super.initState();
    // Initialize a player and playback speed for each URL
    _audioPlayers = _audioUrls.map((url) => AudioPlayer()..setUrl(url)).toList();
    _playbackSpeeds = List.filled(_audioUrls.length, 1.0);

    // Listen for completion on each player to reset to the start
    for (var player in _audioPlayers) {
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.seek(Duration.zero); // Reset to the start
        }
      });
    }
  }

  @override
  void dispose() {
    // Dispose of all players when the widget is disposed
    for (var player in _audioPlayers) {
      player.dispose();
    }
    super.dispose();
  }

  // Helper function to display formatted duration (e.g., 00:45)
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Function to change playback speed for a specific player
  void _changeSpeed(int index, double speed) {
    setState(() {
      _playbackSpeeds[index] = speed;
    });
    _audioPlayers[index].setSpeed(speed);
  }

  // Function to build each audio player
  Widget _buildAudioPlayer(int index) {
    final player = _audioPlayers[index];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Audio Player ${index + 1}'),
            // Play/Pause Button with Loading Indicator
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final isPlaying = playerState?.playing ?? false;
                final processingState = playerState?.processingState;

                if (processingState == ProcessingState.buffering) {
                  // Show a loading indicator while buffering
                  return const CircularProgressIndicator();
                } else {
                  return IconButton(
                    iconSize: 64,
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (isPlaying) {
                        player.pause();
                      } else {
                        player.play();
                      }
                    },
                  );
                }
              },
            ),
            // Seek Forward and Backward Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.replay_10),
                  onPressed: () => player.seek(player.position - const Duration(seconds: 10)),
                ),
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.forward_10),
                  onPressed: () => player.seek(player.position + const Duration(seconds: 10)),
                ),
              ],
            ),
            // Time Meter and Slider
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = player.duration ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      value: position.inSeconds.toDouble(),
                      max: duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        player.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    ),
                  ],
                );
              },
            ),
            // Playback Speed Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Speed: '),
                DropdownButton<double>(
                  value: _playbackSpeeds[index],
                  items: [0.5, 1.0, 1.5, 2.0]
                      .map(
                        (speed) => DropdownMenuItem(
                          value: speed,
                          child: Text('${speed}x'),
                        ),
                      )
                      .toList(),
                  onChanged: (speed) => _changeSpeed(index, speed ?? 1.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Audio Players'),
      ),
      body: ListView.builder(
        itemCount: _audioUrls.length,
        itemBuilder: (context, index) => _buildAudioPlayer(index),
      ),
    );
  }
}
