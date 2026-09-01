/// Categorías self-service de Cloud (`SELF_SERVICE_TIPOS`). No incluir admin.
class SelfServiceTipo {
  final String value;
  final String label;

  const SelfServiceTipo(this.value, this.label);
}

const kSelfServiceTipos = <SelfServiceTipo>[
  SelfServiceTipo('apicultor', 'Apicultor'),
  SelfServiceTipo('prestador_servicios', 'Prestador de servicios'),
  SelfServiceTipo('proveedor', 'Proveedor'),
  SelfServiceTipo('regular', 'Usuario general'),
];
