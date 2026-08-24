import 'package:flutter/material.dart';

class CategoryIconHelper {
  static IconData getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'briefcase':
      case 'work':
        return Icons.work_outline_rounded;
      case 'laptop':
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'trending-up':
      case 'investments':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'utensils':
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'home':
      case 'housing':
      case 'rent':
        return Icons.home_rounded;
      case 'car':
      case 'transport':
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'shopping-bag':
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'film':
      case 'entertainment':
      case 'movies':
        return Icons.movie_outlined;
      case 'heart':
      case 'health':
      case 'fitness':
        return Icons.favorite_border_rounded;
      case 'zap':
      case 'utilities':
      case 'bills':
        return Icons.bolt_rounded;
      case 'shield':
      case 'emergency':
        return Icons.shield_outlined;
      case 'plane':
      case 'travel':
      case 'vacation':
        return Icons.flight_takeoff_rounded;
      case 'target':
      case 'goal':
        return Icons.track_changes_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'book':
      case 'education':
        return Icons.menu_book_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      default:
        return Icons.local_offer_outlined;
    }
  }

  static Color parseColor(String hexColor, {Color defaultColor = const Color(0xFF6366F1)}) {
    try {
      String hex = hexColor.replaceAll('#', '').trim();
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return defaultColor;
    } catch (_) {
      return defaultColor;
    }
  }
}
