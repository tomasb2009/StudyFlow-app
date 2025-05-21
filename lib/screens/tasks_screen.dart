import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:studyflow_app/components/category_dropdown.dart';
import 'package:studyflow_app/components/category_selector.dart';
import 'package:studyflow_app/components/form_tarea.dart';
import 'package:studyflow_app/components/order_by_dropdown.dart';
import 'package:studyflow_app/components/tareas_totales.dart';
import 'package:studyflow_app/models/tarea.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Tarea> tareas = [];
  String? categoriaSeleccionada;
  String periodoSeleccionado = 'Semana';
  String ordenSeleccionado = 'Más Próxima';

  @override
  void initState() {
    super.initState();
    cargarTareas();
  }

  Future<void> cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final tareasJson = prefs.getStringList('tareas') ?? [];

    setState(() {
      tareas =
          tareasJson
              .map((tareaStr) => Tarea.fromJson(json.decode(tareaStr)))
              .toList();
    });
  }

  Future<void> guardarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final tareasJson = tareas.map((t) => json.encode(t.toJson())).toList();
    await prefs.setStringList('tareas', tareasJson);
  }

  void agregarTarea(Tarea nuevaTarea) {
    setState(() {
      tareas.add(nuevaTarea);
    });
    guardarTareas();
  }

  void completarTarea(int index) {
    final tareaFiltrada = tareasFiltradas[index];
    final indiceReal = tareas.indexWhere((t) => t.id == tareaFiltrada.id);

    if (indiceReal != -1) {
      setState(() {
        tareas[indiceReal].completado = !tareas[indiceReal].completado;
        // Reordenar: las tareas completadas primero
        tareas.sort((a, b) {
          if (a.completado && !b.completado) return -1;
          if (!a.completado && b.completado) return 1;
          return 0;
        });
      });
      guardarTareas();
    }
  }

  void eliminarTarea(String id) async {
    setState(() {
      tareas.removeWhere((t) => t.id == id);
    });
    await guardarTareas();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarea eliminada'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void actualizarTarea(Tarea tareaActualizada) {
    final index = tareas.indexWhere((t) => t.id == tareaActualizada.id);
    if (index != -1) {
      setState(() {
        tareas[index] = tareaActualizada;
      });
      guardarTareas();
    }
  }

  List<Tarea> get tareasFiltradas {
    final hoy = DateTime.now();
    final fechaLimite = hoy.add(const Duration(days: 7));

    var tareasFiltradas =
        tareas.where((tarea) {
          // Filtro por completado
          if (periodoSeleccionado == 'Completado') {
            return tarea.completado;
          } else if (tarea.completado) {
            return false;
          }

          // Filtro por período
          final fechaTarea = _parsearFecha(tarea.fechaEntrega);
          bool cumplePeriodo = true;

          if (periodoSeleccionado == 'Semana') {
            cumplePeriodo =
                fechaTarea.isAfter(hoy.subtract(const Duration(days: 1))) &&
                fechaTarea.isBefore(fechaLimite);
          } else if (periodoSeleccionado == 'Proximo') {
            cumplePeriodo = fechaTarea.isAfter(fechaLimite);
          }

          // Filtro por categoría
          final cumpleCategoria =
              categoriaSeleccionada == null ||
              tarea.tipo == categoriaSeleccionada;

          return cumplePeriodo && cumpleCategoria;
        }).toList();

    // Ordenar las tareas según la selección
    tareasFiltradas.sort((a, b) {
      final fechaA = _parsearFecha(a.fechaEntrega);
      final fechaB = _parsearFecha(b.fechaEntrega);

      return ordenSeleccionado == 'Más Próxima'
          ? fechaA.compareTo(fechaB)
          : fechaB.compareTo(fechaA);
    });

    return tareasFiltradas;
  }

  List<Tarea> get tareasIncompletasVencidas {
    final hoy = DateTime.now();
    return tareas.where((tarea) {
      final fechaTarea = _parsearFecha(tarea.fechaEntrega);
      return !tarea.completado && fechaTarea.isBefore(hoy);
    }).toList();
  }

  DateTime _parsearFecha(String fechaStr) {
    final partes = fechaStr.split('/');
    final dia = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    return DateTime(DateTime.now().year, mes, dia);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        body: Stack(
          children: [
            Column(
              children: [
                // Encabezado
                Container(
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 16,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: const Color.fromARGB(37, 0, 0, 0),
                        width: 0.9,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Tareas",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/svg/notification_icon.svg',
                          width: 26,
                          height: 26,
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/svg/settings_icon.svg',
                          width: 26,
                          height: 26,
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xF0E8F1FF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: SvgPicture.asset(
                            'assets/svg/user_icon.svg',
                            width: 26,
                            height: 26,
                            colorFilter: const ColorFilter.mode(
                              Colors.blue,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CategorySelector(
                        onPeriodoChanged: (periodo) {
                          setState(() {
                            periodoSeleccionado = periodo;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CategoriaDropdown(
                            onCategoriaChanged: (categoria) {
                              setState(() {
                                categoriaSeleccionada = categoria;
                              });
                            },
                          ),
                          OrderByDropdown(
                            onOrderChanged: (orden) {
                              setState(() {
                                ordenSeleccionado = orden;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TareasTotales(
                        tareas: tareasFiltradas,
                        tareasIncompletas:
                            periodoSeleccionado == 'Completado'
                                ? tareasIncompletasVencidas
                                : [],
                        onCompletarTarea: (tarea) {
                          final indexReal = tareas.indexWhere(
                            (t) => t.id == tarea.id,
                          );
                          if (indexReal != -1) {
                            setState(() {
                              tareas[indexReal].completado =
                                  !tareas[indexReal].completado;
                              tareas.sort((a, b) {
                                if (!a.completado && b.completado) return -1;
                                if (a.completado && !b.completado) return 1;
                                return 0;
                              });
                            });
                            guardarTareas();
                          }
                        },
                        onEliminarTarea: eliminarTarea,
                        onTareaEditada: actualizarTarea,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder:
                        (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 24,
                              top: 12,
                              left: 12,
                              right: 12,
                            ),
                            child: FormTarea(onTareaAgregada: agregarTarea),
                          ),
                        ),
                  );
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 36, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
