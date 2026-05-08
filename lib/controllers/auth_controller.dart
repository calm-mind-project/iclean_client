import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cep_service.dart';
import '../services/address_service.dart';
import '../models/user_address.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final CepService _cepService = CepService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFetchingCep = false;
  bool get isFetchingCep => _isFetchingCep;

  // Controllers para Login
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Controllers para Register (Conta)
  final registerNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();

  // Controllers para Register (Endereço)
  final registerCepController = TextEditingController();
  final registerLogradouroController = TextEditingController();
  final registerNumeroController = TextEditingController();
  final registerComplementoController = TextEditingController();
  final registerBairroController = TextEditingController();
  final registerCidadeController = TextEditingController();
  final registerEstadoController = TextEditingController();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setFetchingCep(bool value) {
    _isFetchingCep = value;
    notifyListeners();
  }

  Future<String?> login() async {
    _setLoading(true);
    try {
      await _authService.signInWithPassword(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text,
      );
      return null; // Sucesso
    } catch (e) {
      return e.toString(); // Retorna o erro
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> fetchCep(String cep) async {
    _setFetchingCep(true);
    try {
      final addressData = await _cepService.fetchCep(cep);
      if (addressData != null) {
        registerLogradouroController.text = addressData['logradouro'] ?? '';
        registerBairroController.text = addressData['bairro'] ?? '';
        registerCidadeController.text = addressData['cidade'] ?? '';
        registerEstadoController.text = addressData['estado'] ?? '';
        return null;
      }
      return 'CEP não encontrado.';
    } catch (e) {
      return 'Erro ao buscar o CEP.';
    } finally {
      _setFetchingCep(false);
    }
  }

  Future<String?> register({int bedrooms = 1, int bathrooms = 1}) async {
    // Validação
    if (registerNameController.text.trim().isEmpty ||
        registerEmailController.text.trim().isEmpty ||
        registerPasswordController.text.isEmpty ||
        registerCepController.text.trim().isEmpty ||
        registerLogradouroController.text.trim().isEmpty ||
        registerNumeroController.text.trim().isEmpty ||
        registerBairroController.text.trim().isEmpty ||
        registerCidadeController.text.trim().isEmpty ||
        registerEstadoController.text.trim().isEmpty) {
      return 'Por favor, preencha todos os campos obrigatórios.';
    }

    _setLoading(true);
    try {
      final user = await _authService.signUp(
        email: registerEmailController.text.trim(),
        password: registerPasswordController.text,
        name: registerNameController.text.trim(),
      );

      if (user != null) {
        final addressService = AddressService();
        await addressService.createAddress(
          UserAddress(
            userId: user.id,
            label: 'Casa', // Padrão
            cep: registerCepController.text.trim(),
            logradouro: registerLogradouroController.text.trim(),
            numero: registerNumeroController.text.trim(),
            complemento: registerComplementoController.text.trim(),
            bairro: registerBairroController.text.trim(),
            cidade: registerCidadeController.text.trim(),
            estado: registerEstadoController.text.trim(),
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            isDefault: true,
          ),
        );
      }
      return null; // Sucesso
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void disposeControllers() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerCepController.dispose();
    registerLogradouroController.dispose();
    registerNumeroController.dispose();
    registerComplementoController.dispose();
    registerBairroController.dispose();
    registerCidadeController.dispose();
    registerEstadoController.dispose();
  }
}
