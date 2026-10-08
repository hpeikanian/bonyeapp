import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api.dart';
import '../core/widgets.dart';
import 'reminders.dart';

class ClubPage extends StatelessWidget {
  final BonyeApi api;
  const ClubPage({super.key, required this.api});
  @override
  Widget build(BuildContext context) => RemoteView(
        load: () => api.request('GET', '/club'),
        builder: (data, reload) => PageBody(
          children: [
            const SectionTitle(
              'باشگاه بنیه',
              'خرید، امتیاز و مزایای شما؛ یک حساب مشترک در سایت و شعب.',
            ),
            InfoCard('امتیاز شما', '${data['points'] ?? 0}', Icons.stars),
            InfoCard(
              'سطح عضویت',
              '${data['tier']?['name'] ?? 'عضو باشگاه'}',
              Icons.workspace_premium,
            ),
            InfoCard(
              'اعتبار خرید',
              money(data['credit']?['amount']),
              Icons.confirmation_number_outlined,
            ),
            const Text(
              'اعتبار باشگاه کوپن خرید است و امکان برداشت نقدی ندارد.',
            ),
            ...<String, String>{
              '/club/tier': 'سطح و مزایا',
              '/club/points/transactions': 'گردش امتیاز',
              '/club/credit/transactions': 'گردش اعتبار',
              '/club/coupons': 'کوپن‌های من',
              '/club/rewards': 'پاداش‌ها',
              '/club/activity': 'فعالیت‌های باشگاه',
              '/orders': 'خریدهای من',
              '/reminders': 'یادآوری خرید مجدد',
            }.entries.map(
                  (e) => Card(
                    child: ListTile(
                      title: Text(e.value),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => push(
                        context,
                        e.key == '/reminders'
                            ? RemindersPage(api: api)
                            : RecordsPage(api, e.key, e.value),
                      ),
                    ),
                  ),
                ),
            FilledButton(
              onPressed: () => push(context, ConvertPoints(api: api)),
              child: const Text('تبدیل امتیاز به اعتبار خرید'),
            ),
            OutlinedButton(
              onPressed: () => push(context, ReferralPage(api: api)),
              child: const Text('معرفی دوستان'),
            ),
          ],
        ),
      );
}

class ConvertPoints extends StatefulWidget {
  final BonyeApi api;
  const ConvertPoints({super.key, required this.api});
  @override
  State<ConvertPoints> createState() => _ConvertPointsState();
}

class _ConvertPointsState extends State<ConvertPoints> {
  final points = TextEditingController();
  bool busy = false;
  String key = operationKey();
  Json? result;
  @override
  void dispose() {
    points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تبدیل امتیاز')),
        body: PageBody(
          children: [
            const Text(
              'نرخ تبدیل و شرایط کوپن با قوانین فعلی باشگاه تعیین می‌شود.',
            ),
            TextField(
              controller: points,
              enabled: !busy,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                key = operationKey();
                result = null;
              },
              decoration: const InputDecoration(labelText: 'تعداد امتیاز'),
            ),
            FilledButton(
              onPressed: busy || result != null
                  ? null
                  : () async {
                      final n = int.tryParse(normalizeDigits(points.text));
                      if (n == null || n < 1) {
                        showError(
                          context,
                          ApiError('invalid_points', status: 422),
                        );
                        return;
                      }
                      final approved = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تبدیل امتیاز'),
                          content: Text('$n امتیاز به کوپن خرید تبدیل شود؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('انصراف'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('تبدیل'),
                            ),
                          ],
                        ),
                      );
                      if (approved != true || !mounted) {
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        final r = await widget.api.request(
                          'POST',
                          '/club/credit/convert',
                          body: {'points': n},
                          key: key,
                        );
                        if (mounted) {
                          setState(() => result = r);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showError(context, e);
                        }
                      } finally {
                        if (mounted) {
                          setState(() => busy = false);
                        }
                      }
                    },
              child: const Text('تبدیل به کوپن'),
            ),
            if (result != null) RecordCard(result!),
          ],
        ),
      );
}

class ReferralPage extends StatefulWidget {
  final BonyeApi api;
  const ReferralPage({super.key, required this.api});
  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  final code = TextEditingController();
  bool busy = false;
  String joinKey = operationKey();
  final createKey = operationKey();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('معرفی دوستان')),
        body: RemoteView(
          load: () => widget.api.request('GET', '/club/referrals'),
          builder: (data, reload) => PageBody(
            children: [
              RecordCard(data),
              if (data['code'] != null)
                OutlinedButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: data['code'] as String),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('کپی کد معرفی'),
                ),
              if (data['code'] == null)
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          try {
                            await widget.api.request(
                              'POST',
                              '/club/referrals/code',
                              key: createKey,
                            );
                            if (mounted) {
                              reload();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showError(context, e);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => busy = false);
                            }
                          }
                        },
                  child: const Text('دریافت کد معرفی'),
                ),
              if (data['has_referrer'] != true) ...[
                TextField(
                  controller: code,
                  enabled: !busy,
                  onChanged: (_) => joinKey = operationKey(),
                  decoration: const InputDecoration(
                    labelText: 'کد کسی که شما را معرفی کرده',
                  ),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          try {
                            await widget.api.request(
                              'POST',
                              '/club/referrals/join',
                              body: {'code': code.text.trim()},
                              key: joinKey,
                            );
                            if (mounted) {
                              reload();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showError(context, e);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => busy = false);
                            }
                          }
                        },
                  child: const Text('ثبت معرف'),
                ),
              ],
            ],
          ),
        ),
      );
}
