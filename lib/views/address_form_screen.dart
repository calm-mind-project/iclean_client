import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/address_controller.dart';
import '../models/user_address.dart';
import '../services/cep_service.dart';
import 'widgets/premium_text_field.dart';
import 'widgets/premium_button.dart';

class AddressFormScreen extends StatefulWidget {
  final AddressController addressController;

  const AddressFormScreen({super.key, required this.addressController});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CepService _cepService = CepService();

  final _labelController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  bool _isDefault = false;
  bool _isFetchingCep = false;
  int _bedrooms = 1;
  int _bathrooms = 1;

  @override
  void dispose() {
    _labelController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep(String cep) async {
    setState(() => _isFetchingCep = true);
    try {
      final addressData = await _cepService.fetchCep(cep);
      if (addressData != null) {
        setState(() {
          _logradouroController.text = addressData['logradouro'] ?? '';
          _bairroController.text = addressData['bairro'] ?? '';
          _cidadeController.text = addressData['cidade'] ?? '';
          _estadoController.text = addressData['estado'] ?? '';
        });
      } else {
        _showSnackBar('CEP não encontrado.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao buscar o CEP.', isError: true);
    } finally {
      setState(() => _isFetchingCep = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_labelController.text.trim().isEmpty ||
        _cepController.text.trim().isEmpty ||
        _logradouroController.text.trim().isEmpty ||
        _numeroController.text.trim().isEmpty ||
        _bairroController.text.trim().isEmpty ||
        _cidadeController.text.trim().isEmpty ||
        _estadoController.text.trim().isEmpty) {
      _showSnackBar('Por favor, preencha todos os campos obrigatórios.', isError: true);
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final newAddress = UserAddress(
      userId: userId,
      label: _labelController.text.trim().isEmpty ? 'Novo Endereço' : _labelController.text.trim(),
      cep: _cepController.text.trim(),
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim(),
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      isDefault: _isDefault,
    );

    final error = await widget.addressController.saveAddress(newAddress);
    if (error == null) {
      _showSnackBar('Endereço salvo com sucesso!');
      if (mounted) Navigator.of(context).pop();
    } else {
      _showSnackBar(error, isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Novo Endereço'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PremiumTextField(
                controller: _labelController,
                label: 'Nome do local (Ex: Trabalho, Casa da Mãe)',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: PremiumTextField(
                      controller: _cepController,
                      label: 'CEP',
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        if (val.length >= 8) _buscarCep(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 56,
                      child: _isFetchingCep
                          ? const Center(child: CircularProgressIndicator(color: Colors.black))
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _logradouroController,
                label: 'Logradouro (Rua/Av)',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: PremiumTextField(
                      controller: _numeroController,
                      label: 'Número',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: PremiumTextField(
                      controller: _complementoController,
                      label: 'Complemento (Opcional)',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: _bairroController,
                label: 'Bairro',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PremiumTextField(
                      controller: _cidadeController,
                      label: 'Cidade',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: PremiumTextField(
                      controller: _estadoController,
                      label: 'UF',
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Tamanho do Imóvel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Definir como endereço padrão'),
                value: _isDefault,
                activeTrackColor: Colors.black,
                onChanged: (bool value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              ListenableBuilder(
                listenable: widget.addressController,
                builder: (context, _) {
                  return PremiumButton(
                    text: 'Salvar Endereço',
                    isLoading: widget.addressController.isSaving,
                    onPressed: _saveAddress,
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
