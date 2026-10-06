import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';

class InvoiceService {
  static Future<void> printInvoice(Order order) async {
    final document = pw.Document()
      ..addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => _buildInvoice(order),
        ),
      );

    await Printing.layoutPdf(
      name: 'invoice-${order.id.substring(0, 8)}',
      onLayout: (_) => document.save(),
    );
  }

  static pw.Widget _buildInvoice(Order order) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final invoiceNumber = 'INV-${order.id.substring(0, 8).toUpperCase()}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'COPPER SPOON CANTEEN',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.brown800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'PICKUP ORDER INVOICE',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Divider(color: PdfColors.brown300),
        pw.SizedBox(height: 12),
        _detail('Invoice number', invoiceNumber),
        _detail('Order number', order.id),
        _detail('Order date', dateFormat.format(order.createdAt.toLocal())),
        _detail('Pickup time', order.pickupText),
        _detail('Payment method', order.paymentMethodText),
        _detail(
          'Payment status',
          order.paymentStatus == 'PAID' ? 'PAID' : 'PAY AT PICKUP',
        ),
        if (order.paymentReference != null)
          _detail('Payment reference', order.paymentReference!),
        pw.SizedBox(height: 22),
        pw.TableHelper.fromTextArray(
          headers: const ['Item', 'Qty', 'Unit price', 'Amount'],
          data: order.items
              .map(
                (item) => [
                  item.itemName,
                  '${item.quantity}',
                  'Rs. ${item.unitPrice.toStringAsFixed(2)}',
                  'Rs. ${item.subtotal.toStringAsFixed(2)}',
                ],
              )
              .toList(),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.brown800),
          cellPadding: const pw.EdgeInsets.all(8),
          cellAlignments: {
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 18),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'TOTAL  Rs. ${order.totalAmount.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Spacer(),
        pw.Divider(color: PdfColors.grey400),
        pw.Center(
          child: pw.Text(
            order.paymentMethod == 'MOCK_ONLINE'
                ? 'Demo invoice - online payment is simulated; no real payment was processed.'
                : 'Thank you. Cash payment is due at pickup.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  static pw.Widget _detail(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 125,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
