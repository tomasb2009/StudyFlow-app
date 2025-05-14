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
    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
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
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 65,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: SvgPicture.asset(
              iconAsset,
              key: ValueKey<bool>(isSelected),
              width: isSelected ? 40 : 34,
              height: isSelected ? 40 : 34,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.blue : Colors.grey,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
