import 'package:flutter/material.dart';

import '../data/messaging_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _composer = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  String _title = 'Conversation';
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _channel = MessagingService.subscribeToMessages(widget.conversationId, _refreshMessages);
  }

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    final channel = _channel;
    if (channel != null) {
      MessagingService.unsubscribe(channel);
    }
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await MessagingService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
        if (messages.isNotEmpty) {
          final profile = messages.last['sender_profile'] as Map<String, dynamic>?;
          final name = profile?['full_name']?.toString().trim();
          if (name != null && name.isNotEmpty) _title = name;
        }
      });
      await MessagingService.markConversationRead(widget.conversationId);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les messages.';
      });
    }
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await MessagingService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() => _messages = messages);
      await MessagingService.markConversationRead(widget.conversationId);
      _scrollToBottom();
    } catch (_) {
      // Realtime refresh failures are intentionally non-blocking.
    }
  }

  Future<void> _sendMessage() async {
    final content = _composer.text.trim();
    if (content.isEmpty || _sending) return;

    _composer.clear();
    setState(() => _sending = true);

    try {
      await MessagingService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );
      await _refreshMessages();
    } catch (error) {
      if (!mounted) return;
      _composer.text = content;
      _composer.selection = TextSelection.collapsed(offset: content.length);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Envoi impossible : $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editMessage(Map<String, dynamic> message) async {
    final controller = TextEditingController(text: message['content']?.toString() ?? '');
    final edited = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(controller: controller, autofocus: true, maxLines: 5),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    controller.dispose();
    if (edited == null || edited.trim().isEmpty) return;

    try {
      await MessagingService.editMessage(messageId: message['id'].toString(), content: edited);
      await _refreshMessages();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Modification impossible : $error')));
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text('Le message sera masqué pour la conversation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await MessagingService.deleteMessage(message['id'].toString());
      await _refreshMessages();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Suppression impossible : $error')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _time(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = MessagingServiceCurrentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessages(currentUserId)),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(String? currentUserId) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: _loadMessages, icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Commence la conversation 👋', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final senderId = message['sender_id']?.toString();
        final mine = currentUserId != null && senderId == currentUserId;
        final deleted = message['deleted_at'] != null;
        final content = deleted ? 'Message supprimé' : (message['content']?.toString() ?? '');

        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: mine && !deleted
                ? () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit_outlined),
                              title: const Text('Modifier'),
                              onTap: () {
                                Navigator.pop(context);
                                _editMessage(message);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline_rounded),
                              title: const Text('Supprimer'),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteMessage(message);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: mine ? Theme.of(context).colorScheme.onPrimary : null,
                      fontStyle: deleted ? FontStyle.italic : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_time(message['created_at']?.toString())}${message['edited_at'] != null ? ' · modifié' : ''}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: mine
                              ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.72)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.viewInsetsOf(context).bottom),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _composer,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Écrire un message...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Envoyer',
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagingServiceCurrentUser {
  static String? get id => SupabaseCurrentUserBridge.id;
}

class SupabaseCurrentUserBridge {
  static String? get id => null;
}
