import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'widgets/premium_text_field.dart';
import 'widgets/premium_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthController _authController = AuthController();
  int _currentStep = 0;
  int _bedrooms = 1;
  int _bathrooms = 1;

  @override
  void dispose() {
    _authController.disposeControllers();
    super.dispose();
  }

  Future<void> _buscarCep(String cep) async {
    final error = await _authController.fetchCep(cep);
    if (error != null) {
      _showSnackBar(error, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _register() async {
    final error = await _authController.register(
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
    );
    if (error == null) {
      _showSnackBar('Cadastro realizado com sucesso!');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      _showSnackBar(error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                'Crie sua\nconta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  letterSpacing: -1,
                ),
              ),
            ),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: Colors.black),
                ),
                child: ListenableBuilder(
                  listenable: _authController,
                  builder: (context, _) {
                    return Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  elevation: 0,
                  physics: const ClampingScrollPhysics(),
                  onStepContinue: () {
                    if (_currentStep == 0) {
                      if (_authController.registerNameController.text.trim().isEmpty ||
                          _authController.registerEmailController.text.trim().isEmpty ||
                          _authController.registerPasswordController.text.isEmpty) {
                        _showSnackBar(
                          'Preencha os dados da conta antes de continuar.',
                          isError: true,
                        );
                        return;
                      }
                      setState(() {
                        _currentStep += 1;
                      });
                    } else if (_currentStep == 1) {
                      if (_authController.registerCepController.text.trim().isEmpty ||
                          _authController.registerLogradouroController.text.trim().isEmpty ||
                          _authController.registerNumeroController.text.trim().isEmpty ||
                          _authController.registerBairroController.text.trim().isEmpty ||
                          _authController.registerCidadeController.text.trim().isEmpty ||
                          _authController.registerEstadoController.text.trim().isEmpty) {
                        _showSnackBar(
                          'Preencha os dados do endereço antes de continuar.',
                          isError: true,
                        );
                        return;
                      }
                      setState(() {
                        _currentStep += 1;
                      });
                    } else {
                      _register();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep -= 1;
                      });
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  controlsBuilder: (context, details) {
                    final isLastStep = _currentStep == 2;
                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: PremiumButton(
                              text: isLastStep ? 'Concluir' : 'Continuar',
                              isLoading: _authController.isLoading,
                              onPressed: details.onStepContinue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextButton(
                              onPressed: _authController.isLoading
                                  ? null
                                  : details.onStepCancel,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                _currentStep == 0 ? 'Cancelar' : 'Voltar',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text(
                        'Dados Pessoais',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Column(
                        children: [
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _authController.registerNameController,
                            label: 'Nome Completo',
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _authController.registerEmailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _authController.registerPasswordController,
                            label: 'Senha',
                            obscureText: true,
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text(
                        'Endereço',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: PremiumTextField(
                                  controller: _authController.registerCepController,
                                  label: 'CEP',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    if (val.length >= 8) {
                                      _buscarCep(val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 56,
                                  child: _authController.isFetchingCep
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _authController.registerLogradouroController,
                            label: 'Logradouro (Rua/Av)',
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: PremiumTextField(
                                  controller: _authController.registerNumeroController,
                                  label: 'Número',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: PremiumTextField(
                                  controller: _authController.registerComplementoController,
                                  label: 'Complemento (Opcional)',
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PremiumTextField(
                            controller: _authController.registerBairroController,
                            label: 'Bairro',
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: PremiumTextField(
                                  controller: _authController.registerCidadeController,
                                  label: 'Cidade',
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: PremiumTextField(
                                  controller: _authController.registerEstadoController,
                                  label: 'UF',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.indexed,
                    ),
                    Step(
                      title: const Text(
                        'Tamanho do Imóvel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Column(
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Ajude-nos a estimar o valor base para as suas faxinas configurando o tamanho da sua casa padrão.',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          _buildCounterRow(
                            title: 'Quartos',
                            icon: Icons.bed,
                            value: _bedrooms,
                            onIncrement: () => setState(() => _bedrooms++),
                            onDecrement: () {
                              if (_bedrooms > 0) setState(() => _bedrooms--);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildCounterRow(
                            title: 'Banheiros',
                            icon: Icons.bathtub,
                            value: _bathrooms,
                            onIncrement: () => setState(() => _bathrooms++),
                            onDecrement: () {
                              if (_bathrooms > 0) setState(() => _bathrooms--);
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      isActive: _currentStep >= 2,
                    ),
                  ],
                );
              }
            ),
          ),
        ),
        ],
      ),
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required IconData icon,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: Colors.black87),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              color: value > 0 ? Colors.black : Colors.grey,
              iconSize: 32,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.black,
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }
}
