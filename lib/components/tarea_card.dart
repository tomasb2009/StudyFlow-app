import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:studyflow_app/components/detalle_tarea_modal.dart';
import 'package:studyflow_app/models/tarea.dart';

class TareaCard extends StatefulWidget {
  final Tarea tarea;
  final BorderRadius borderRadius;
  final Function() onCheck;
  final bool isCompleting;
  final Function(Tarea)? onTareaEditada;

  const TareaCard({
    super.key,
    required this.tarea,
    required this.borderRadius,
    required this.onCheck,
    this.isCompleting = false,
    this.onTareaEditada,
  });

  @override
  State<TareaCard> createState() => _TareaCardState();
}

class _TareaCardState extends State<TareaCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => DetalleTareaModal.mostrar(
            context,
            widget.tarea,
            onTareaEditada: widget.onTareaEditada,
          ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: widget.tarea.color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.tarea.tipo,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.tarea.fechaEntrega,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/svg/check_icon.svg',
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  widget.isCompleting || widget.tarea.completado
                      ? Colors.blue[500]!
                      : Colors.grey[500]!,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: widget.onCheck,
            ),
          ],
        ),
      ),
    );
  }
}
