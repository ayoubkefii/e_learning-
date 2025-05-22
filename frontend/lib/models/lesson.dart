import 'dart:convert';
import 'package:html_unescape/html_unescape.dart';

class Lesson {
  final int id;
  final int moduleId;
  final String title;
  final String content;
  final String? videoUrl;
  final int? duration;
  final int orderIndex;
  final String createdAt;
  final String updatedAt;
  final List<String>? documents;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.content,
    this.videoUrl,
    this.duration,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.documents,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Handle content and documents
    String content = '';
    List<String> documents = [];
    final unescape = HtmlUnescape();
    var rawContent = json['content'];
    if (rawContent != null) {
      if (rawContent is Map) {
        content = rawContent['text'] ?? '';
        documents = (rawContent['documents'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      } else if (rawContent is String) {
        var contentStr = rawContent;
        if (contentStr.contains('&quot;')) {
          contentStr = unescape.convert(contentStr);
        }
        if (contentStr.trim().startsWith('{')) {
          try {
            final contentJson = jsonDecode(contentStr);
            content = contentJson['text'] ?? '';
            documents = (contentJson['documents'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
          } catch (e) {
            content = contentStr;
          }
        } else {
          content = contentStr;
        }
      }
    }
    return Lesson(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      moduleId: json['module_id'] is int
          ? json['module_id']
          : int.tryParse(json['module_id'].toString()) ?? 0,
      title: json['title'] ?? '',
      content: content,
      videoUrl: json['video_url'] ?? '',
      duration:
          json['duration'] != null && json['duration'].toString().isNotEmpty
              ? int.tryParse(json['duration'].toString())
              : null,
      orderIndex: json['order_index'] is int
          ? json['order_index']
          : int.tryParse(json['order_index'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      documents: documents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'content': content,
      'video_url': videoUrl,
      'duration': duration,
      'order_index': orderIndex,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'documents': documents,
    };
  }
}
