import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/widgets.dart';
import 'reminders.dart';

class HomePage extends StatelessWidget {
  final BonyeApi api;
  final VoidCallback onPets;
  const HomePage({super.key, required this.api, required this.onPets});
  @override
  Widget build(BuildContext context) => RemoteView(
        load: () => api.request('GET', '/me'),
        builder: (data, reload) => PageBody(
          children: [
            SectionTitle(
              'سلام ${data['name'] ?? ''} 👋',
              'یک قدم کوچک برای حال خوب همراه کوچکت.',
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pets, color: accent, size: 42),
                  const SizedBox(height: 18),
                  const Text(
                    'تغذیه مناسب، زندگی بهتر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'مشخصات پتت را تکمیل کن تا پیشنهاد غذا و برنامه مصرف متناسب با او را ببینی.',
                    style: TextStyle(color: Colors.white70, height: 1.8),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: brand,
                    ),
                    onPressed: onPets,
                    child: const Text('برنامه غذایی پت من'),
                  ),
                ],
              ),
            ),
            InfoCard(
              'شماره عضویت',
              '${data['member_no'] ?? '—'}',
              Icons.card_membership,
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('خریدهای من'),
                subtitle: const Text('خریدهای سایت و شعب بنیه'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => push(
                  context,
                  RecordsPage(api, '/orders', 'خریدهای من'),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('یادآوری خرید مجدد'),
                onTap: () => push(context, RemindersPage(api: api)),
              ),
            ),
          ],
        ),
      );
}

class ProductsPage extends StatelessWidget {
  final BonyeApi api;
  const ProductsPage({super.key, required this.api});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('محصولات بنیه')),
        body: RemoteView(
          load: () => api.request('GET', '/products?limit=100'),
          builder: (data, reload) => PageBody(
            children: [
              const Text(
                'قیمت‌ها به ریال هستند. قیمت و موجودی نهایی هنگام پرداخت در سایت مشخص می‌شود.',
              ),
              ...(data['items'] as List).cast<Json>().map(
                    (p) => ProductCard(api: api, product: p),
                  ),
              if ((data['items'] as List).isEmpty)
                const Text('هنوز محصولی برای نمایش وجود ندارد.'),
            ],
          ),
        ),
      );
}

class ProductCard extends StatelessWidget {
  final BonyeApi api;
  final Json product;
  final VoidCallback? onPlan;
  const ProductCard({
    super.key,
    required this.api,
    required this.product,
    this.onPlan,
  });
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${product['name'] ?? product['sku']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${product['pack_quantity'] ?? ''} ${product['pack_unit'] ?? ''}',
              ),
              Text(money(product['price']?['amount'])),
              Text(
                  'موجودی قابل فروش: ${product['sellable_quantity'] ?? 0} بسته'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onPlan != null)
                    FilledButton(
                      onPressed: onPlan,
                      child: const Text('دریافت برنامه غذایی'),
                    ),
                  OutlinedButton(
                    onPressed: product['purchase_link_available'] != true
                        ? null
                        : () async {
                            try {
                              final result = await api.request(
                                'GET',
                                '/products/${product['variant_id']}/purchase-link',
                              );
                              await externalLink(result['url'] as String);
                            } catch (e) {
                              if (context.mounted) {
                                showError(context, e);
                              }
                            }
                          },
                    child: const Text('خرید از سایت'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
