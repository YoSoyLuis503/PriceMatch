import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_detail_page.dart';

final supabase = Supabase.instance.client;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _cargando = false;
  bool _buscado = false;

  static const Color logoPurple = Color(0xFF676AF2);
  static const Color logoRed    = Color(0xFFFF4842);

  Future<void> _buscar(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _cargando = true; _buscado = true; });

    try {
      final data = await supabase
          .rpc('buscar_productos', params: {'query': query.trim()});
      setState(() { _resultados = List<Map<String, dynamic>>.from(data); });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() { _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PriceMatch',
          style: TextStyle(
            color: logoPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onSubmitted: _buscar,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search, color: logoPurple),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() { _resultados = []; _buscado = false; });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: logoPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: logoPurple, width: 2),
                ),
              ),
            ),
          ),

          // Resultados
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: logoPurple))
                : !_buscado
                    ? _buildEstadoInicial()
                    : _resultados.isEmpty
                        ? _buildSinResultados()
                        : _buildListaProductos(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoInicial() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Buscá un producto para\ncomparar precios',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSinResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No encontramos ese producto',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _resultados.length,
      itemBuilder: (context, index) {
        final p = _resultados[index];
        return _ProductCard(
          producto: p,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                masterId: p['id'],
                nombre: p['nombre_normalizado'],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final VoidCallback onTap;

  const _ProductCard({required this.producto, required this.onTap});

  static const Color logoPurple = Color(0xFF676AF2);

  String _getSitioLogo(String? sitio) {
    switch (sitio?.toLowerCase()) {
      case 'walmart':      return '🔵';
      case 'superselectos': return '🟡';
      default:             return '🏪';
    }
  }

  @override
  Widget build(BuildContext context) {
    final precioRaw = producto['precio_min'];
    final precio = precioRaw is String 
        ? double.tryParse(precioRaw) 
        : (precioRaw as num?)?.toDouble();
    final sitio  = producto['sitio_precio_min'] ?? '';
    final imagen = producto['imagen_url'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagen.isNotEmpty
                    ? Image.network(
                        imagen,
                        width: 70, height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderImagen(),
                      )
                    : _placeholderImagen(),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto['nombre_normalizado'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (producto['marca'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        producto['marca'],
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${precio != null ? precio.toStringAsFixed(2) : '-'}',
                          style: const TextStyle(
                            color: logoPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_getSitioLogo(sitio)} $sitio',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImagen() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_basket, color: Colors.grey),
    );
  }
}