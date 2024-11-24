import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Condições'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Termos e Condições de Uso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '1. Aceitação dos Termos\n\n'
              'Ao acessar e usar o aplicativo PureLife, você concorda em cumprir estes termos e condições de uso. Se você não concordar com qualquer parte destes termos, não deverá usar o aplicativo.\n\n'
              
              '2. Descrição do Serviço\n\n'
              'O PureLife é um aplicativo de saúde e bem-estar que oferece recursos como:\n'
              '• Monitoramento de atividades físicas e passos\n'
              '• Registro de medicamentos e lembretes\n'
              '• Acompanhamento de refeições e hidratação\n'
              '• Monitoramento de sono\n'
              '• Assistente virtual de saúde (MindBot)\n'
              '• Registro de humor e bem-estar\n\n'
              
              '3. Responsabilidades do Usuário\n\n'
              'O usuário é responsável por:\n'
              '• Fornecer informações precisas e verdadeiras\n'
              '• Manter a segurança de sua conta e senha\n'
              '• Usar o aplicativo de acordo com as leis aplicáveis\n'
              '• Não compartilhar informações sensíveis de saúde com outros usuários\n\n'
              
              '4. Limitações do Serviço\n\n'
              'O PureLife não substitui atendimento médico profissional. As informações e sugestões fornecidas pelo aplicativo, incluindo o MindBot, são apenas para fins informativos e de bem-estar geral.\n\n'
              
              '5. Privacidade e Dados\n\n'
              'Coletamos e processamos dados como:\n'
              '• Informações de perfil (nome, idade, CEP)\n'
              '• Dados de atividade física e passos\n'
              '• Registros de medicamentos e refeições\n'
              '• Informações de humor e bem-estar\n'
              '• Interações com o MindBot\n\n'
              'Seus dados são protegidos e tratados de acordo com nossa Política de Privacidade e leis de proteção de dados aplicáveis.\n\n'
              
              '6. Permissões do Dispositivo\n\n'
              'O aplicativo requer acesso a:\n'
              '• Sensores de atividade física\n'
              '• Armazenamento para salvar dados locais\n'
              '• Internet para sincronização e funcionamento do MindBot\n\n'
              
              '7. Segurança\n\n'
              'Utilizamos tecnologias de segurança para proteger seus dados, incluindo:\n'
              '• Autenticação segura via Firebase\n'
              '• Criptografia de dados sensíveis\n'
              '• Controle de acesso aos dados\n\n'
              
              '8. Alterações nos Termos\n\n'
              'Reservamo-nos o direito de modificar estes termos a qualquer momento. Alterações significativas serão notificadas através do aplicativo.\n\n'
              
              '9. Contato\n\n'
              'Para questões sobre estes termos ou sobre o aplicativo, entre em contato através do MindBot ou nossos canais de suporte.\n\n'
              
              '10. Encerramento\n\n'
              'Reservamo-nos o direito de encerrar o acesso ao aplicativo em caso de violação destes termos ou uso inadequado do serviço.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
