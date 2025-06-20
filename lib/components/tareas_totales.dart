import 'package:flutter/material.dart';
import 'package:studyflow_app/components/tarea_card_2.dart';
import 'package:studyflow_app/models/tarea.dart';

class TareasTotales extends StatefulWidget {
  final List<Tarea> tareas;
  final List<Tarea> tareasIncompletas;

  // Ahora onCompletarTarea recibe la tarea directamente
  final Function(Tarea) onCompletarTarea;
  final Function(String) onEliminarTarea;
  final Function(Tarea)? onTareaEditada;

  const TareasTotales({
    super.key,
    required this.tareas,
    required this.onCompletarTarea,
    required this.onEliminarTarea,
    required this.onTareaEditada,
    required this.tareasIncompletas,
  });

  @override
  State<TareasTotales> createState() => _TareasTotalesState();
}

class _TareasTotalesState extends State<TareasTotales> {
  String? _completingTaskId;

  void _confirmarCompletar(BuildContext context, Tarea tarea) {
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
                  widget.onCompletarTarea(
                    tarea,
                  ); // Ahora pasamos la tarea directamente
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

    // Filtramos solo las tareas incompletas vencidas (fecha anterior a hoy)
    final tareasIncompletasVencidas =
        widget.tareasIncompletas.where((tarea) {
          final hoy = DateTime.now();

          // Parsear el string "dd/MM" sumando el año actual
          final partes = tarea.fechaEntrega.split('/');
          if (partes.length != 2) return false;

          final dia = int.tryParse(partes[0]);
          final mes = int.tryParse(partes[1]);
          if (dia == null || mes == null) return false;

          final fechaTarea = DateTime(hoy.year, mes, dia);
          final fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);

          return fechaTarea.isBefore(fechaHoy);
        }).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: alturaDisponible),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(widget.tareas.length, (index) {
                final tarea = widget.tareas[index];
                return TareaCard2(
                  key: ValueKey(tarea.id),
                  tarea: tarea,
                  isCompleting: _completingTaskId == tarea.id,
                  onDismissed: (id) => widget.onEliminarTarea(id),
                  onCheck: () => _confirmarCompletar(context, tarea),
                  onTareaEditada: widget.onTareaEditada,
                );
              }),
              if (tareasIncompletasVencidas.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 1.3, color: Colors.black54),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tareas Incompletas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(height: 1.3, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...tareasIncompletasVencidas.map((tarea) {
                  return TareaCard2(
                    key: ValueKey('incompleta_${tarea.id}'),
                    tarea: tarea,
                    color: const Color.fromARGB(150, 255, 0, 0),
                    isCompleting: false,
                    onDismissed: (id) => widget.onEliminarTarea(id),
                    onCheck: () => _confirmarCompletar(context, tarea),
                    onTareaEditada: widget.onTareaEditada,
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
