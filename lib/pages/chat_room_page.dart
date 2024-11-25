import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;
  final String recipientName;
  final String recipientId;

  const ChatRoomPage({
    super.key,
    required this.chatRoomId,
    required this.recipientName,
    required this.recipientId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _messagesStream;

  // Inicializa o estado da página e configura o stream de mensagens
  @override
  void initState() {
    super.initState();
    // Garante que as mensagens sejam ordenadas corretamente
    _messagesStream = _firestore
        .collection('chatRooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
    
    // Adiciona índice para mensagens
    _createMessageIndex();
  }

  // Cria um índice para otimizar a consulta de mensagens no Firestore
  Future<void> _createMessageIndex() async {
    try {
      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .where('timestamp')
          .get();
    } catch (e) {
      print('Error creating message index: $e');
    }
  }

  // Envia uma nova mensagem para o chat e atualiza o estado da conversa
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Busca informações do chat room
      final chatRoom = await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .get();
      
      if (!chatRoom.exists) {
        print('Chat room not found');
        return;
      }

      final chatData = chatRoom.data() as Map<String, dynamic>;
      final isHealthProfessional = user.uid == chatData['professionalId'];

      // Prepara a mensagem com todos os campos necessários
      final message = {
        'text': _messageController.text.trim(),
        'senderId': user.uid,
        'senderName': isHealthProfessional ? chatData['professionalName'] : chatData['userName'],
        'timestamp': FieldValue.serverTimestamp(),
        'isFromProfessional': isHealthProfessional,
        'senderRole': isHealthProfessional ? 'professional' : 'user',
        'chatRoomId': widget.chatRoomId,
      };

      // Adiciona a mensagem à coleção de mensagens
      final messageRef = await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(message);

      // Atualiza o último estado do chat room
      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .update({
            'lastMessage': _messageController.text.trim(),
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastSenderId': user.uid,
            'lastMessageId': messageRef.id,
            'lastSenderName': isHealthProfessional ? chatData['professionalName'] : chatData['userName'],
            'lastSenderRole': isHealthProfessional ? 'professional' : 'user',
          });

      _messageController.clear();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
    }
  }

  // Verifica se um usuário é um profissional de saúde
  Future<bool> _isHealthProfessional(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.data()?['health_professional'] == true;
  }

  // Constrói a interface do chat com a lista de mensagens e campo de entrada
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          // Messages list with improved UI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == _auth.currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['senderName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                color: isMe
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Limpa os recursos quando a página é fechada
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}