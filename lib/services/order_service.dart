import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_order.dart';

class OrderService {
  final _client = Supabase.instance.client;

  /// Cria um novo pedido de faxina no Supabase
  Future<ServiceOrder> createOrder(ServiceOrder order) async {
    final response = await _client
        .from('service_orders')
        .insert(order.toMap())
        .select()
        .single();

    return ServiceOrder.fromMap(response);
  }

  /// Retorna true se usuário tiver pelo menos 1 serviço pendente aguardando profissional
  Future<bool> hasPendingOrder() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('service_orders')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'pending')
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Busca todos os pedidos do usuário logado
  Future<List<ServiceOrder>> fetchMyOrders() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('service_orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((map) => ServiceOrder.fromMap(map)).toList();
  }

  /// Cancela um pedido (atualiza o status para 'cancelled')
  Future<void> cancelOrder(String orderId) async {
    await _client
        .from('service_orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId);
  }

  /// Faz o upload de um vídeo de segurança para o bucket 'order_videos'
  Future<String> uploadOrderVideo(File videoFile, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.mp4';
    final path = '$userId/$fileName';

    await _client.storage.from('order_videos').upload(path, videoFile);

    // Retorna o caminho do vídeo (para buckets privados, geraremos uma URL assinada depois)
    return path;
  }
}
