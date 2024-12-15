import 'package:flutter/cupertino.dart';

class BounceButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const BounceButton({super.key, required this.onTap, required this.child});

  @override
  _BounceButtonState createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
  }

  void _onTap() {
    _controller.reverse().then((_) {
      _controller.forward();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedScale(
        scale: _controller.value,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
