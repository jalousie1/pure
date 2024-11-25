import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthProfessionalChatPage extends StatefulWidget {
  const HealthProfessionalChatPage({super.key});

  @override
  State<HealthProfessionalChatPage> createState() => _HealthProfessionalChatPageState();
}

class _HealthProfessionalChatPageState extends State<HealthProfessionalChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _chatsStream;

  // Inicializa o estado da página e configura o stream de chats
  @override
  void initState() {
    super.initState();
    _initChatStream();
  }

  // Configura o stream para receber atualizações dos chats do profissional de saúde
  void _initChatStream() {
    final user = _auth.currentUser;
    if (user != null) {
      _chatsStream = _firestore
          .collection('chatRooms')
          .where('professionalId', isEqualTo: user.uid)
          .snapshots();

      print('Initializing chat stream for professional: ${user.uid}'); // Debug print
    }
  }

  // Constrói a interface da página com a lista de chats
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patient Chats'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          // Add debug prints
          if (snapshot.hasError) {
            print('Error in stream: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];
          print('Number of chats found: ${chats.length}'); // Debug print
          
          if (chats.isEmpty) {
            return const Center(
              child: Text('No active chats'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              // Add debug print for each chat
              print('Chat data: $chat');
              
              final lastMessage = chat['lastMessage'] as String? ?? 'No messages yet';
              final userName = chat['userName'] as String? ?? 'Anonymous User';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(userName),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTimestamp(chat['lastMessageTime'] as Timestamp?),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/chat-room',
                      arguments: {
                        'chatRoomId': chats[index].id,
                        'recipientName': userName,
                        'recipientId': chat['userId'],
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Formata a data da última mensagem para exibição
  // Retorna: hora atual se for hoje, 'Ontem' se for ontem, ou a data completa
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
