class SpecificationItem {
  final String id; // Уникальный ID для каждого отдельного товара
  final String article; // Артикул, например "А321"
  final String name; // Наименование
  // Можно добавить и другие поля из Excel при необходимости

  SpecificationItem({
    required this.id,
    required this.article,
    required this.name,
  });
}

class GroupedArticle {
  final String article;
  final int totalQuantity;

  GroupedArticle({required this.article, required this.totalQuantity});
}
