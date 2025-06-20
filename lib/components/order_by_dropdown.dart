import 'package:flutter/material.dart';

class OrderByDropdown extends StatefulWidget {
  final Function(String) onOrderChanged;

  const OrderByDropdown({super.key, required this.onOrderChanged});

  @override
  State<OrderByDropdown> createState() => _OrderByDropdownState();
}

class _OrderByDropdownState extends State<OrderByDropdown> {
  String? selectedValue;

  final List<String> opciones = ["Más Próxima", "Más Lejana"];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          hint: const Text(
            'Ordenar por',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(15),
          itemHeight: 48,
          items:
              opciones.map((String valor) {
                return DropdownMenuItem<String>(
                  value: valor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(valor),
                  ),
                );
              }).toList(),
          onChanged: (String? nuevoValor) {
            setState(() {
              selectedValue = nuevoValor;
            });
            widget.onOrderChanged(nuevoValor ?? "Más Próxima");
          },
        ),
      ),
    );
  }
}
