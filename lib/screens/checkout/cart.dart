class Cart {
  final List<Map<String, dynamic>> items;

  Cart(this.items);

  void addItem(Map<String, dynamic> product) {
    items.add(product);
  }

  void removeItem(String productId) {
    items.removeWhere((item) => item['id'] == productId);
  }
}
