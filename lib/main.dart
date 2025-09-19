import 'package:flutter/material.dart';

void main() => runApp(const TiendasCercaApp());

/// ---------------------------
/// MODELOS SIMPLES (in-memory)
/// ---------------------------
class Store {
  final String id;
  String name;
  String address;
  double distanceKm;
  final List<Product> products;
  final List<String> paymentMethods; // solo display
  final List<ChatMessage> chat; // chat local por tienda

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.products,
    required this.paymentMethods,
    List<ChatMessage>? chat,
  }) : chat = chat ?? [];
}

class Product {
  final String id;
  String name;
  double price;
  final String unit;
  final String image; // puede ser URL o asset; aquí solo texto
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.image,
  });
}

class ChatMessage {
  final String sender; // "cliente" | "tendero"
  final String text;
  final DateTime at;
  ChatMessage({required this.sender, required this.text}) : at = DateTime.now();
}

class CartItem {
  final Product product;
  final Store store;
  int qty;
  CartItem({required this.product, required this.store, this.qty = 1});
}

/// ------------------------------------
/// ESTADO GLOBAL SENCILLO (StatefulApp)
/// ------------------------------------
class AppState {
  bool tenderoMode = false; // alterna para editar precios
  final List<Store> stores = _seedStores();

  final List<CartItem> cart = [];

  void toggleTenderoMode() => tenderoMode = !tenderoMode;

  void addToCart(Store store, Product product) {
    final idx = cart.indexWhere((c) => c.product.id == product.id && c.store.id == store.id);
    if (idx >= 0) {
      cart[idx].qty += 1;
    } else {
      cart.add(CartItem(product: product, store: store, qty: 1));
    }
  }

  void removeFromCart(CartItem item) {
    cart.remove(item);
  }

  void changeQty(CartItem item, int delta) {
    item.qty += delta;
    if (item.qty <= 0) cart.remove(item);
  }

  double cartTotal() {
    double t = 0;
    for (final c in cart) {
      t += c.product.price * c.qty;
    }
    return t;
  }

  static List<Store> _seedStores() {
    final List<Store> s = [];
    for (int i = 1; i <= 10; i++) {
      s.add(
        Store(
          id: 's$i',
          name: 'Tienda Vecina #$i',
          address: 'Calle ${10 + i} # ${5 + i}-${20 + i}',
          distanceKm: (i * 0.3),
          paymentMethods: ['Efectivo', 'Nequi', 'Bancolombia'],
          products: [
            Product(id: 'p${i}a', name: 'Arroz x500g', price: 3200, unit: 'paq', image: 'arroz'),
            Product(id: 'p${i}b', name: 'Huevos x12', price: 12500, unit: 'doc', image: 'huevos'),
            Product(id: 'p${i}c', name: 'Leche 1L', price: 4200, unit: 'L', image: 'leche'),
            Product(id: 'p${i}d', name: 'Aceite 1L', price: 16500, unit: 'L', image: 'aceite'),
            Product(id: 'p${i}e', name: 'Pan tajado', price: 6200, unit: 'unid', image: 'pan'),
          ],
        ),
      );
    }
    return s;
  }
}

/// --------------
/// APP PRINCIPAL
/// --------------
class TiendasCercaApp extends StatefulWidget {
  const TiendasCercaApp({super.key});

  @override
  State<TiendasCercaApp> createState() => _TiendasCercaAppState();
}

