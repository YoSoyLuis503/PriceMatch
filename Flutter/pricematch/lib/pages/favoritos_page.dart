import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_detail_page.dart'; // Para poder navegar al detalle del producto

final supabase = Supabase.instance.client;

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<Map<String, dynamic>> _favoritos = [];
  bool _cargando = true;

  static const Color logoPurple = Color(0xFF676AF2);

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  // Descarga la lista de favoritos del usuario actual
  Future<void> _cargarFavoritos() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _cargando = true);

    try {
      final data = await supabase
          .from('favoritos')
          .select()
          .eq('usuario_id', user.id)
          .order('id', ascending: false); // Los más nuevos primero

      setState(() {
        _favoritos = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la lista: $e')),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  // Permite borrar un favorito directamente desde esta pantalla
  Future<void> _eliminarFavorito(dynamic productoId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('favoritos')
          .delete()
          .eq('usuario_id', user.id)
          .eq('producto_id', productoId);

      // Actualizamos la interfaz quitándolo de la lista local
      setState(() {
        _favoritos.removeWhere((item) => item['producto_id'] == productoId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado de la lista de compras')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: logoPurple),
        title: const Text(
          'Mi Lista de Compras',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: logoPurple))
          : _favoritos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.turned_in_not, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no tienes productos guardados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoritos.length,
                  itemBuilder: (context, index) {
                    final fav = _favoritos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: logoPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_bag, color: logoPurple),
                        ),
                        title: Text(
                          fav['nombre_producto'] ?? 'Producto sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text(
                          'Ver precios actualizados →',
                          style: TextStyle(fontSize: 12, color: logoPurple),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _eliminarFavorito(fav['producto_id']),
                        ),
                        onTap: () async {
                          // Navegar al detalle para ver los precios actualizados
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(
                                masterId: fav['producto_id'],
                                nombre: fav['nombre_producto'] ?? '',
                              ),
                            ),
                          );
                          // Al regresar, refrescamos la lista por si el usuario quitó el favorito allá dentro
                          _cargarFavoritos();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}