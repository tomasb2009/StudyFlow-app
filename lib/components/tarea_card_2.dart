import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:studyflow_app/models/tarea.dart';
import 'detalle_tarea_modal.dart';

class TareaCard2 extends StatefulWidget {
  final Tarea tarea;
  final Color? color;
  final Function(String) onDismissed;
  final Function() onCheck;
  final bool isCompleting;
  final Function(Tarea)? onTareaEditada;

  const TareaCard2({
    super.key,
    required this.tarea,
    required this.onDismissed,
    required this.onCheck,
    this.isCompleting = false,
    this.onTareaEditada,
    this.color,
  });

  @override
  State<TareaCard2> createState() => _TareaCard2State();
}

class _TareaCard2State extends State<TareaCard2> {
  Future<bool?> _confirmarEliminacion(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Eliminar tarea',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres eliminar esta tarea?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
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
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Eliminar',
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
    return Dismissible(
      key: ValueKey(widget.tarea.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmarEliminacion(context),
      onDismissed: (_) => widget.onDismissed(widget.tarea.id),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () {
          DetalleTareaModal.mostrar(
            context,
            widget.tarea,
            onTareaEditada: widget.onTareaEditada, // Pasa el callback
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 250, 250, 250),
            border: Border(
              bottom: BorderSide(
                color: const Color.fromARGB(37, 0, 0, 0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/svg/check_icon.svg',
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(
                    widget.isCompleting || widget.tarea.completado
                        ? Colors.blue[500]!
                        : Colors.grey[500]!,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: widget.isCompleting ? null : widget.onCheck,
              ),

              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tarea.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: widget.color ?? Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.tarea.fechaEntrega.toString(),
                          style: TextStyle(
                            color: widget.color ?? Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 22,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F7FE),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            widget.tarea.tipo,
                            style: const TextStyle(
                              color: Color(0xFF64A1ED),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: widget.tarea.color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
