import 'package:flutter/material.dart';
import 'package:studyflow_app/components/tarea_card.dart';
import 'package:studyflow_app/models/tarea.dart';

class TareasSemanales extends StatefulWidget {
  final List<Tarea> tareas;
  final Function(int) onCompletarTarea;
  final Function(Tarea)? onTareaEditada;

  const TareasSemanales({
    super.key,
    required this.tareas,
    required this.onCompletarTarea,
    this.onTareaEditada,
  });

  @override
  State<TareasSemanales> createState() => _TareasSemanalesState();
}

class _TareasSemanalesState extends State<TareasSemanales> {
  String? _completingTaskId; // Para rastrear qué tarea se está completando

  void _confirmarAccion({
    required BuildContext context,
    required String titulo,
    required String contenido,
    required VoidCallback onConfirmar,
    required Color color,
    required IconData icono,
    required String taskId, // Nuevo parámetro para identificar la tarea
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Row(
            children: [
              Icon(icono, color: color),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          content: Text(
            contenido,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                onConfirmar();
              },
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  DateTime? _parseFecha(String fechaStr) {
    try {
      final partes = fechaStr.split('/');
      if (partes.length != 2) return null;

      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final anio = DateTime.now().year;

      if (dia == null || mes == null) return null;

      return DateTime(anio, mes, dia);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final finSemana = inicioHoy.add(const Duration(days: 7));

    final tareasFiltradas =
        widget.tareas.where((tarea) {
          final fecha = _parseFecha(tarea.fechaEntrega);
          return fecha != null &&
              !tarea.completado &&
              !fecha.isBefore(inicioHoy) &&
              !fecha.isAfter(finSemana);
        }).toList();

    tareasFiltradas.sort((a, b) {
      final fechaA = _parseFecha(a.fechaEntrega);
      final fechaB = _parseFecha(b.fechaEntrega);
      if (fechaA == null || fechaB == null) return 0;
      return fechaA.compareTo(fechaB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Tareas Semanales",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 350),
          child:
              tareasFiltradas.isEmpty
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "🎉 ¡Sin tareas esta semana! 🎉",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  )
                  : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Column(
                        children: List.generate(tareasFiltradas.length, (
                          index,
                        ) {
                          final tarea = tareasFiltradas[index];
                          final isFirst = index == 0;
                          final isLast = index == tareasFiltradas.length - 1;

                          BorderRadius borderRadius;
                          if (isFirst && isLast) {
                            borderRadius = BorderRadius.circular(22);
                          } else if (isFirst) {
                            borderRadius = const BorderRadius.vertical(
                              top: Radius.circular(22),
                            );
                          } else if (isLast) {
                            borderRadius = const BorderRadius.vertical(
                              bottom: Radius.circular(22),
                            );
                          } else {
                            borderRadius = BorderRadius.zero;
                          }

                          return TareaCard(
                            tarea: tarea,
                            borderRadius: borderRadius,
                            isCompleting: _completingTaskId == tarea.id,
                            onCheck: () {
                              _confirmarAccion(
                                context: context,
                                titulo: 'Completar tarea',
                                contenido:
                                    '¿Estás seguro de que quieres marcar esta tarea como completada?',
                                onConfirmar: () {
                                  setState(() {
                                    _completingTaskId = tarea.id;
                                  });

                                  Future.delayed(
                                    const Duration(milliseconds: 750),
                                    () {
                                      final originalIndex = widget.tareas
                                          .indexOf(tarea);
                                      widget.onCompletarTarea(originalIndex);
                                      setState(() {
                                        _completingTaskId = null;
                                      });
                                    },
                                  );
                                },
                                color: Colors.blue,
                                icono: Icons.check_circle,
                                taskId: tarea.id,
                              );
                            },
                            onTareaEditada: widget.onTareaEditada,
                          );
                        }),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
}
