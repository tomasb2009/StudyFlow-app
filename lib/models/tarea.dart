import 'dart:ui';

class Tarea {
  final String id;
  String titulo;
  String descripcion;
  String fechaEntrega;
  bool completado;
  String tipo;
  Color color;

  Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fechaEntrega,
    required this.tipo,
    this.completado = false,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'descripcion': descripcion,
    'fechaEntrega': fechaEntrega,
    'completado': completado,
    'tipo': tipo,
    'color': color.value.toString(),
  };

  factory Tarea.fromJson(Map<String, dynamic> json) => Tarea(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    titulo: json['titulo'] ?? '',
    descripcion: json['descripcion'] ?? '',
    fechaEntrega: json['fechaEntrega'] ?? '',
    completado: json['completado'] ?? false,
    tipo: json['tipo'] ?? '',
    color: Color(int.tryParse(json['color'] ?? '') ?? 0xFFFFFFFF),
  );
}
