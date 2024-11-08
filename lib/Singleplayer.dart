import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(AudioPlayerApp());
}

class AudioPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Audio Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _audioPlayer = AudioPlayer();
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setUrl(
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ); // Replace with your audio URL

    // Listen to the player state stream to detect completion
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero); // Reset to the start
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Helper function to display formatted duration (e.g., 00:45)
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Function to change playback speed
  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _audioPlayer.setSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Just Audio Player'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause Button with Loading Indicator
          StreamBuilder<PlayerState>(
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final isPlaying = playerState?.playing ?? false;
              final processingState = playerState?.processingState;

              if (processingState == ProcessingState.buffering) {
                // Show a loading indicator while buffering
                return CircularProgressIndicator();
              } else {
                return IconButton(
                  iconSize: 64,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      _audioPlayer.play();
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
                icon: Icon(Icons.replay_10),
                onPressed: () => _audioPlayer.seek(
                    _audioPlayer.position - Duration(seconds: 10)),
              ),
              IconButton(
                iconSize: 48,
                icon: Icon(Icons.forward_10),
                onPressed: () => _audioPlayer.seek(
                    _audioPlayer.position + Duration(seconds: 10)),
              ),
            ],
          ),
          // Time Meter and Slider
          StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _audioPlayer.duration ?? Duration.zero;

              return Column(
                children: [
                  Slider(
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(seconds: value.toInt()));
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
              Text('Speed: '),
              DropdownButton<double>(
                value: _playbackSpeed,
                items: [0.5, 1.0, 1.5, 2.0]
                    .map(
                      (speed) => DropdownMenuItem(
                        value: speed,
                        child: Text('${speed}x'),
                      ),
                    )
                    .toList(),
                onChanged: (speed) => _changeSpeed(speed ?? 1.0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
