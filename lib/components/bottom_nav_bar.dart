import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double itemWidth = width / 5;

    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            bottom: 8,
            left: itemWidth * currentIndex + itemWidth * 0.3,
            child: Container(
              width: itemWidth * 0.4,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Íconos con tamaño dinámico
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                iconAsset: 'assets/svg/home_icon.svg',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                iconAsset: 'assets/svg/calendar_icon.svg',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                iconAsset: 'assets/svg/clock_icon.svg',
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                iconAsset: 'assets/svg/book_icon.svg',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                iconAsset: 'assets/svg/gemini_icon.svg',
                index: 4,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconAsset;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _NavItem({
    required this.iconAsset,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  bool get isSelected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final double selectedSize = 36;
    final double defaultSize = 32;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        height: 65,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isSelected ? selectedSize : defaultSize,
            height: isSelected ? selectedSize : defaultSize,
            child: SvgPicture.asset(
              iconAsset,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.blueAccent : Colors.grey.shade400,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
