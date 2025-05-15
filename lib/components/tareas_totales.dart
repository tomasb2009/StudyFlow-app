import 'package:flutter/material.dart';
import 'package:studyflow_app/components/tarea_card_2.dart';
import 'package:studyflow_app/models/tarea.dart';

class TareasTotales extends StatefulWidget {
  final List<Tarea> tareas;
  final Function(int) onCompletarTarea;
  final Function(String) onEliminarTarea;
  final Function(Tarea)? onTareaEditada; // Agrega esta línea

  const TareasTotales({
    super.key,
    required this.tareas,
    required this.onCompletarTarea,
    required this.onEliminarTarea,
    required this.onTareaEditada,
  });

  @override
  State<TareasTotales> createState() => _TareasTotalesState();
}

class _TareasTotalesState extends State<TareasTotales> {
  String? _completingTaskId;

  void _confirmarCompletar(BuildContext context, int index) {
    final tarea = widget.tareas[index];

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final bool completado = tarea.completado;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Row(
            children: [
              Icon(
                completado ? Icons.check_circle : Icons.check_circle,
                color: completado ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                completado ? 'Desmarcar tarea' : 'Completar tarea',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: completado ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ),
          content: Text(
            completado
                ? '¿Estás seguro de que quieres desmarcar esta tarea como completada?'
                : '¿Estás seguro de que quieres marcar esta tarea como completada?',
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
                backgroundColor: completado ? Colors.red : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _completingTaskId = tarea.id;
                });

                Future.delayed(const Duration(milliseconds: 750), () {
                  widget.onCompletarTarea(index);
                  setState(() {
                    _completingTaskId = null;
                  });
                });
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

  @override
  Widget build(BuildContext context) {
    final alturaDisponible = MediaQuery.of(context).size.height - 406;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: alturaDisponible),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Column(
            children: List.generate(widget.tareas.length, (index) {
              final tarea = widget.tareas[index];
              return TareaCard2(
                key: ValueKey(tarea.id),
                tarea: tarea,
                isCompleting: _completingTaskId == tarea.id,
                onDismissed: (id) => widget.onEliminarTarea(id),
                onCheck: () => _confirmarCompletar(context, index),
                onTareaEditada: widget.onTareaEditada, // Pasa el callback
              );
            }),
          ),
        ),
      ),
    );
  }
}
