/// Shared formatting utilities used across the application.
///
/// Centralises currency and date formatting so individual widgets
/// don't need to import `intl` or hardcode format strings directly.
library;

import 'package:intl/intl.dart';

/// Formats a numeric [amount] as Indian Rupees, e.g. ₹12.50
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Formats a [DateTime] as a short date, e.g. "29 Sep 2026"
String formatDate(DateTime date) {
  return DateFormat('d MMM yyyy').format(date);
}

/// Formats a [DateTime] as date + time, e.g. "29 Sep 2026, 14:30"
String formatDateTime(DateTime date) {
  return DateFormat('d MMM yyyy, HH:mm').format(date);
}

/// Capitalises the first letter of [text] and lowercases the rest.
/// Useful for displaying order statuses like "pending" → "Pending".
String capitalise(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
