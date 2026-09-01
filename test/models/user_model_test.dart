import 'package:flutter_test/flutter_test.dart';
import 'package:meliapp_flutter/models/user_model.dart';

void main() {
  group('User.fromJson', () {
    test('usa auth_user_id e hidrata contacto', () {
      final user = User.fromJson({
        'auth_user_id': 'uuid-123',
        'username': 'apicultor',
        'tipo_usuario': 'productor',
        'role': 'user',
        'status': 'active',
        'activo': true,
        'fecha_registro': '2024-01-01',
        'last_login': '2024-08-01',
        'nombre_completo': 'Ana Apicultora',
        'nombre_empresa': 'Apiario Sur',
        'correo_principal': 'ana@meliapp.cl',
        'telefono_principal': '+56911111111',
        'direccion': 'Calle 1',
        'comuna': 'Temuco',
        'region': 'Araucanía',
      });

      expect(user.id, 'uuid-123');
      expect(user.username, 'apicultor');
      expect(user.tipoUsuario, 'productor');
      expect(user.role, 'user');
      expect(user.email, 'ana@meliapp.cl');
      expect(user.telefono, '+56911111111');
      expect(user.nombreCompleto, 'Ana Apicultora');
      expect(user.comuna, 'Temuco');
      expect(user.rut, isNull);
    });

    test('hidrata rut y registro SAG si vienen del perfil', () {
      final user = User.fromJson({
        'id': 'u1',
        'username': 'erika',
        'rut': '12.345.678-9',
        'registro_sag': 'SAG-99',
      });
      expect(user.rut, '12.345.678-9');
      expect(user.registroSag, 'SAG-99');
    });

    test('cae a id si no hay auth_user_id', () {
      final user = User.fromJson({'id': 'legacy-id', 'username': 'user'});

      expect(user.id, 'legacy-id');
    });

    test('hidrata ubicaciones y redes', () {
      final user = User.fromJson({
        'id': 'u1',
        'username': 'erika',
        'ubicaciones': [
          {
            'id': 'loc-1',
            'nombre': 'Apiario Principal',
            'latitud': -38.55,
            'longitud': -71.13,
            'descripcion': 'Pichipehuenco',
          },
        ],
        'redes_sociales': {'instagram': 'https://instagram.com/erika'},
      });

      expect(user.ubicaciones, hasLength(1));
      expect(user.ubicaciones.first.nombre, 'Apiario Principal');
      expect(user.redesConValor['instagram'], contains('instagram.com'));
    });

    test('deduplica rol y tipo, y oculta username igual al nombre', () {
      final user = User.fromJson({
        'id': 'u1',
        'username': 'Erika Poblete',
        'nombre_completo': 'Erika Poblete',
        'role': 'APICULTOR',
        'tipo_usuario': 'apicultor',
        'status': 'active',
        'comuna': 'Lonquimay',
        'region': 'La Araucania',
      });

      expect(user.occupationLabel, 'Apicultor');
      expect(user.hasDistinctUsername, isFalse);
      expect(user.locationLabel, 'Lonquimay, La Araucania');
      expect(user.isActive, isTrue);
    });

    test('muestra username solo si aporta identidad distinta', () {
      final user = User.fromJson({
        'id': 'u1',
        'username': 'erika.poblete',
        'nombre_completo': 'Erika Poblete',
        'role': 'user',
        'tipo_usuario': 'productor',
      });

      expect(user.hasDistinctUsername, isTrue);
      expect(user.occupationLabel, 'Productor');
    });

    test('cae a email si no hay correo_principal', () {
      final user = User.fromJson({
        'id': '1',
        'username': 'user',
        'email': 'fallback@meliapp.cl',
      });

      expect(user.email, 'fallback@meliapp.cl');
    });
  });

  test('toJson usa las claves del backend', () {
    final json = User(
      id: 'uuid-123',
      username: 'apicultor',
      email: 'ana@meliapp.cl',
      role: 'user',
    ).toJson();

    expect(json['auth_user_id'], 'uuid-123');
    expect(json['correo_principal'], 'ana@meliapp.cl');
    expect(json['username'], 'apicultor');
    expect(json['role'], 'user');
  });
}