class _TiendasCercaAppState extends State<TiendasCercaApp> {
  final AppState state = AppState();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiendas Cerca',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF8FAF8),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tiendas Cerca — MVP'),
          actions: [
            IconButton(
              tooltip: state.tenderoMode ? 'Salir modo Tendero' : 'Entrar modo Tendero',
              onPressed: () => setState(state.toggleTenderoMode),
              icon: Icon(state.tenderoMode ? Icons.lock_open : Icons.store),
            ),
            Stack(
              children: [
                IconButton(
                  tooltip: 'Carrito',
                  onPressed: () => setState(() => currentIndex = 1),
                  icon: const Icon(Icons.shopping_cart),
                ),
                if (state.cart.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${state.cart.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: currentIndex,
          children: [
            StoresView(state: state, openCart: () => setState(() => currentIndex = 1)),
            CartView(state: state, goCheckout: () => setState(() => currentIndex = 2)),
            CheckoutView(state: state, backToHome: () => setState(() => currentIndex = 0)),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => setState(() => currentIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Tiendas'),
            NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Carrito'),
            NavigationDestination(icon: Icon(Icons.payment_outlined), label: 'Checkout'),
          ],
        ),
      ),
    );
  }
}

/// ----------------------
/// VIEW: LISTA DE TIENDAS
/// ----------------------
class StoresView extends StatefulWidget {
  final AppState state;
  final VoidCallback openCart;
  const StoresView({super.key, required this.state, required this.openCart});

  @override
  State<StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends State<StoresView> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.state.stores.where((s) {
      if (query.trim().isEmpty) return true;
      final q = query.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.address.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar tienda o dirección…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final s = filtered[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.storefront)),
                  title: Text(s.name),
                  subtitle: Text('${s.address}\n${s.distanceKm.toStringAsFixed(1)} km'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StoreDetailPage(
                        state: widget.state,
                        store: s,
                        onAddToCart: () {
                          // Dar feedback y permitir abrir carrito
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Producto agregado al carrito'),
                              action: SnackBarAction(label: 'Ver carrito', onPressed: widget.openCart),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ----------------------
/// VIEW: DETALLE DE TIENDA
/// ----------------------
class StoreDetailPage extends StatefulWidget {
  final AppState state;
  final Store store;
  final VoidCallback onAddToCart;
  const StoreDetailPage({
    super.key,
    required this.state,
    required this.store,
    required this.onAddToCart,
  });

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  String productQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.store.products.where((p) {
      if (productQuery.trim().isEmpty) return true;
      final q = productQuery.toLowerCase();
      return p.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        actions: [
          IconButton(
            tooltip: 'Chat con la tienda',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(store: widget.store),
              ),
            ),
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.store.address, style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: widget.store.paymentMethods
                      .map((pm) => Chip(label: Text(pm), avatar: const Icon(Icons.payments)))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar producto…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (v) => setState(() => productQuery = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final p = filtered[i];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                    title: Text(p.name),
                    subtitle: Text('${p.unit} · \$${p.price.toStringAsFixed(0)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.state.tenderoMode)
                          IconButton(
                            tooltip: 'Editar precio',
                            onPressed: () => _editPriceDialog(p),
                            icon: const Icon(Icons.edit),
                          ),
                        IconButton(
                          tooltip: 'Agregar al carrito',
                          onPressed: () {
                            widget.state.addToCart(widget.store, p);
                            widget.onAddToCart();
                            setState(() {});
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPriceDialog(Product p) async {
    final ctl = TextEditingController(text: p.price.toStringAsFixed(0));
    final newVal = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Actualizar precio'),
        content: TextField(
          controller: ctl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Precio (COP)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctl.text.trim());
              if (v != null && v > 0) {
                Navigator.pop(context, v);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newVal != null) {
      setState(() => p.price = newVal);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precio actualizado')),
      );
    }
  }
}

/// ----------------------
/// VIEW: CHAT POR TIENDA
/// ----------------------
class ChatPage extends StatefulWidget {
  final Store store;
  const ChatPage({super.key, required this.store});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _ctl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat — ${widget.store.name}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              reverse: true,
              itemCount: widget.store.chat.length,
              itemBuilder: (_, i) {
                final msg = widget.store.chat.reversed.toList()[i];
                final isClient = msg.sender == 'cliente';
                return Align(
                  alignment: isClient ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isClient ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmtTime(msg.at),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final txt = _ctl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      widget.store.chat.add(ChatMessage(sender: 'cliente', text: txt));
      // Simulación de respuesta automática del tendero:
      widget.store.chat.add(ChatMessage(sender: 'tendero', text: '¡Recibido! 👌'));
    });
    _ctl.clear();
  }

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// ----------------------
/// VIEW: CARRITO
/// ----------------------
class CartView extends StatefulWidget {
  final AppState state;
  final VoidCallback goCheckout;
  const CartView({super.key, required this.state, required this.goCheckout});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  @override
  Widget build(BuildContext context) {
    final cart = widget.state.cart;
    final total = widget.state.cartTotal();

    return Column(
      children: [
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Text('Tu carrito está vacío.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, i) {
                    final item = cart[i];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                          '${item.store.name}\n\$${item.product.price.toStringAsFixed(0)} · ${item.product.unit}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => setState(() => widget.state.changeQty(item, -1)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${item.qty}', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              onPressed: () => setState(() => widget.state.changeQty(item, 1)),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              tooltip: 'Quitar',
                              onPressed: () => setState(() => widget.state.removeFromCart(item)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: cart.length,
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('\$${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: cart.isEmpty ? null : widget.goCheckout,
                  icon: const Icon(Icons.payment),
                  label: const Text('Ir a pagar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ----------------------
/// VIEW: CHECKOUT (mock)
/// ----------------------
class CheckoutView extends StatefulWidget {
  final AppState state;
  final VoidCallback backToHome;
  const CheckoutView({super.key, required this.state, required this.backToHome});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  String? pm;

  @override
  Widget build(BuildContext context) {
    final total = widget.state.cartTotal();
    final uniqueStores = widget.state.cart.map((e) => e.store).toSet().toList();

    // Intersección de métodos de pago de todas las tiendas del carrito (simplificación)
    final availablePMs = uniqueStores
        .map((s) => s.paymentMethods.toSet())
        .reduce((a, b) => a.intersection(b))
        .toList();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text('Resumen de compra', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...widget.state.cart.map((c) => ListTile(
                      dense: true,
                      title: Text('${c.product.name} x${c.qty}'),
                      subtitle: Text(c.store.name),
                      trailing: Text('\$${(c.product.price * c.qty).toStringAsFixed(0)}'),
                    )),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('\$${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Medio de pago', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: availablePMs.map((m) {
                    final selected = pm == m;
                    return ChoiceChip(
                      label: Text(m),
                      selected: selected,
                      onSelected: (_) => setState(() => pm = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Nota: Este es un checkout simulado para validar el flujo. '
                  'En la siguiente iteración conectamos pasarela (Nequi/Bancolombia/QR) o confirmación por chat.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.backToHome,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Seguir comprando'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (pm == null || widget.state.cart.isEmpty)
                        ? null
                        : () {
                            final metodo = pm!;
                            // Vaciar carrito y confirmar
                            setState(() {
                              widget.state.cart.clear();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Pedido confirmado vía $metodo ✅')),
                            );
                            widget.backToHome();
                          },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar pedido'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
