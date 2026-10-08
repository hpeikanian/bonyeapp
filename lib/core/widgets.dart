import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

const brand = Color(0xFF15383D);
const accent = Color(0xFFE6AD60);
String plainText(Object? value) => (value ?? '')
    .toString()
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&#8217;', '’');
String money(Object? amount) => '${amount ?? '۰'} ریال';
Future<void> externalLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw ApiError('invalid_link');
  }
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw ApiError('link_failed');
  }
}

void showError(BuildContext context, Object error) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error is ApiError
            ? error.message
            : 'عملیات انجام نشد؛ دوباره تلاش کنید.',
      ),
    ),
  );
}

void push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children:
            children.expand((w) => [w, const SizedBox(height: 14)]).toList(),
      );
}

class SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const SectionTitle(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, height: 1.7),
          ),
        ],
      );
}

class InfoCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const InfoCard(this.title, this.value, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: brand.withValues(alpha: .08),
                child: Icon(icon, color: brand),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class RemoteView extends StatefulWidget {
  final Future<Json> Function() load;
  final Widget Function(Json data, VoidCallback reload) builder;
  const RemoteView({super.key, required this.load, required this.builder});
  @override
  State<RemoteView> createState() => _RemoteViewState();
}

class _RemoteViewState extends State<RemoteView> {
  late Future<Json> future;
  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  void reload() {
    setState(() => future = widget.load());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 48, color: brand),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.error is ApiError
                          ? (snapshot.error as ApiError).message
                          : 'دریافت اطلاعات انجام نشد.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: reload,
                      child: const Text('تلاش دوباره'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              reload();
              await future;
            },
            child: widget.builder(snapshot.data!, reload),
          );
        },
      );
}

const labels = <String, String>{
  'id': 'شناسه',
  'name': 'نام',
  'title': 'عنوان',
  'description': 'شرح',
  'details': 'جزئیات',
  'code': 'کد',
  'status': 'وضعیت',
  'points': 'امتیاز',
  'direction': 'نوع گردش',
  'created_at': 'تاریخ ثبت',
  'expires_at': 'انقضا',
  'invoice_no': 'شماره فاکتور',
  'invoice_date': 'تاریخ فاکتور',
  'total': 'جمع',
  'net_total': 'جمع خالص',
  'grand_total': 'مبلغ نهایی',
  'currency': 'واحد پول',
  'amount': 'مبلغ',
  'value': 'مقدار',
  'type': 'نوع',
  'min_spend': 'حداقل خرید',
  'max_discount': 'سقف تخفیف',
  'used_count': 'تعداد استفاده',
  'usage_limit': 'سقف استفاده',
  'discount': 'تخفیف',
  'quantity': 'تعداد',
  'qty': 'تعداد',
  'sku': 'کد کالا',
  'unit_price': 'قیمت واحد',
  'next_date': 'موعد بعدی',
  'repeat_days': 'فاصله روزها',
  'daily_qty': 'مصرف روزانه',
  'consumption_unit': 'واحد مصرف',
  'rewarded_referrals': 'معرفی‌های موفق',
  'points_per_qualified_referral': 'امتیاز معرفی موفق',
  'qualification_min_spend': 'حداقل خرید واجد شرایط',
  'member_no': 'شماره عضویت',
  'address': 'آدرس',
  'mobile': 'موبایل',
  'email': 'ایمیل',
  'city': 'شهر',
  'postal_code': 'کد پستی',
  'recipient_name': 'گیرنده',
  'recipient_mobile': 'موبایل گیرنده',
  'province': 'استان',
  'line1': 'آدرس',
  'birth_date': 'تولد',
  'point_multiplier': 'ضریب امتیاز',
  'active': 'فعال',
  'reference_type': 'نوع مرجع',
  'reference_id': 'شناسه مرجع',
  'tier': 'سطح عضویت',
  'benefits': 'مزایا',
  'min_points': 'حداقل امتیاز',
  'net_amount': 'مبلغ خالص',
  'sales_channel': 'محل خرید',
  'items': 'اقلام خرید',
  'usage': 'سابقه استفاده',
  'discount_amount': 'مبلغ تخفیف',
  'redeemed_points': 'امتیاز تبدیل‌شده',
  'weight_kg': 'وزن (کیلوگرم)',
  'measured_on': 'تاریخ اندازه‌گیری',
  'label': 'عنوان آدرس',
  'is_default': 'آدرس پیش‌فرض',
  'has_referrer': 'معرف ثبت‌شده',
  'lead_days': 'روزهای یادآوری زودتر',
  'last_purchase_date': 'تاریخ آخرین خرید',
};
String displayValue(dynamic value) {
  if (value == null) {
    return '—';
  }
  if (value is bool) {
    return value ? 'بله' : 'خیر';
  }
  if (value is Map) {
    return value.entries
        .where((e) =>
            labels.containsKey(e.key) &&
            !['id', 'reference_id', 'reference_type'].contains(e.key))
        .map((e) => '${labels[e.key]}: ${displayValue(e.value)}')
        .join('\n');
  }
  if (value is List) {
    return value.map(displayValue).join('\n');
  }
  const names = {
    'IRR': 'ریال',
    'percent': 'درصد',
    'fixed': 'مبلغ ثابت',
    'purchase_coupon': 'کوپن خرید',
    'g': 'گرم',
    'tablet': 'قرص',
    'direct': 'مستقیم',
    'branch': 'شعبه',
    'woocommerce': 'سایت',
    'dog': 'سگ',
    'cat': 'گربه'
  };
  return names[value.toString()] ?? plainText(value);
}

class RecordCard extends StatelessWidget {
  final Json record;
  const RecordCard(this.record, {super.key});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: record.entries
                .where((e) =>
                    e.value != null &&
                    labels.containsKey(e.key) &&
                    !['id', 'reference_id', 'reference_type'].contains(e.key))
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SelectableText(
                      '${labels[e.key]}: ${displayValue(e.value)}',
                      style: const TextStyle(height: 1.6),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
}

class RecordsPage extends StatefulWidget {
  final BonyeApi api;
  final String path, title;
  const RecordsPage(this.api, this.path, this.title, {super.key});
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  final List<Json> items = [];
  String? cursor;
  bool busy = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    load(reset: true);
  }

  Future<void> load({bool reset = false}) async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await widget.api.request(
        'GET',
        '${widget.path}${!reset && cursor != null ? '?cursor=${Uri.encodeQueryComponent(cursor!)}' : ''}',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) {
          items.clear();
        }
        final rows = data['items'];
        if (rows is List) {
          for (final row in rows.cast<Json>()) {
            if (!items.any((i) => i['id'] != null && i['id'] == row['id'])) {
              items.add(row);
            }
          }
        } else {
          items.add(data);
        }
        cursor = data['pagination']?['next_cursor'] as String?;
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = e);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: RefreshIndicator(
          onRefresh: () => load(reset: true),
          child: PageBody(
            children: [
              ...items.map(RecordCard.new),
              if (busy) const Center(child: CircularProgressIndicator()),
              if (error != null)
                Text(
                  error is ApiError
                      ? (error as ApiError).message
                      : 'دریافت اطلاعات انجام نشد.',
                ),
              if (!busy && items.isEmpty && error == null)
                const Text('هنوز اطلاعاتی ثبت نشده است.'),
              if (!busy && (cursor != null || error != null))
                OutlinedButton(
                  onPressed: () => load(reset: items.isEmpty),
                  child: Text(error != null ? 'تلاش دوباره' : 'نمایش بیشتر'),
                ),
            ],
          ),
        ),
      );
}
