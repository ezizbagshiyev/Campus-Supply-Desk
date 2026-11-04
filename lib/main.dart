import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Firebase startup failed. Run flutterfire configure for Android, '
                'verify the selected project, then restart.\n$error',
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Supply Desk - Variant B',
      home: ProductPage(),
    ),
  );
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _products = FirebaseFirestore.instance.collection('campus_products');
  late final _productStream = _products.snapshots(includeMetadataChanges: true);
  final _search = TextEditingController();
  final _minimum = TextEditingController();
  final _maximum = TextEditingController();
  final _deleting = <String>{};

  @override
  void dispose() {
    _search.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  String? get _rangeError {
    for (final c in [_minimum, _maximum]) {
      if (c.text.trim().isNotEmpty && parseAmount(c.text) == null) {
        return 'Bounds must be finite numbers of zero or more.';
      }
    }
    final min = parseAmount(_minimum.text);
    final max = parseAmount(_maximum.text);
    if (min != null && max != null && min > max) {
      return 'Minimum cannot exceed maximum.';
    }
    return null;
  }

  void _reset() => setState(() {
    _search.clear();
    _minimum.clear();
    _maximum.clear();
  });

  Future<void> _createOrUpdate([
    QueryDocumentSnapshot<Map<String, dynamic>>? document,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) =>
          ProductEditor(products: _products, document: document),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete only document $id? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting.add(id));
    try {
      await _products.doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Deleted document $id.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed (${error.code}). Check permissions and connection.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Supply Desk - Variant B')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search product names',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minimum,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Minimum price',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maximum,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Maximum price',
                        ),
                      ),
                    ),
                    TextButton(onPressed: _reset, child: const Text('Reset')),
                  ],
                ),
                if (_rangeError != null)
                  Text(
                    _rangeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Products could not load. Check connection and permissions.',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data!.docs;
                if (_rangeError != null) {
                  return const Center(
                    child: Text('Correct the price range to see results.'),
                  );
                }
                final invalid = all
                    .where((d) => !validProduct(d.data()))
                    .length;
                final documents = all
                    .where(
                      (d) => matchesProduct(
                        d.data(),
                        _search.text,
                        parseAmount(_minimum.text),
                        parseAmount(_maximum.text),
                      ),
                    )
                    .toList();
                documents.sort(
                  (a, b) => (a.data()['name'] as String)
                      .toLowerCase()
                      .compareTo((b.data()['name'] as String).toLowerCase()),
                );
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${documents.length} of ${all.length} products | '
                        '${snapshot.data!.metadata.isFromCache ? "Cache (may be stale)" : "Server snapshot"} | '
                        '${snapshot.data!.metadata.hasPendingWrites ? "Pending writes" : "No pending writes"}'
                        '${invalid > 0 ? " | $invalid malformed records excluded; inspect Console" : ""}',
                      ),
                    ),
                    Expanded(
                      child: documents.isEmpty
                          ? Center(
                              child: Text(
                                all.isEmpty
                                    ? 'No products yet. Add one to begin.'
                                    : 'No products found.',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 88),
                              itemCount: documents.length,
                              itemBuilder: (context, index) {
                                final document = documents[index];
                                final data = document.data();
                                final name = data['name'];
                                final price = data['price'];
                                if (name is! String ||
                                    name.trim().isEmpty ||
                                    price is! num ||
                                    !price.isFinite ||
                                    price < 0) {
                                  return ListTile(
                                    title: Text(
                                      'Invalid product ${document.id}: check name/price types.',
                                    ),
                                  );
                                }
                                return Card(
                                  child: ListTile(
                                    title: Text(name),
                                    subtitle: Text(
                                      '${price.toStringAsFixed(2)}\nID: ${document.id}',
                                    ),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit product',
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _createOrUpdate(document),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete product',
                                          icon: const Icon(Icons.delete),
                                          onPressed:
                                              _deleting.contains(document.id)
                                              ? null
                                              : () =>
                                                    _deleteProduct(document.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create product',
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, required this.products, this.document});

  final CollectionReference<Map<String, dynamic>> products;
  final QueryDocumentSnapshot<Map<String, dynamic>>? document;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.document?.data()['name'] as String? ?? '',
  );
  late final _price = TextEditingController(
    text: widget.document?.data()['price']?.toString() ?? '',
  );
  var _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final data = <String, Object>{
      'name': _name.text.trim(),
      'price': double.parse(_price.text.trim()),
    };
    try {
      final document = widget.document;
      if (document == null) {
        await widget.products.add(data);
      } else {
        await widget.products.doc(document.id).update(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      debugPrint('Product save failed (${error.code}): ${error.message}');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError =
            'Save failed (${error.code}). '
            'Check your connection and permissions.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.document == null ? 'Create product' : 'Edit product',
                ),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a product name'
                      : null,
                ),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) {
                    final amount = parseAmount(value ?? '');
                    return amount == null
                        ? 'Enter a finite price of zero or more'
                        : null;
                  },
                ),
                if (_saveError != null)
                  Text(
                    _saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_saving)
                  const Text(
                    'Awaiting server acknowledgement. If offline, reconnect. '
                    'This editor stays open until the write succeeds or fails.',
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save'),
                ),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A blank bound is absent; callers validate supplied bounds separately.
double? parseAmount(String input) {
  final value = double.tryParse(input.trim());
  return value == null || !value.isFinite || value < 0 ? null : value;
}

bool validProduct(Map<String, dynamic> data) {
  final name = data['name'];
  final price = data['price'];
  return name is String &&
      name.trim().isNotEmpty &&
      price is num &&
      price.isFinite &&
      price >= 0;
}

bool matchesProduct(
  Map<String, dynamic> data,
  String query,
  double? min,
  double? max,
) {
  if (!validProduct(data)) return false;
  final name = (data['name'] as String).trim().toLowerCase();
  final price = data['price'] as num;
  return name.contains(query.trim().toLowerCase()) &&
      (min == null || price >= min) &&
      (max == null || price <= max);
}
