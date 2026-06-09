import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RegisterPage extends StatefulWidget {
const RegisterPage({super.key});

@override
State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
final nombreController = TextEditingController();
final usuarioController = TextEditingController();
final telefonoController = TextEditingController();
final ciudadController = TextEditingController();
final emailController = TextEditingController();
final passwordController = TextEditingController();

bool loading = false;
bool obscurePassword = true;

static const Color primaryColor = Color(0xFF6356E5);
static const Color secondaryColor = Color(0xFF8D86FF);
static const Color accentColor = Color(0xFFFF3B3B);

Future<void> register() async {
if (nombreController.text.trim().isEmpty ||
usuarioController.text.trim().isEmpty ||
emailController.text.trim().isEmpty ||
passwordController.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Complete todos los campos obligatorios'),
),
);
return;
}


if (passwordController.text.length < 6) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'La contraseña debe tener al menos 6 caracteres',
      ),
    ),
  );
  return;
}

try {
  setState(() => loading = true);

  final response = await supabase.auth.signUp(
    email: emailController.text.trim(),
    password: passwordController.text.trim(),
  );

  final user = response.user;

  if (user != null) {
    await supabase.from('perfiles').insert({
      'id': user.id,
      'nombre': nombreController.text.trim(),
      'usuario': usuarioController.text.trim(),
      'telefono': telefonoController.text.trim(),
      'ciudad': ciudadController.text.trim(),
    });
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cuenta creada correctamente'),
      ),
    );

    Navigator.pop(context);
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
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
nombreController.dispose();
usuarioController.dispose();
telefonoController.dispose();
ciudadController.dispose();
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
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Regístrate para crear tus listas y guardar favoritos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 25),

                customField(
                  controller: nombreController,
                  label: 'Nombre completo',
                  icon: Icons.person,
                ),

                customField(
                  controller: usuarioController,
                  label: 'Nombre de usuario',
                  icon: Icons.alternate_email,
                ),

                customField(
                  controller: telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                customField(
                  controller: ciudadController,
                  label: 'Ciudad',
                  icon: Icons.location_city,
                ),

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
                    onPressed: loading ? null : register,
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
                            'Crear Cuenta',
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
                    Navigator.pop(context);
                  },
                  child: const Text(
                    '¿Ya tienes cuenta? Inicia sesión',
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
