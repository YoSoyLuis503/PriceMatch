import 'package:flutter/material.dart';

class FavoritosPage extends StatelessWidget {
const FavoritosPage({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Mi Lista de Compras'),
),
body: const Center(
child: Text(
'Aún no tienes productos guardados',
style: TextStyle(
fontSize: 18,
),
),
),
);
}
}
