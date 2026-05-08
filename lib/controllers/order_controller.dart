import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_order.dart';
import '../services/order_service.dart';

class OrderListController extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<ServiceOrder> _orders = [];
  List<ServiceOrder> get orders => _orders;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.fetchMyOrders();
    } catch (e) {
      _errorMessage = 'Erro ao buscar pedidos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _orderService.cancelOrder(orderId);
      // Atualiza localmente
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final oldOrder = _orders[index];
        _orders[index] = ServiceOrder(
          id: oldOrder.id,
          userId: oldOrder.userId,
          urgencyType: oldOrder.urgencyType,
          scheduledDate: oldOrder.scheduledDate,
          cleaningType: oldOrder.cleaningType,
          bedrooms: oldOrder.bedrooms,
          bathrooms: oldOrder.bathrooms,
          estimatedPrice: oldOrder.estimatedPrice,
          status: 'cancelled', // Novo status
          videoUrl: oldOrder.videoUrl,
          createdAt: oldOrder.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      // Falha silenciosa ou lançar para UI tratar
      throw Exception('Não foi possível cancelar o pedido: $e');
    }
  }
}

class OrderDetailController extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  ServiceOrder _order;
  ServiceOrder get order => _order;

  bool _isCancelling = false;
  bool get isCancelling => _isCancelling;

  OrderDetailController(this._order);

  Future<String?> cancelOrder() async {
    _isCancelling = true;
    notifyListeners();

    try {
      await _orderService.cancelOrder(_order.id!);
      _order = ServiceOrder(
        id: _order.id,
        userId: _order.userId,
        urgencyType: _order.urgencyType,
        scheduledDate: _order.scheduledDate,
        cleaningType: _order.cleaningType,
        bedrooms: _order.bedrooms,
        bathrooms: _order.bathrooms,
        estimatedPrice: _order.estimatedPrice,
        status: 'cancelled',
        videoUrl: _order.videoUrl,
        createdAt: _order.createdAt,
      );
      return null;
    } catch (e) {
      return 'Erro ao cancelar: $e';
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }
}

class OrderWizardController extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  int _currentPage = 0;
  int get currentPage => _currentPage;
  final int totalPages = 6; // +1 page for address selection

  String? selectedAddressId;
  String? urgencyType; // 'agendar' ou 'agora'
  DateTime? scheduledDate;
  TimeOfDay? scheduledTime;
  
  String? cleaningType; // 'padrao', 'pesada', 'pos_obra'
  
  int bedrooms = 1;
  int bathrooms = 1;
  
  File? securityVideo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void setAddressId(String addressId) {
    selectedAddressId = addressId;
    notifyListeners();
  }

  void setUrgencyType(String type) {
    urgencyType = type;
    if (type == 'agora') {
      scheduledDate = null;
      scheduledTime = null;
    }
    notifyListeners();
  }

  void setScheduledDate(DateTime date) {
    scheduledDate = date;
    notifyListeners();
  }

  void setScheduledTime(TimeOfDay time) {
    scheduledTime = time;
    notifyListeners();
  }

  void setCleaningType(String type) {
    cleaningType = type;
    notifyListeners();
  }

  void incrementBedrooms() {
    bedrooms++;
    notifyListeners();
  }

  void decrementBedrooms() {
    if (bedrooms > 0) bedrooms--;
    notifyListeners();
  }

  void incrementBathrooms() {
    bathrooms++;
    notifyListeners();
  }

  void decrementBathrooms() {
    if (bathrooms > 0) bathrooms--;
    notifyListeners();
  }

  void setSecurityVideo(File? video) {
    securityVideo = video;
    notifyListeners();
  }

  double calculateTotal() {
    double basePrice = 100.0;
    if (cleaningType == 'pesada') basePrice = 180.0;
    if (cleaningType == 'pos_obra') basePrice = 300.0;

    double sizeMultiplier = (bedrooms * 20.0) + (bathrooms * 30.0);
    double total = basePrice + sizeMultiplier;
    if (urgencyType == 'agora') total += 50.0;
    return total;
  }

  Future<String?> finishFlow() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      DateTime? scheduledDateTime;
      if (urgencyType == 'agendar' && scheduledDate != null && scheduledTime != null) {
        scheduledDateTime = DateTime(
          scheduledDate!.year,
          scheduledDate!.month,
          scheduledDate!.day,
          scheduledTime!.hour,
          scheduledTime!.minute,
        );
      }

      String? uploadedVideoUrl;
      if (securityVideo != null) {
        uploadedVideoUrl = await _orderService.uploadOrderVideo(securityVideo!, userId);
      }

      final order = ServiceOrder(
        userId: userId,
        addressId: selectedAddressId,
        urgencyType: urgencyType!,
        scheduledDate: scheduledDateTime,
        cleaningType: cleaningType!,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        estimatedPrice: calculateTotal(),
        videoUrl: uploadedVideoUrl,
      );

      await _orderService.createOrder(order);
      return null; // Sucesso
    } on StorageException catch (e) {
      if (e.statusCode == '413') {
        return 'O vídeo de segurança é muito grande (limite do servidor atingido). Por favor, grave um vídeo mais curto ou diminua a resolução.';
      }
      return 'Erro no armazenamento: ${e.message}';
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
