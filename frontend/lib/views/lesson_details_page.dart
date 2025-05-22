import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:html_unescape/html_unescape.dart';
import '../models/lesson.dart';

class LessonDetailsPage extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailsPage({Key? key, required this.lesson}) : super(key: key);

  @override
  State<LessonDetailsPage> createState() => _LessonDetailsPageState();
}

class _LessonDetailsPageState extends State<LessonDetailsPage> {
  VideoPlayerController? _videoController;
  String? lessonText;
  List<String> documents = [];
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    // Parse content
    final unescape = HtmlUnescape();
    try {
      var content = widget.lesson.content;
      if (content.contains('&quot;')) {
        content = unescape.convert(content);
      }
      if (content.isNotEmpty && content.trim().startsWith('{')) {
        final contentJson = json.decode(content);
        lessonText = contentJson['text'] ?? '';
        documents = (contentJson['documents'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      } else if (widget.lesson.content is Map) {
        final contentJson = widget.lesson.content as Map;
        lessonText = contentJson['text'] ?? '';
        documents = (contentJson['documents'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      } else {
        lessonText = widget.lesson.content;
      }
      print('Lesson documents: $documents');
    } catch (e) {
      lessonText = widget.lesson.content;
    }
    // Setup video player if videoUrl exists
    if (widget.lesson.videoUrl != null && widget.lesson.videoUrl!.isNotEmpty) {
      final videoUrl = widget.lesson.videoUrl!.startsWith('http')
          ? widget.lesson.videoUrl!
          : 'http://localhost/e_learning/backend/${widget.lesson.videoUrl!}';
      _videoController = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {});
        }).catchError((error) {
          setState(() {
            _videoError = true;
          });
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _showFullScreenVideo() async {
    if (_videoController == null) return;
    final videoUrl = widget.lesson.videoUrl!.startsWith('http')
        ? widget.lesson.videoUrl!
        : 'http://localhost/e_learning/backend/${widget.lesson.videoUrl!}';
    VideoPlayerController dialogController =
        VideoPlayerController.network(videoUrl);
    await dialogController.initialize();
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: dialogController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: dialogController.value.aspectRatio,
                          child: VideoPlayer(dialogController),
                        )
                      : const CircularProgressIndicator(),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () {
                      dialogController.pause();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                if (dialogController.value.isInitialized)
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            dialogController.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            setState(() {
                              dialogController.value.isPlaying
                                  ? dialogController.pause()
                                  : dialogController.play();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    await dialogController.pause();
    await dialogController.dispose();
    setState(() {});
  }

  Widget _buildVideoPlayer() {
    if (_videoError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.error, color: Colors.red, size: 48),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Video format not supported or file not found. Try using a different browser or check the file format.',
            style: TextStyle(color: Colors.red[700]),
          ),
        ],
      );
    }
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: VideoPlayer(_videoController!),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen,
                      color: Colors.white, size: 28),
                  onPressed: _showFullScreenVideo,
                  tooltip: 'Full Screen',
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
              ),
              Text(_videoController!.value.isPlaying ? "Pause" : "Play"),
              const SizedBox(width: 16),
              Text(
                _formatDuration(_videoController!.value.duration),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      );
    } else if (widget.lesson.videoUrl != null &&
        widget.lesson.videoUrl!.isNotEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Container();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${widget.lesson.createdAt}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (widget.lesson.duration != null) ...[
              const SizedBox(height: 4),
              Text(
                'Duration: ${widget.lesson.duration} minutes',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            _buildVideoPlayer(),
            if (widget.lesson.videoUrl != null &&
                widget.lesson.videoUrl!.isNotEmpty)
              const SizedBox(height: 24),
            Divider(),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lessonText ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Attachments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (widget.lesson.documents != null &&
                widget.lesson.documents!.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.lesson.documents!.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final document = widget.lesson.documents![index];
                  final docUrl = document.startsWith('http')
                      ? document
                      : 'http://localhost/e_learning/backend/$document';
                  return ListTile(
                    leading:
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(document.split('/').last),
                    onTap: () async {
                      if (await canLaunchUrl(Uri.parse(docUrl))) {
                        await launchUrl(Uri.parse(docUrl),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  );
                },
              )
            else
              Text(
                'No attachments available.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
