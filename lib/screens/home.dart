import '../core/language.dart';
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/widgets.dart';
import 'reminders.dart';

class HomePage extends StatelessWidget {
  final BonyeApi api;
  final VoidCallback onPets, onClub, onLearn;
  const HomePage(
      {super.key,
      required this.api,
      required this.onPets,
      required this.onClub,
      required this.onLearn});
  @override
  Widget build(BuildContext context) => RemoteView(
        load: () => api.request('GET', '/me'),
        builder: (data, reload) => PageBody(
          children: [
            SectionTitle(
              'سلام ${data['name'] ?? ''} 👋',
              'یک قدم کوچک برای حال خوب همراه کوچکت.',
            ),
            BrandFeature(
              title: 'تغذیه مناسب، زندگی بهتر',
              subtitle:
                  'مشخصات پتت را تکمیل کن تا پیشنهاد غذا و برنامه مصرف متناسب با او را ببینی.',
              icon: Icons.spa_outlined,
              action: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: accent, foregroundColor: brand),
                  onPressed: onPets,
                  icon: const Icon(Icons.arrow_forward),
                  label: const AppText('برنامه غذایی پت من')),
            ),
            LayoutBuilder(
                builder: (context, constraints) =>
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: ActionTile(
                              title: 'باشگاه بنیه',
                              subtitle: 'امتیاز و مزایای شما',
                              icon: Icons.workspace_premium_outlined,
                              onTap: onClub)),
                      SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: ActionTile(
                              title: 'آموزش و مراقبت',
                              subtitle: 'پادکست و مقاله',
                              icon: Icons.headphones_outlined,
                              onTap: onLearn)),
                    ])),
            InfoCard(
              'شماره عضویت',
              '${data['member_no'] ?? '—'}',
              Icons.card_membership,
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const AppText('خریدهای من'),
                subtitle: const AppText('خریدهای سایت و شعب بنیه'),
                trailing: const ForwardChevron(),
                onTap: () => push(
                  context,
                  RecordsPage(api, '/orders', 'خریدهای من'),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const AppText('یادآوری خرید مجدد'),
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
        appBar: AppBar(title: const AppText('محصولات بنیه')),
        body: RemoteView(
          load: () => api.request('GET', '/products?limit=100'),
          builder: (data, reload) => PageBody(
            children: [
              const AppText(
                'قیمت‌ها به ریال هستند. قیمت و موجودی نهایی هنگام پرداخت در سایت مشخص می‌شود.',
              ),
              ...(data['items'] as List).cast<Json>().map(
                    (p) => ProductCard(api: api, product: p),
                  ),
              if ((data['items'] as List).isEmpty)
                const AppText('هنوز محصولی برای نمایش وجود ندارد.'),
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
              AppText(
                '${product['name'] ?? product['sku']}',
                translate: false,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              AppText(
                '${product['pack_quantity'] ?? ''} ${tr((product['pack_unit'] ?? '').toString())}',
              ),
              AppText(money(product['price']?['amount'])),
              AppText(
                  'موجودی قابل فروش: ${product['sellable_quantity'] ?? 0} بسته'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onPlan != null)
                    FilledButton(
                      onPressed: onPlan,
                      child: const AppText('دریافت برنامه غذایی'),
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
                    child: const AppText('خرید از سایت'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
