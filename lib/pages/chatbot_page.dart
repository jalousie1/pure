import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String aiInstructions = '''
Você é um assistente especializado em saúde geral do MindBot. Siga estas diretrizes:

REGRAS PRINCIPAIS:
1. Use somente português do Brasil
2. Mantenha respostas curtas e diretas (máximo 3 parágrafos)
3. Baseie as respostas em evidências científicas
4. Não faça diagnósticos médicos
5. Para assuntos não relacionados à saúde, responda: "Desculpe, só posso ajudar com questões relacionadas à saúde."

TÓPICOS PERMITIDOS:
- Alimentação saudável
- Exercícios físicos
- Sono e descanso
- Prevenção de doenças
- Hábitos saudáveis
- Higiene pessoal
- Bem-estar geral
- Primeiros socorros básicos

EM CASOS DE DEPRESSÃO:
1. Identifique sinais de depressão na mensagem
2. Responda com empatia e acolhimento
3. Sugira buscar ajuda profissional
4. Forneça contatos úteis:
   - CVV: 188 (24h)
   - CAPS de sua região
5. Dê dicas práticas de autocuidado

IMPORTANTE:
- Não prescreva medicamentos
- Não faça diagnósticos
- Sempre incentive consultar profissionais de saúde
- Mantenha tom acolhedor e profissional
''';

class ChatBotPageWidget extends StatefulWidget {
  const ChatBotPageWidget({super.key});

  @override
  State<ChatBotPageWidget> createState() => _ChatBotPageWidgetState();
}

class _ChatBotPageWidgetState extends State<ChatBotPageWidget> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Create chat history string
      final chatHistory = _messages
          .map((msg) => "${msg['sender'] == 'user' ? 'Usuário' : 'Assistente'}: ${msg['text']}")
          .join('\n');

      final response = await http.post(
        Uri.parse('${dotenv.env['GEMINI_API_URL']}?key=${dotenv.env['GEMINI_API_KEY']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "$aiInstructions\n\nHistórico do Chat:\n$chatHistory"
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({'sender': 'bot', 'text': botResponse});
          _isTyping = false;
        });
        _scrollToBottom();
      } else {
        _handleError('Erro na resposta: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('Erro ao enviar mensagem');
    }
  }

  void _handleError(String message) {
    setState(() {
      _messages.add({'sender': 'bot', 'text': message});
      _isTyping = false;
    });
  }

  List<TextSpan> _processText(String text) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int lastMatch = 0;

    for (Match match in exp.allMatches(text)) {
      if (match.start > lastMatch) {
        spans.add(TextSpan(
          text: text.substring(lastMatch, match.start),
          style: const TextStyle(fontSize: 16),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ));
      lastMatch = match.end;
    }

    if (lastMatch < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatch),
        style: const TextStyle(fontSize: 16),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat com MindBot', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,  // Keep this for auto-scroll
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )),
                  );
                }

                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).primaryColor : Colors.grey.shade200,  // Remove opacity
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: isUser 
                      ? Text(
                          message['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            children: _processText(message['text']!),
                            style: const TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(25),
                  child: InkWell(
                    onTap: () {
                      if (_controller.text.isNotEmpty) {
                        _sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const Icon(Icons.send, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}

