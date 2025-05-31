class Anunciomodel {
  String id;
  String nombre;
  String descripcion;
  String image;

  Anunciomodel({
    required this.id,
    required this.nombre,
    required this. descripcion,
    required this.image
  });

  factory Anunciomodel.fromMap(Map<String, dynamic> map, String id) {
    return Anunciomodel(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      image: map['image'] ?? ''
    );
  }
}