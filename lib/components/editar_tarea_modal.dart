import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studyflow_app/models/tarea.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditarTareaModal extends StatefulWidget {
  final Tarea tarea;
  final Function(Tarea)? onTareaEditada;

  const EditarTareaModal({super.key, required this.tarea, this.onTareaEditada});

  static void mostrar(
    BuildContext context,
    Tarea tarea, {
    Function(Tarea)? onTareaEditada,
  }) {
    showDialog(
      context: context,
      builder:
          (context) =>
              EditarTareaModal(tarea: tarea, onTareaEditada: onTareaEditada),
    );
  }

  @override
  State<EditarTareaModal> createState() => _EditarTareaModalState();
}

class _EditarTareaModalState extends State<EditarTareaModal>
    with TickerProviderStateMixin {
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  DateTime? selectedDate;
  String selectedTipo = '';
  Color selectedColor = Colors.red;

  final List<Color> coloresDisponibles = [
    Colors.red,
    Colors.deepOrange,
    Colors.orange,
    Colors.amber,
    Colors.yellow,
    Colors.lime,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.pinkAccent,
  ];

  final List<String> tipos = ["Tarea", "Evaluación", "Reunión", "Proyecto"];

  late final AnimationController _tituloAnim;
  late final AnimationController _descripcionAnim;
  late final AnimationController _fechaAnim;
  late final AnimationController _tipoAnim;
  late final Animation<double> _tituloOffset;
  late final Animation<double> _descripcionOffset;
  late final Animation<double> _fechaOffset;
  late final Animation<double> _tipoOffset;

  int tituloLength = 0;
  int descripcionLength = 0;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con los valores actuales de la tarea
    _tituloController = TextEditingController(text: widget.tarea.titulo);
    _descripcionController = TextEditingController(
      text: widget.tarea.descripcion,
    );
    selectedTipo = widget.tarea.tipo;
    selectedColor = widget.tarea.color;

    // Inicializar contadores con la longitud actual del texto
    tituloLength = widget.tarea.titulo.length;
    descripcionLength = widget.tarea.descripcion.length;

    // Parsear la fecha de la tarea si existe
    if (widget.tarea.fechaEntrega.isNotEmpty) {
      final parts = widget.tarea.fechaEntrega.split('/');
      if (parts.length == 2) {
        selectedDate = DateTime(
          DateTime.now().year,
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    }

    // Configurar animaciones
    _tituloAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _descripcionAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fechaAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tipoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final shakeTween = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]);

    _tituloOffset = shakeTween.animate(_tituloAnim);
    _descripcionOffset = shakeTween.animate(_descripcionAnim);
    _fechaOffset = shakeTween.animate(_fechaAnim);
    _tipoOffset = shakeTween.animate(_tipoAnim);

    // Listeners para actualizar el conteo de caracteres
    _tituloController.addListener(() {
      setState(() {
        tituloLength = _tituloController.text.length;
      });
    });

    _descripcionController.addListener(() {
      setState(() {
        descripcionLength = _descripcionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _tituloAnim.dispose();
    _descripcionAnim.dispose();
    _fechaAnim.dispose();
    _tipoAnim.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime hoy = DateTime.now();
    final DateTime initial =
        (selectedDate != null && selectedDate!.isAfter(hoy))
            ? selectedDate!
            : hoy;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: hoy,
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 6, 135, 240),
              onSurface: Color.fromARGB(190, 0, 0, 0),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (_tituloController.text.isEmpty ||
        _descripcionController.text.isEmpty ||
        selectedDate == null ||
        selectedTipo.isEmpty) {
      if (_tituloController.text.isEmpty) _tituloAnim.forward(from: 0);
      if (_descripcionController.text.isEmpty)
        _descripcionAnim.forward(from: 0);
      if (selectedDate == null) _fechaAnim.forward(from: 0);
      if (selectedTipo.isEmpty) _tipoAnim.forward(from: 0);
      return;
    }

    // Crear tarea actualizada manteniendo el mismo ID y estado de completado
    final tareaActualizada = Tarea(
      id: widget.tarea.id,
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      fechaEntrega:
          '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}',
      tipo: selectedTipo,
      color: selectedColor,
      completado: widget.tarea.completado,
    );

    // Actualizar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    List<String> tareasGuardadas = prefs.getStringList('tareas') ?? [];

    // Buscar la tarea existente por su ID
    final index = tareasGuardadas.indexWhere((tareaJson) {
      final tareaMap = jsonDecode(tareaJson);
      return tareaMap['id'] == widget.tarea.id;
    });

    if (index != -1) {
      // Reemplazar la tarea antigua con la actualizada
      tareasGuardadas[index] = jsonEncode(tareaActualizada.toJson());
      await prefs.setStringList('tareas', tareasGuardadas);

      // Notificar que la tarea fue editada
      if (widget.onTareaEditada != null) {
        widget.onTareaEditada!(tareaActualizada);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar Tarea',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),

              // Selector de color y campo de título
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap:
                        () => showModalBottomSheet(
                          backgroundColor: Colors.white,
                          context: context,
                          builder:
                              (_) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 16,
                                    bottom: 4,
                                    right: 16,
                                    left: 16,
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    children:
                                        coloresDisponibles.map((color) {
                                          return GestureDetector(
                                            onTap: () {
                                              setState(
                                                () => selectedColor = color,
                                              );
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    const BorderRadius.all(
                                                      Radius.circular(8),
                                                    ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                        ),
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _tituloAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_tituloOffset.value, 0),
                          child: TextField(
                            controller: _tituloController,
                            cursorColor: Colors.grey[700],
                            enableInteractiveSelection: false,
                            cursorRadius: Radius.circular(100),
                            style: const TextStyle(color: Colors.black),
                            maxLength: 22,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(22),
                            ],
                            decoration: InputDecoration(
                              hintText: "Agrega un título...",
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              counterText: "$tituloLength/22",
                              filled: true,
                              fillColor: const Color(0xFFF4F4F4),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Descripción
              AnimatedBuilder(
                animation: _descripcionAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_descripcionOffset.value, 0),
                    child: TextField(
                      controller: _descripcionController,
                      cursorColor: Colors.grey[700],
                      enableInteractiveSelection: false,
                      cursorRadius: Radius.circular(100),
                      style: const TextStyle(color: Colors.black),
                      maxLines: 3,
                      maxLength: 100,
                      inputFormatters: [LengthLimitingTextInputFormatter(100)],
                      decoration: InputDecoration(
                        hintText: "Agrega una descripción",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        counterText: "$descripcionLength/100",
                        filled: true,
                        fillColor: const Color(0xFFF4F4F4),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Fecha
              AnimatedBuilder(
                animation: _fechaAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_fechaOffset.value, 0),
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedDate == null
                              ? "Seleccionar fecha"
                              : "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}",
                          style: TextStyle(
                            color:
                                selectedDate == null
                                    ? Colors.grey
                                    : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tipo
              AnimatedBuilder(
                animation: _tipoAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_tipoOffset.value, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedTipo.isEmpty ? null : selectedTipo,
                        dropdownColor: Colors.white,
                        elevation: 2,
                        hint: const Text("Seleccionar tipo"),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items:
                            tipos.map((String tipo) {
                              return DropdownMenuItem<String>(
                                value: tipo,
                                child: Text(tipo),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTipo = value!;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
