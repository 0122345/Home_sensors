import 'package:flutter/material.dart';
 
class AppBarNav extends StatefulWidget {
  const AppBarNav({super.key});

  @override
  State<AppBarNav> createState() => _AppBarNavState();
}


class _AppBarNavState extends State<AppBarNav> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      leading: GestureDetector(
        onTap: () {},
        child: Icon(
          Icons.menu,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      title: Center(
        child: Text(
          'Home of sensors',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          color: Theme.of(context).textTheme.bodyLarge?.color,
          onPressed: () {},
        ),
      ],
    );
  }
}
