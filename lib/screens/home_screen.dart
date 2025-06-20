import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:studyflow_app/components/study_analitics.dart';
import 'package:studyflow_app/components/tareas_semanales.dart';
import 'package:studyflow_app/components/user_stats_card.dart';
import 'package:studyflow_app/models/tarea.dart';
import 'package:studyflow_app/models/pomodoro_stats.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Tarea> tareas = [];
  PomodoroStats? _stats;
  double _tiempoHoy = 0.0;

  String fraseInspiracional = '';
  final List<String> frases = [
    "El éxito es la suma de pequeños esfuerzos repetidos día tras día.",
    "La motivación te impulsa, el hábito te mantiene.",
    "Cada día es una nueva oportunidad para mejorar.",
    "No tienes que ser grande para comenzar, pero tienes que comenzar para ser grande.",
    "Cree en ti y todo será posible.",
  ];

  @override
  void initState() {
    super.initState();
    cargarTareas();
    FlutterForegroundTask.addTaskDataCallback(_onPomodoroData);
    seleccionarFraseInspiracional();
    _cargarStatsActualizados();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onPomodoroData);
    super.dispose();
  }

  void _onPomodoroData(Object data) {
    if (!mounted) return;

    if (data is Map &&
        data["action"] == "pomodoroStats" &&
        data["stats"] != null) {
      setState(() {
        _stats = PomodoroStats.fromJson(data["stats"]);
        _calcularTiempoHoy();
      });
    }
  }

  void seleccionarFraseInspiracional() {
    frases.shuffle();
    setState(() {
      fraseInspiracional = frases.first;
    });
  }

  Future<void> cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    final tareasJson = prefs.getStringList('tareas') ?? [];

    debugPrint("Tareas encontradas en SharedPreferences: $tareasJson");

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

  void agregarTarea(Tarea nueva) {
    setState(() {
      tareas.add(nueva);
    });
    guardarTareas();
  }

  void completarTarea(int index) {
    setState(() {
      tareas[index].completado = true;
    });
    guardarTareas();
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

  Future<void> _cargarStatsActualizados() async {
    await cargarStats();
    FlutterForegroundTask.sendDataToTask({"action": "getStats"});
  }

  Future<void> cargarStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('pomodoro_stats');
    if (statsJson != null) {
      setState(() {
        _stats = PomodoroStats.fromJson(statsJson);
        _calcularTiempoHoy();
      });
    }
  }

  void _calcularTiempoHoy() {
    if (_stats != null) {
      final hoy = DateTime.now();
      final key =
          '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      final segundosHoy = _stats!.dailySeconds[key] ?? 0;
      setState(() {
        _tiempoHoy = segundosHoy / 3600; // Convertir segundos a horas
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: const Color.fromARGB(255, 250, 250, 250),
          child: Column(
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Color.fromARGB(37, 0, 0, 0),
                      width: 0.9,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Study Flow",
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

              // Contenido desplazable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Hola Alex,",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              fraseInspiracional,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 16, bottom: 20),
                              child: Text(
                                "Progreso de hoy",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: TiempoEstudiadoCard(
                                    primerNumero: _tiempoHoy,
                                    segundoNumero: 3,
                                    texto1: "Tiempo",
                                    texto2: "Estudiado",
                                    texto3: "h",
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TiempoEstudiadoCard(
                                    primerNumero:
                                        tareas
                                            .where((t) => t.completado == true)
                                            .length,
                                    segundoNumero: tareas.length,
                                    texto1: "Tareas",
                                    texto2: "Realizadas",
                                    texto3: "",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TareasSemanales(
                          tareas: tareas,
                          onCompletarTarea: completarTarea,
                          onTareaEditada: actualizarTarea, // Agrega esta línea
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.only(top: 16, left: 24, right: 24),
                        child: StudyAnalitics(stats: _stats),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
