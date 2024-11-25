import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthChatPage extends StatefulWidget {
  const HealthChatPage({super.key});

  @override
  State<HealthChatPage> createState() => _HealthChatPageState();
}

class _HealthChatPageState extends State<HealthChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _professionalsStream;

  List<String> _filters = ['All'];
  String _selectedFilter = 'All';
  List<String> _favorites = []; // Add this as a class field

  // Inicializa os dados necessários quando a página é criada
  @override
  void initState() {
    super.initState();
    // Initialize the professionals stream from Firestore
    _professionalsStream = _firestore.collection('health_professionals').snapshots();
    _loadFavoriteProfessionals();
    _loadSpecialties(); // Adicionar chamada para carregar especialidades
  }

  // Inicia uma conversa com um profissional de saúde selecionado
  Future<void> _startChat(Map<String, dynamic> professional) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to start a chat')),
        );
        return;
      }

      // Get user data from Firestore
      final userData = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userData.exists) {
        print('User data not found');
        return;
      }

      final userName = userData.data()?['username'] as String? ?? 'Anonymous User';

      // Create a unique chat room ID combining both user IDs
      final chatRoomId = 'chat_${user.uid}_${professional['id']}';
      
      // Create a chat room document
      final chatRef = _firestore.collection('chatRooms').doc(chatRoomId);
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        await chatRef.set({
          'professionalId': professional['id'],
          'userId': user.uid,
          'professionalName': professional['name'],
          'userName': userName, // Use the fetched username
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'professionalSpecialty': professional['specialty'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Created new chat room: $chatRoomId'); // Debug print
      }

      // Navigate to chat room
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chat-room',
          arguments: {
            'chatRoomId': chatRoomId,
            'recipientName': professional['name'],
            'recipientId': professional['id'],
          },
        );
      }
    } catch (e) {
      print('Error starting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Carrega a lista de profissionais favoritos do usuário
  Future<void> _loadFavoriteProfessionals() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .get();
        
        // Store favorites in class field
        setState(() {
          _favorites = userData.docs.map((doc) => doc.id).toList();
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Adiciona ou remove um profissional da lista de favoritos
  Future<void> _toggleFavorite(String professionalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userRef = _firestore.collection('users').doc(user.uid);
      final favoriteRef = userRef.collection('favorites').doc(professionalId);
      
      final doc = await favoriteRef.get();
      if (doc.exists) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // Calcula a média das avaliações de um profissional
  Future<double> _loadProfessionalRating(String professionalId) async {
    try {
      final ratings = await _firestore
          .collection('health_professionals') // Update collection name here
          .doc(professionalId)
          .collection('ratings')
          .get();

      if (ratings.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var rating in ratings.docs) {
        totalRating += rating.data()['rating'] as double;
      }
      return totalRating / ratings.docs.length;
    } catch (e) {
      print('Error loading rating: $e');
      return 0.0;
    }
  }

  // Carrega todas as especialidades disponíveis para filtrar
  Future<void> _loadSpecialties() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('health_professionals')
          .get();

      // Criar conjunto para evitar duplicatas
      final Set<String> specialties = {'All', 'Online'};
      
      // Adicionar cada especialidade única ao conjunto
      for (var doc in snapshot.docs) {
        final specialty = (doc.data() as Map<String, dynamic>)['specialty']?.toString();
        if (specialty != null && specialty.isNotEmpty) {
          specialties.add(specialty);
        }
      }

      // Atualizar lista de filtros
      setState(() {
        _filters = specialties.toList()..sort();
        // Garantir que 'All' e 'Online' fiquem no início
        _filters.remove('All');
        _filters.remove('Online');
        _filters.insert(0, 'Online');
        _filters.insert(0, 'All');
      });
    } catch (e) {
      print('Error loading specialties: $e');
    }
  }

  // Constrói a lista de profissionais com suas informações
  Widget _buildProfessionalsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _professionalsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final professionals = snapshot.data?.docs ?? [];
        
        if (professionals.isEmpty) {
          return const Center(child: Text('No professionals available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: professionals.length,
          itemBuilder: (context, index) {
            final professional = professionals[index].data() as Map<String, dynamic>;
            professional['id'] = professionals[index].id;

            // Add null checks and default values
            final name = professional['name']?.toString() ?? 'No name';
            final specialty = professional['specialty']?.toString() ?? 'Unknown specialty';
            final image = professional['image']?.toString() ?? 'https://via.placeholder.com/150';
            final status = professional['status']?.toString() ?? 'Offline';
            final rating = professional['rating']?.toString() ?? '0.0';

            if (_selectedFilter != 'All' &&
                status != _selectedFilter &&
                specialty != _selectedFilter) {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(image),
                  onBackgroundImageError: (e, s) => const Icon(Icons.person),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Online'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: status == 'Online'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(specialty),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _favorites.contains(professional['id']) 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        color: _favorites.contains(professional['id'])
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => _toggleFavorite(professional['id']),
                    ),
                    FilledButton(
                      onPressed: status == 'Online'
                          ? () => _startChat(professional)
                          : null,
                      child: const Text('Chat'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Constrói a interface principal da página
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthcare Professionals'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search professionals...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildProfessionalsList(),
          ),
        ],
      ),
    );
  }
}
