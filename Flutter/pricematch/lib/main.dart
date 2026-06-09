import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pricematch/pages/search_page.dart';
import 'package:pricematch/pages/login_page.dart';
import 'package:pricematch/pages/favoritos_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Error: Las llaves de Supabase no se encontraron en el archivo .env');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PriceMatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6356E5)),
        useMaterial3: true,
      ),
      home: const PriceMatchHomePage(),
    );
  }
}

class PriceMatchHomePage extends StatefulWidget {
  const PriceMatchHomePage({super.key});

  @override
  State<PriceMatchHomePage> createState() => _PriceMatchHomePageState();
}

class _PriceMatchHomePageState extends State<PriceMatchHomePage> {
  // Colores consistentes con tu LoginPage
  static const Color primaryColor = Color(0xFF6356E5);
  static const Color accentColor = Color(0xFFFF3B3B);

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar transparente para el botón de cerrar sesión
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: user != null
            ? [
                IconButton(
                  icon: const Icon(Icons.logout, color: accentColor, size: 28),
                  onPressed: () async {
                    await supabase.auth.signOut();
                    if (mounted) {
                      setState(() {}); // Recarga la página actual inmediatamente
                    }
                  },
                ),
              ]
            : null,
      ),
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
                      'assets/images/logo_pricematch.jpeg',
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
                          color: Color(0xFF2D2D2D),
                        ),
                        children: [
                          TextSpan(text: '¡Encuentra el mejor\n'),
                          TextSpan(
                            text: 'precio',
                            style: TextStyle(color: primaryColor),
                          ),
                          TextSpan(text: ' en '),
                          TextSpan(
                            text: 'El Salvador',
                            style: TextStyle(color: accentColor),
                          ),
                          TextSpan(text: '!'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ahorra tiempo y dinero comparando precios en tus supermercados y farmacias favoritas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
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
                    // Botón principal
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchPage()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
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

                    // Botón dinámico con lógica de refresco al volver de Login
                    TextButton(
                      onPressed: () async {
                        if (user == null) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                          if (mounted) setState(() {}); // Recarga la interfaz al volver
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritosPage()),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        user == null ? 'Iniciar Sesión' : 'Mi Lista de Compras',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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