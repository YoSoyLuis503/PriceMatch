import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa dotenv
import 'package:pricematch/pages/search_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar el archivo .env primero
  await dotenv.load(fileName: ".env");

  // 2. Leer las llaves de dotenv
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_KEY'] ?? '';

  // Verificar que las llaves se cargaron
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Error: Las llaves de Supabase no se encontraron en el archivo .env');
  }

  // 3. Inicializar Supabase con las llaves seguras
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

// Cliente global
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la banda de debug
      title: 'PriceMatch',
      theme: ThemeData(
        // Color base del carrito (un morado azulado)
        primarySwatch: Colors.deepPurple,
        // Usamos Material 3 para un look más moderno
        useMaterial3: true,
      ),
      home: const PriceMatchHomePage(),
    );
  }
}

class PriceMatchHomePage extends StatelessWidget {
  const PriceMatchHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos los colores exactos de tu logo para usarlos como acentos
    const Color logoPurple = Color(0xFF676AF2); // Morado/azul del carrito
    const Color logoRed = Color(0xFFFF4842);    // Rojo de 'Match'

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- EL LOGO DE TU IMAGEN ---
              Expanded(
                flex: 4,
                child: Center(
                  child: Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/logo_pricematch.jpeg', // Tu logo aquí
                      fit: BoxFit.contain,
                      width: 250,
                    ),
                  ),
                ),
              ),

              // --- TEXTO DE BIENVENIDA ---
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(text: '¡Encuentra el mejor\n'),
                          TextSpan(
                            text: 'precio',
                            style: TextStyle(color: logoPurple), // Color del carrito
                          ),
                          TextSpan(text: ' en '),
                          TextSpan(
                            text: 'El Salvador',
                            style: TextStyle(color: logoRed), // Acento rojo
                          ),
                          TextSpan(text: '!'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ahorra tiempo y dinero comparando precios en tus supermercados y farmacias favoritas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // --- BOTONES DE ACCIÓN ---
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botón principal con el color morado de tu logo
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logoPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Empezar a buscar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                    const SizedBox(height: 16),
                    // Botón secundario para login/registro
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: logoRed, // Acento rojo del logo
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Crear mi lista de compras',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}