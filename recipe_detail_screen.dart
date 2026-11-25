import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'recipe.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  // Replace with the ID of any cooking video: the part after "v=" in a YouTube link
  static const videoId = 'dQw4w9WgXcQ';
  static const storeLocation = LatLng(22.3569, 91.7832);

  late final YoutubePlayerController _yt;
  double _rating = 0;
  DateTime? _cookDate;

  @override
  void initState() {
    super.initState();
    _yt = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _cookDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _cookDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return Scaffold(
      appBar: AppBar(title: Text(r.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            r.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 4),
          Text('${r.category} • ${r.difficulty} • ${r.cookTime} min')
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(controller: _yt, aspectRatio: 16 / 9),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          const SizedBox(height: 24),
          const Text(
            'Rate this recipe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            allowHalfRating: true,
            itemCount: 5,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (v) => setState(() => _rating = v),
          ),
          Text(_rating == 0 ? 'Not rated yet' : 'Your rating: $_rating / 5'),
          const SizedBox(height: 24),
          const Text(
            'Plan to cook on',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _cookDate == null
                  ? 'Pick a date'
                  : DateFormat.yMMMMd().format(_cookDate!),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Buy ingredients nearby',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: storeLocation,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cooknest.cooknest',
                  ),
                  const MarkerLayer(
                    markers: [
                      Marker(
                        point: storeLocation,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
