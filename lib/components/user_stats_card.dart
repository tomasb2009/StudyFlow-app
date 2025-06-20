import 'package:flutter/material.dart';

class TiempoEstudiadoCard extends StatelessWidget {
  final num primerNumero;
  final num segundoNumero;
  final String texto1;
  final String texto2;
  final String? texto3;

  const TiempoEstudiadoCard({
    super.key,
    required this.primerNumero,
    required this.segundoNumero,
    required this.texto1,
    required this.texto2,
    required this.texto3,
  });

  @override
  Widget build(BuildContext context) {
    // Calculamos el progreso, asegurándonos de no dividir por cero
    final double progreso =
        segundoNumero == 0
            ? 0.0
            : (primerNumero / segundoNumero).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.blue, size: 40),

              SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto1,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    texto2,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "${texto3 != "" ? primerNumero.toStringAsFixed(1) : primerNumero.toStringAsFixed(0)}${texto3 ?? ''}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      ' / ',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${texto3 != "" ? segundoNumero.toStringAsFixed(0) : segundoNumero.toStringAsFixed(0)}${texto3 ?? ''}",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      segundoNumero == 0
                          ? Colors.grey
                          : Colors
                              .blue, // Cambiar el color si el segundo número es 0
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
