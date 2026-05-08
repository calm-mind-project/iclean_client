class UserAddress {
  final String? id;
  final String userId;
  final String label;
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final int bedrooms;
  final int bathrooms;
  final bool isDefault;
  final DateTime? createdAt;

  UserAddress({
    this.id,
    required this.userId,
    this.label = 'Casa',
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.isDefault = false,
    this.createdAt,
  });

  /// Formato legível do endereço completo
  String get fullAddress =>
      '$logradouro, $numero${complemento != null && complemento!.isNotEmpty ? ' - $complemento' : ''} — $bairro, $cidade/$estado';

  /// Linha resumida para exibição em cards
  String get shortAddress => '$logradouro, $numero — $cidade/$estado';

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'label': label,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'is_default': isDefault,
    };
  }

  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      label: map['label'] as String? ?? 'Casa',
      cep: map['cep'] as String,
      logradouro: map['logradouro'] as String,
      numero: map['numero'] as String,
      complemento: map['complemento'] as String?,
      bairro: map['bairro'] as String,
      cidade: map['cidade'] as String,
      estado: map['estado'] as String,
      bedrooms: map['bedrooms'] as int? ?? 1,
      bathrooms: map['bathrooms'] as int? ?? 1,
      isDefault: map['is_default'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  UserAddress copyWith({
    String? id,
    String? userId,
    String? label,
    String? cep,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    int? bedrooms,
    int? bathrooms,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
