import 'package:flutter/material.dart';

class CategoriaDropdown extends StatefulWidget {
  final Function(String?) onCategoriaChanged;

  const CategoriaDropdown({super.key, required this.onCategoriaChanged});

  @override
  State<CategoriaDropdown> createState() => _CategoriaDropdownState();
}

class _CategoriaDropdownState extends State<CategoriaDropdown> {
  String? selectedValue;

  final List<String> opciones = ["Tarea", "Evaluación", "Reunión", "Proyecto"];

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
          hint: Text(
            "Categorías",
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
            widget.onCategoriaChanged(nuevoValor);
          },
        ),
      ),
    );
  }
}
