import 'dart:async';
import '/login/login.dart';
import 'package:flutter/material.dart';

// CLIPPER //

////// Clipper Class for Upper Container or Sign Up //////////

class CustomUpClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var h = size.height;
    var w = size.width;
    final path = Path();
    path.lineTo(0, h);
    // path.lineTo(w, h);
    path.quadraticBezierTo(w * 0.5, h - 110, w, h);
    path.lineTo(w, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

////// Clipper Class for Bottom Sheet or Login //////////

class CustomBottomClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var h = size.height;
    var w = size.width;
    final path = Path();
    path.moveTo(0, 60);
    path.lineTo(0, h);
    path.lineTo(w, h);
    path.lineTo(w, 60);
    path.quadraticBezierTo(w * 0.5, -60, 0, 60);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}

// FIELD //

class FieldWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool pass;
  final TextEditingController controlador;
  final FocusNode? node;
  final TextInputType keyboard;
  const FieldWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.pass,
    required this.controlador,
    required this.node,
    required this.keyboard,
  });

  @override
  FieldState createState() => FieldState();
}

class FieldState extends State<FieldWidget> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(25)),
      child: TextFormField(
        keyboardType: widget.keyboard,
        controller: widget.controlador,
        focusNode: widget.node,
        cursorColor: const Color.fromARGB(255, 255, 255, 255),
        obscureText: widget.pass ? _obscureText : false,
        onFieldSubmitted: (value) {
          if (widget.controlador == mailController) {
            passNode.requestFocus();
          }
        },
        decoration: InputDecoration(
            focusColor: const Color.fromARGB(255, 189, 189, 189),
            hoverColor: const Color.fromARGB(255, 189, 189, 189),
            hintText: widget.title,
            border: InputBorder.none,
            prefixIcon: Icon(
              widget.icon,
              color: Colors.grey,
            ),
            suffixIcon: widget.pass
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                      size: 25,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null),
      ),
    );
  }
}

// ANIMATIONS //

class ShowUpAnimation extends StatefulWidget {
  final Widget child;
  final int? delay;

  const ShowUpAnimation({super.key, required this.child, this.delay});

  @override
  ShowUpAnimationState createState() => ShowUpAnimationState();
}

class ShowUpAnimationState extends State<ShowUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _animOffset;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    final curve =
        CurvedAnimation(curve: Curves.decelerate, parent: _animController);
    _animOffset =
        Tween<Offset>(begin: const Offset(0.0, 0.35), end: Offset.zero)
            .animate(curve);

    if (widget.delay == null) {
      _animController.forward();
    } else {
      _timer = Timer(Duration(milliseconds: widget.delay!), () {
        _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animController.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: _animOffset,
        child: widget.child,
      ),
    );
  }
}

// TEXT //
class TextUtil extends StatelessWidget {
  final String text;
  final Color? color;
  final double? size;
  final bool? weight;
  const TextUtil(
      {super.key, required this.text, this.size, this.color, this.weight});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: color ?? Colors.white,
          fontSize: size ?? 18,
          fontWeight: weight == null ? FontWeight.w400 : FontWeight.w700,
          fontFamily: "Poppins"),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
