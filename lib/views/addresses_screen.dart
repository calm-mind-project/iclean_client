import 'package:flutter/material.dart';
import '../controllers/address_controller.dart';
import '../models/user_address.dart';
import 'address_form_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final AddressController _addressController = AddressController();

  @override
  void initState() {
    super.initState();
    _addressController.fetchAddresses();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _showAddressDialog({UserAddress? address}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddressFormScreen(addressController: _addressController, initialAddress: address),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Meus Endereços'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _addressController,
        builder: (context, _) {
          if (_addressController.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (_addressController.errorMessage != null) {
            return Center(child: Text(_addressController.errorMessage!));
          }

          final addresses = _addressController.addresses;

          if (addresses.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum endereço cadastrado.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: addr.isDefault ? Colors.black : Colors.grey.shade200,
                    width: addr.isDefault ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          addr.label.toLowerCase() == 'casa'
                              ? Icons.home
                              : Icons.business,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          addr.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (addr.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Padrão',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      addr.shortAddress,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!addr.isDefault)
                          TextButton(
                            onPressed: () {
                              _addressController.setDefault(addr.id!);
                            },
                            child: const Text('Tornar Padrão'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showAddressDialog(address: addr),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            _addressController.deleteAddress(addr.id!);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressDialog(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
