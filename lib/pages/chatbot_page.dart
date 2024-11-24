import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

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

class _ChatBotPageWidgetState extends State<ChatBotPageWidget> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimController;

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  // Faz a rolagem automática para o final da lista de mensagens
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

  // Envia a mensagem para a API do Gemini e processa a resposta
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

  // Trata erros de comunicação com a API
  void _handleError(String message) {
    setState(() {
      _messages.add({'sender': 'bot', 'text': message});
      _isTyping = false;
    });
  }

  // Processa o texto para formatar palavras entre ** como negrito
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

  // Constrói o visual de cada mensagem no chat
  Widget _buildMessage(Map<String, String> message, bool isUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(isUser ? 20 * (1 - value) : -20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isUser 
              ? Theme.of(context).primaryColor 
              : isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isUser
              ? Text(
                  message['text']!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                )
              : RichText(
                  text: TextSpan(
                    children: _processText(message['text']!),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Cria o indicador animado de "digitando..." do bot
  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => _buildDot(index),
          ),
        ),
      ),
    );
  }

  // Cria os pontos animados do indicador de "digitando..."
  Widget _buildDot(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _typingAnimController,
      builder: (context, child) {
        final offset = sin((_typingAnimController.value * pi * 2) - (index * 0.8));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, offset * 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  // Constrói a interface principal do chat
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                
                return _buildMessage(message, isUser);
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
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark 
                        ? Colors.grey.shade800.withOpacity(0.9)
                        : Colors.grey.shade100.withOpacity(0.9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, 
                        vertical: 10
                      ),
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
    _typingAnimController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}

