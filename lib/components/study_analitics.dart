import 'package:flutter/material.dart';

class StudyAnalitics extends StatefulWidget {
  const StudyAnalitics({super.key});

  @override
  State<StudyAnalitics> createState() => _StudyAnaliticsState();
}

class _StudyAnaliticsState extends State<StudyAnalitics> {
  final List<double> data = [1.0, 2.5, 0.5, 3.0, 2.8, 3.5, 3.5];
  final List<String> dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

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
                  _ResumenItem(valor: "13.5h", etiqueta: "Tiempo Total"),
                  _VerticalDivider(),
                  _ResumenItem(valor: "2.2h", etiqueta: "Prom. Diario"),
                  _VerticalDivider(),
                  _ResumenItem(valor: "3.5h", etiqueta: "Mejor Día"),
                ],
              ),
              SizedBox(height: 16),
              _BarChart(),
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
  final List<double> data = [1.0, 2.5, 0.5, 3.0, 2.8, 3.5, 4];
  final List<String> dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
  final double maxHeight = 145;

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
                height: maxHeight * (value / 4), // asumiendo 4h como máx.
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
