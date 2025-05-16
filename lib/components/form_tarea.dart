import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studyflow_app/models/tarea.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormTarea extends StatefulWidget {
  final Function(Tarea) onTareaAgregada;

  const FormTarea({super.key, required this.onTareaAgregada});

  @override
  State<FormTarea> createState() => _FormTareaState();
}

class _FormTareaState extends State<FormTarea> with TickerProviderStateMixin {
  Color selectedColor = Colors.red;
  DateTime? selectedDate;
  String selectedTipo = '';
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descController = TextEditingController();

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
  late final Animation<double> _tituloOffset;
  late final Animation<double> _descripcionOffset;
  late final Animation<double> _fechaOffset;
  late final AnimationController _tipoAnim;
  late final Animation<double> _tipoOffset;

  int tituloLength = 0;
  int descripcionLength = 0;

  @override
  void initState() {
    super.initState();

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

    tituloController.addListener(() {
      setState(() {
        tituloLength = tituloController.text.length;
      });
    });

    descController.addListener(() {
      setState(() {
        descripcionLength = descController.text.length;
      });
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 6, 135, 240),
              onSurface: const Color.fromARGB(190, 0, 0, 0),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _guardarTarea() async {
    if (tituloController.text.isEmpty ||
        descController.text.isEmpty ||
        selectedDate == null ||
        selectedTipo.isEmpty) {
      if (tituloController.text.isEmpty) {
        _tituloAnim.forward(from: 0);
      }
      if (descController.text.isEmpty) {
        _descripcionAnim.forward(from: 0);
      }
      if (selectedDate == null) {
        _fechaAnim.forward(from: 0);
      }
      if (selectedTipo.isEmpty) {
        _tipoAnim.forward(from: 0);
      }
      return;
    }

    final random = Random();
    final nuevaTarea = Tarea(
      id: random.nextInt(1000000).toString(),
      titulo: tituloController.text,
      descripcion: descController.text,
      fechaEntrega:
          '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}',
      tipo: selectedTipo,
      color: selectedColor,
      completado: false,
    );

    final prefs = await SharedPreferences.getInstance();
    List<String> tareasGuardadas = prefs.getStringList('tareas') ?? [];
    tareasGuardadas.add(jsonEncode(nuevaTarea.toJson()));
    await prefs.setStringList('tareas', tareasGuardadas);

    widget.onTareaAgregada(nuevaTarea);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[500],
                    shape: const CircleBorder(),
                  ),
                ),
                GestureDetector(
                  onTap: _guardarTarea,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "CREAR TAREA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                                            margin: EdgeInsets.only(bottom: 12),
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
                    margin: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                          controller: tituloController,
                          cursorColor: Colors.grey[700],
                          enableInteractiveSelection: false,
                          cursorRadius: Radius.circular(100),
                          maxLength: 22,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(22),
                          ],
                          decoration: InputDecoration(
                            hintText: "Agrega un título...",
                            counterText: "$tituloLength/22",
                            filled: true,
                            fillColor: const Color(0xFFF4F4F4),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _descripcionAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_descripcionOffset.value, 0),
                  child: TextField(
                    controller: descController,
                    cursorColor: Colors.grey[700],
                    enableInteractiveSelection: false,
                    cursorRadius: Radius.circular(100),
                    maxLines: 4,
                    maxLength: 100,
                    inputFormatters: [LengthLimitingTextInputFormatter(100)],
                    decoration: InputDecoration(
                      hintText: "Agrega una descripción",
                      counterText: "$descripcionLength/100",
                      filled: true,
                      fillColor: const Color(0xFFF4F4F4),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
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
                              selectedDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }
}
