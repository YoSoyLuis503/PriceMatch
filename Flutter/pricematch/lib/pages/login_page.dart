import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'register_page.dart';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final emailController = TextEditingController();
final passwordController = TextEditingController();

bool loading = false;
bool obscurePassword = true;

static const Color primaryColor = Color(0xFF6356E5);
static const Color secondaryColor = Color(0xFF8D86FF);
static const Color accentColor = Color(0xFFFF3B3B);

Future<void> login() async {
if (emailController.text.trim().isEmpty ||
passwordController.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Ingrese correo y contraseña',
),
),
);
return;
}


try {
  setState(() => loading = true);

  await supabase.auth.signInWithPassword(
    email: emailController.text.trim(),
    password: passwordController.text.trim(),
  );

  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const PriceMatchHomePage(),
      ),
      (route) => false,
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Correo o contraseña incorrectos',
        ),
      ),
    );
  }
}

if (mounted) {
  setState(() => loading = false);
}


}

Widget customField({
required TextEditingController controller,
required String label,
required IconData icon,
bool password = false,
TextInputType keyboardType = TextInputType.text,
}) {
return Padding(
padding: const EdgeInsets.only(bottom: 15),
child: TextField(
controller: controller,
keyboardType: keyboardType,
obscureText: password ? obscurePassword : false,
decoration: InputDecoration(
filled: true,
fillColor: Colors.grey.shade50,
labelText: label,
prefixIcon: Icon(
icon,
color: primaryColor,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(15),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(15),
borderSide: const BorderSide(
color: primaryColor,
width: 2,
),
),
suffixIcon: password
? IconButton(
icon: Icon(
obscurePassword
? Icons.visibility_off
: Icons.visibility,
color: primaryColor,
),
onPressed: () {
setState(() {
obscurePassword = !obscurePassword;
});
},
)
: null,
),
),
);
}

@override
void dispose() {
emailController.dispose();
passwordController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Container(
width: double.infinity,
decoration: const BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
primaryColor,
secondaryColor,
],
),
),
child: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Container(
constraints: const BoxConstraints(
maxWidth: 500,
),
padding: const EdgeInsets.all(30),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(30),
boxShadow: const [
BoxShadow(
color: Colors.black12,
blurRadius: 25,
offset: Offset(0, 12),
),
],
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
  Icons.shopping_cart,
  size: 70,
  color: primaryColor,
),


                const SizedBox(height: 10),

                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Inicia sesión para acceder a tus listas y favoritos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 30),

                customField(
                  controller: emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                customField(
                  controller: passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock,
                  password: true,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegisterPage(),
                      ),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? Crear cuenta',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);


}
}
