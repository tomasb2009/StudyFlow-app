import 'package:flutter/material.dart';
import 'dart:math';
import '../models/pomodoro_stats.dart';

class StudyAnalitics extends StatefulWidget {
  final PomodoroStats? stats;

  const StudyAnalitics({super.key, this.stats});

  @override
  State<StudyAnalitics> createState() => _StudyAnaliticsState();
}

class _StudyAnaliticsState extends State<StudyAnalitics> {
  final List<String> dias = ['Dom', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab'];

  List<double> get data {
    if (widget.stats == null) {
      return List.filled(7, 0.0);
    }

    final last7Days = widget.stats!.getLast7Days();
    final List<double> result = List.filled(7, 0.0);

    // Obtener el día de la semana actual (1=Lunes, 7=Domingo)
    final hoy = DateTime.now();

    // Mapear los datos según el día de la semana (comenzando con domingo)
    for (int i = 0; i < 7; i++) {
      final day = hoy.subtract(
        Duration(days: 6 - i),
      ); // Desde hace 6 días hasta hoy
      final key =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final segundos = last7Days[key] ?? 0;

      // Calcular la posición en el array (0=Domingo, 1=Lunes, ..., 6=Sábado)
      final diaSemana = day.weekday; // 1=Lunes, 2=Martes, ..., 7=Domingo
      final posicion =
          diaSemana == 7 ? 0 : diaSemana; // Domingo=0, Lunes=1, ..., Sábado=6

      result[posicion] = segundos / 3600; // Convertir segundos a horas
    }

    return result;
  }

  double get tiempoTotal => data.fold(0.0, (sum, value) => sum + value);
  double get promedioDiario => data.isEmpty ? 0.0 : tiempoTotal / data.length;
  double get mejorDia =>
      data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            "Análisis de estudio",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 275,
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ResumenItem(
                    valor: "${tiempoTotal.toStringAsFixed(1)}h",
                    etiqueta: "Tiempo Total",
                  ),
                  _VerticalDivider(),
                  _ResumenItem(
                    valor: "${promedioDiario.toStringAsFixed(1)}h",
                    etiqueta: "Prom. Diario",
                  ),
                  _VerticalDivider(),
                  _ResumenItem(
                    valor: "${mejorDia.toStringAsFixed(1)}h",
                    etiqueta: "Mejor Día",
                  ),
                ],
              ),
              SizedBox(height: 16),
              _BarChart(data: data),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _ResumenItem({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 2, color: Colors.grey.shade300);
  }
}

class _BarChart extends StatelessWidget {
  final List<double> data;
  final List<String> dias = ['Dom', 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab'];
  final double maxHeight = 145;
  final double maxHours = 3.0; // Máximo de 3 horas

  _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight + 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final value = data[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height:
                    maxHeight *
                    (min(value, maxHours) / maxHours), // Limitar a 3h máximo
                width: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D9CEC),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dias[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
