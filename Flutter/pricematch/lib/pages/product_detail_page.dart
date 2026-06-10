import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

class ProductDetailPage extends StatefulWidget {
  final dynamic masterId;
  final String nombre;

  const ProductDetailPage({
    super.key,
    required this.masterId,
    required this.nombre,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<Map<String, dynamic>> _precios = [];
  bool _cargando = true;
  bool _esFavorito = false; // <-- NUEVO: Guarda si el producto ya es favorito

  static const Color logoPurple = Color(0xFF676AF2);

  @override
  void initState() {
    super.initState();
    _cargarPrecios();
    _verificarFavorito(); // <-- NUEVO: Verifica el estado al iniciar
  }

  Future<void> _cargarPrecios() async {
    try {
      final data = await supabase.rpc(
        'precios_por_supermercado',
        params: {'p_master_id': widget.masterId},
      );
      setState(() { _precios = List<Map<String, dynamic>>.from(data); });
    } finally {
      setState(() { _cargando = false; });
    }
  }

  // <-- NUEVO: Comprueba si el usuario ya guardó este producto
  Future<void> _verificarFavorito() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('favoritos')
          .select()
          .eq('usuario_id', user.id)
          .eq('producto_id', widget.masterId)
          .maybeSingle(); // Retorna un registro o null

      if (mounted) {
        setState(() {
          _esFavorito = data != null; // Si no es null, ya es favorito
        });
      }
    } catch (e) {
      print('Error al verificar favorito: $e');
    }
  }

  // MODIFICADO: Ahora agrega o elimina dinámicamente (Toggle)
  Future<void> _toggleFavorito() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para guardar favoritos')),
      );
      return;
    }

    try {
      if (_esFavorito) {
        // Si ya es favorito, lo eliminamos
        await supabase
            .from('favoritos')
            .delete()
            .eq('usuario_id', user.id)
            .eq('producto_id', widget.masterId);

        setState(() { _esFavorito = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Producto eliminado de tu lista')),
          );
        }
      } else {
        // Si no es favorito, lo agregamos (Tu lógica original)
        await supabase.from('favoritos').insert({
          'usuario_id': user.id,
          'producto_id': widget.masterId,
          'nombre_producto': widget.nombre,
        });

        setState(() { _esFavorito = true; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Producto guardado en tu lista!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _getSitioColor(String? sitio) {
    switch (sitio?.toLowerCase()) {
      case 'walmart':       return const Color(0xFF0071CE);
      case 'superselectos': return const Color(0xFFFFB800);
      default:              return Colors.grey;
    }
  }

  IconData _getSitioIcon(String? sitio) {
    switch (sitio?.toLowerCase()) {
      case 'walmart':       return Icons.store;
      case 'superselectos': return Icons.storefront;
      default:              return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mejorPrecio = _precios.isNotEmpty ? _precios.first : null;
    final imagen = (mejorPrecio?['imagen_url'] as String?) ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: logoPurple),
        title: const Text(
          'Comparar precios',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // MODIFICADO: El icono cambia de color y forma según el estado
          IconButton(
            icon: Icon(
              _esFavorito ? Icons.favorite : Icons.favorite_border,
              color: _esFavorito ? Colors.red : logoPurple,
            ),
            tooltip: _esFavorito ? 'Eliminar de la lista' : 'Guardar producto',
            onPressed: _toggleFavorito,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: logoPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: imagen.isNotEmpty
                        ? Image.network(imagen, height: 180, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.shopping_basket, size: 100, color: Colors.grey))
                        : const Icon(Icons.shopping_basket, size: 100, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.nombre,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  if (mejorPrecio != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: logoPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: logoPurple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: logoPurple),
                          const SizedBox(width: 8),
                          const Text('Mejor precio',
                              style: TextStyle(color: logoPurple, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(
                            '\$${mejorPrecio['precio']?.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: logoPurple,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('Precios por supermercado',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  ..._precios.map((p) => _PrecioCard(
                        precio: p,
                        esMejor: p == mejorPrecio,
                        sitioColor: _getSitioColor(p['sitio']),
                        sitioIcon: _getSitioIcon(p['sitio']),
                      )),
                ],
              ),
            ),
    );
  }
}

// (Tu clase _PrecioCard se mantiene exactamente igual abajo...)
class _PrecioCard extends StatelessWidget {
  final Map<String, dynamic> precio;
  final bool esMejor;
  final Color sitioColor;
  final IconData sitioIcon;

  const _PrecioCard({
    required this.precio,
    required this.esMejor,
    required this.sitioColor,
    required this.sitioIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: esMejor ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: esMejor ? BorderSide(color: sitioColor, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sitioColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(sitioIcon, color: sitioColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    precio['sitio']?.toString().toUpperCase() ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, color: sitioColor),
                  ),
                  if (precio['nombre'] != null)
                    Text(
                      precio['nombre'],
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (esMejor)
                    const Text('Mejor precio', style: TextStyle(fontSize: 11, color: Colors.green)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  () {
                    final p = precio['precio'];
                    final val = p is String ? double.tryParse(p) : (p as num?)?.toDouble();
                    return '\$${val?.toStringAsFixed(2) ?? '-'}';
                  }(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (precio['url_producto'] != null)
                  TextButton(
                    onPressed: () async {
                      final url = Uri.parse(precio['url_producto']);
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Ver en tienda →', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}