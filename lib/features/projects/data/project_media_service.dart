import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectMediaService {
  ProjectMediaService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static const String _bucket = 'project-media';

  /// Upload une image de projet dans Supabase Storage.
  ///
  /// Structure :
  /// project-media/{userId}/{projectId}/{fileName}
  static Future<String> uploadProjectImage({
    required String projectId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('Utilisateur non connecté.');
    }

    final safeFileName = _sanitizeFileName(fileName);

    final path = '${user.id}/$projectId/$safeFileName';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );

    return path;
  }

  /// Enregistre le média dans public.project_media.
  static Future<Map<String, dynamic>> createProjectMedia({
    required String projectId,
    required String storagePath,
    required String mimeType,
    required int fileSizeBytes,
    int? width,
    int? height,
    int sortOrder = 0,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException('Utilisateur non connecté.');
    }

    final response = await _client
        .from('project_media')
        .insert({
          'project_id': projectId,
          'uploaded_by': user.id,
          'storage_path': storagePath,
          'media_type': 'image',
          'mime_type': mimeType,
          'file_size_bytes': fileSizeBytes,
          'width': width,
          'height': height,
          'sort_order': sortOrder,
        })
        .select()
        .single();

    return response;
  }

  /// Génère une URL signée temporaire pour afficher une image privée.
  static Future<String> createSignedUrl({
    required String storagePath,
    int expiresIn = 3600,
  }) {
    return _client.storage.from(_bucket).createSignedUrl(
          storagePath,
          expiresIn,
        );
  }

  /// Supprime le fichier du Storage.
  static Future<void> deleteStorageFile({
    required String storagePath,
  }) async {
    await _client.storage.from(_bucket).remove([
      storagePath,
    ]);
  }

  /// Supprime l'enregistrement dans project_media.
  static Future<void> deleteProjectMedia({
    required String mediaId,
  }) async {
    await _client.from('project_media').delete().eq(
          'id',
          mediaId,
        );
  }

  static String _sanitizeFileName(String fileName) {
    final normalized = fileName
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    if (normalized.isEmpty) {
      return 'image.webp';
    }

    return normalized;
  }
}
