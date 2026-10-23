import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class Category {
  final String name;
  final String icon;
  final Color color;
  const Category(this.name, this.icon, this.color);
}

const expenseCategories = <Category>[
  Category('Food', '🍜', AppColors.mint),
  Category('Transport', '🚌', AppColors.sky),
  Category('Shopping', '🛍', AppColors.teal),
  Category('Health', '💊', AppColors.cyan),
  Category('Fun', '🎮', AppColors.sage),
  Category('Bills', '💡', AppColors.yellow),
  Category('Other', '📦', AppColors.white),
];

const incomeCategories = <Category>[
  Category('Salary', '💼', AppColors.lime),
  Category('Gift', '🎁', AppColors.green),
  Category('Other income', '💰', AppColors.seafoam),
];

Category categoryByName(String name) {
  for (final c in [...expenseCategories, ...incomeCategories]) {
    if (c.name == name) return c;
  }
  return expenseCategories.last;
}
