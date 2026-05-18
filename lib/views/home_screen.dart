import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import '../controllers/home_controller.dart';
import '../controllers/address_controller.dart';
import '../services/order_service.dart';
import 'widgets/home_drawer.dart';
import 'widgets/action_bottom_sheet.dart';
import 'service_flow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final HomeController _homeController = HomeController();
  final AddressController _addressController = AddressController();
  final OrderService _orderService = OrderService();

  bool _hasPendingOrder = false;
  late final AnimationController _bannerRotationController;

  @override
  void initState() {
    super.initState();
    _bannerRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _loadLocation();
    _addressController.fetchAddresses();
    _loadPendingOrder();
  }

  Future<void> _loadLocation() async {
    await _homeController.loadDeviceLocation();
    if (mounted) {
      if (_homeController.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_homeController.errorMessage!)),
        );
      } else {
        _mapController.move(_homeController.currentPosition, 16.0);
      }
    }
  }

  @override
  void dispose() {
    _bannerRotationController.dispose();
    _homeController.dispose();
    _addressController.dispose();
    super.dispose();
  }


  Future<void> _loadPendingOrder() async {
    try {
      final hasPendingOrder = await _orderService.hasPendingOrder();
      if (mounted) {
        setState(() => _hasPendingOrder = hasPendingOrder);
      }
    } catch (_) {}
  }

  void _solicitarServico() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ServiceFlowScreen())).then((_) {
      _loadPendingOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final name = metadata['name'] as String? ?? 'Sem Nome';
    final email = user?.email ?? 'N/A';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 112,
        leading: Builder(
          builder: (context) => Row(
            children: [
              Container(
                margin: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              if (_hasPendingOrder)
                Tooltip(
                  message: 'Limpeza registrada. Estamos selecionando a profissional.',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 1.08),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    onEnd: () {
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade700),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.hourglass_top, size: 18, color: Colors.black87),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      drawer: ListenableBuilder(
        listenable: _addressController,
        builder: (context, _) {
          String addressText = 'Nenhum endereço informado';
          if (!_addressController.isLoading && _addressController.addresses.isNotEmpty) {
            final defaultAddress = _addressController.addresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => _addressController.addresses.first,
            );
            addressText = defaultAddress.shortAddress;
          }
          return HomeDrawer(name: name, email: email, addressText: addressText);
        }
      ),
      body: ListenableBuilder(
        listenable: _homeController,
        builder: (context, _) {
          return Stack(
            children: [
              // 1. Camada de Fundo: O Mapa
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _homeController.currentPosition,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.iclean',
                  ),
                  // Marcador indicando a posição do usuário
                  if (!_homeController.isLoadingLocation)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _homeController.currentPosition,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.person_pin_circle,
                            size: 50,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                ],
              ),


              if (_hasPendingOrder)
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _bannerRotationController,
                      builder: (context, child) {
                        final angle = math.sin(_bannerRotationController.value * 2 * math.pi) * 0.05;
                        return Transform.rotate(angle: angle, child: child);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Text(
                          'PROCURANDO FAXINEIRA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Feedback visual se estiver carregando a localização do GPS
              if (_homeController.isLoadingLocation)
                const Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Buscando GPS do aparelho...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Camada Inferior: Painel de Ação (Bottom Sheet Fixo) extraído para componente
              ActionBottomSheet(onAction: _solicitarServico),
            ],
          );
        }
      ),
    );
  }
}
