import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/widgets.dart';

class AccountPage extends StatelessWidget {
  final BonyeApi api;
  const AccountPage({super.key, required this.api});
  @override
  Widget build(BuildContext context) => RemoteView(
      load: () => api.request('GET', '/me'),
      builder: (data, reload) => PageBody(children: [
            SectionTitle(
                '${data['name'] ?? 'حساب من'}', '${data['mobile'] ?? ''}'),
            RecordCard(data),
            OutlinedButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => ProfileForm(api: api, profile: data)));
                  if (context.mounted) {
                    reload();
                  }
                },
                child: const Text('ویرایش پروفایل')),
            ListTile(
                title: const Text('آدرس‌های من'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => push(context, AddressesPage(api: api))),
            ListTile(
                title: const Text('تنظیمات پیام‌ها'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => push(context, PreferencesPage(api: api))),
            ListTile(
                title: const Text('نشست‌های فعال'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => push(context, SessionsPage(api: api))),
            const Text(
                'ورود به فروشگاه اینترنتی مستقل است؛ رمز یا توکن اپ به مرورگر منتقل نمی‌شود.'),
            OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await api.logout();
                  } catch (e) {
                    if (context.mounted) {
                      showError(context, e);
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('خروج از حساب')),
          ]));
}

class ProfileForm extends StatefulWidget {
  final BonyeApi api;
  final Json profile;
  const ProfileForm({super.key, required this.api, required this.profile});
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late TextEditingController name, email;
  bool busy = false;
  String key = operationKey();
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.profile['name'] as String? ?? '');
    email =
        TextEditingController(text: widget.profile['email'] as String? ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('ویرایش پروفایل')),
      body: PageBody(children: [
        TextField(
            controller: name,
            enabled: !busy,
            onChanged: (_) => key = operationKey(),
            decoration: const InputDecoration(labelText: 'نام و نام خانوادگی')),
        TextField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => key = operationKey(),
            decoration: const InputDecoration(labelText: 'ایمیل')),
        FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await widget.api.request('PATCH', '/me',
                          body: {
                            'name': name.text.trim(),
                            'email': email.text.trim().isEmpty
                                ? null
                                : email.text.trim()
                          },
                          key: key);
                      if (context.mounted) {
                        Navigator.pop(context);
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
            child: const Text('ذخیره')),
      ]));
}

class AddressesPage extends StatelessWidget {
  final BonyeApi api;
  const AddressesPage({super.key, required this.api});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('آدرس‌های من')),
      body: RemoteView(
          load: () => api.request('GET', '/me/addresses?limit=100'),
          builder: (data, reload) => PageBody(children: [
                FilledButton(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => AddressForm(api: api)));
                      if (context.mounted) {
                        reload();
                      }
                    },
                    child: const Text('افزودن آدرس')),
                ...(data['items'] as List)
                    .cast<Json>()
                    .map((a) => Column(children: [
                          RecordCard(a),
                          OutlinedButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            AddressForm(api: api, address: a)));
                                if (context.mounted) {
                                  reload();
                                }
                              },
                              child: const Text('ویرایش آدرس'))
                        ])),
              ])));
}

class AddressForm extends StatefulWidget {
  final BonyeApi api;
  final Json? address;
  const AddressForm({super.key, required this.api, this.address});
  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final fields = <String, TextEditingController>{};
  final form = GlobalKey<FormState>();
  bool isDefault = false, busy = false;
  String key = operationKey();
  @override
  void initState() {
    super.initState();
    for (final f in [
      'label',
      'recipient_name',
      'mobile',
      'province',
      'city',
      'address',
      'postal_code'
    ]) {
      fields[f] =
          TextEditingController(text: widget.address?[f] as String? ?? '');
    }
    isDefault = widget.address?['is_default'] == true;
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('آدرس')),
      body: Form(
          key: form,
          onChanged: () => key = operationKey(),
          child: PageBody(children: [
            ...fields.entries.map((e) => TextFormField(
                controller: e.value,
                enabled: !busy,
                decoration: InputDecoration(
                    labelText: e.key == 'label' ? 'عنوان آدرس' : labels[e.key]),
                validator: (v) => !['label', 'mobile'].contains(e.key) &&
                        (v == null || v.trim().isEmpty)
                    ? 'این مورد لازم است.'
                    : null)),
            SwitchListTile(
                title: const Text('آدرس پیش‌فرض'),
                value: isDefault,
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                          isDefault = v;
                          key = operationKey();
                        })),
            FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) {
                          return;
                        }
                        setState(() => busy = true);
                        try {
                          await widget.api.request(
                              widget.address == null ? 'POST' : 'PATCH',
                              widget.address == null
                                  ? '/me/addresses'
                                  : '/me/addresses/${widget.address!['id']}',
                              body: {
                                for (final e in fields.entries)
                                  e.key:
                                      ['mobile', 'postal_code'].contains(e.key)
                                          ? normalizeDigits(e.value.text.trim())
                                          : e.value.text.trim(),
                                'is_default': isDefault
                              },
                              key: key);
                          if (context.mounted) {
                            Navigator.pop(context);
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
                child: const Text('ذخیره آدرس')),
          ])));
}

class PreferencesPage extends StatelessWidget {
  final BonyeApi api;
  const PreferencesPage({super.key, required this.api});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('تنظیمات پیام‌ها')),
      body: RemoteView(
          load: () => api.request('GET', '/me/preferences'),
          builder: (data, reload) => PageBody(children: [
                const Text(
                    'اعلان گوشی در API فعلی ارسال نمی‌شود؛ تنظیمات زیر مربوط به پیامک و ایمیل هستند.'),
                ...{
                  'sms_marketing': 'پیامک پیشنهادها و آموزش',
                  'sms_transactional': 'پیامک اطلاع‌رسانی خرید',
                  'email_marketing': 'ایمیل پیشنهادها و آموزش'
                }.entries.map((e) => SwitchListTile(
                    title: Text(e.value),
                    value: data[e.key] == true,
                    onChanged: (value) async {
                      try {
                        await api.request('PATCH', '/me/preferences', body: {
                          e.key: value,
                          'consent_version': 'bonye-app-v1'
                        });
                        if (context.mounted) {
                          reload();
                        }
                      } catch (error) {
                        if (context.mounted) {
                          showError(context, error);
                        }
                      }
                    })),
              ])));
}

class SessionsPage extends StatelessWidget {
  final BonyeApi api;
  const SessionsPage({super.key, required this.api});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('نشست‌های فعال')),
        body: RemoteView(
          load: () => api.request('GET', '/auth/sessions'),
          builder: (data, reload) => PageBody(children: [
            ...(data['items'] as List).cast<Json>().map((s) => Card(
                  child: ListTile(
                    title: Text('${s['device_name']}'),
                    subtitle: Text('${s['created_at']}'),
                    trailing: IconButton(
                      tooltip: 'ابطال نشست',
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        try {
                          await api.request(
                              'DELETE', '/auth/sessions/${s['id']}');
                          if (context.mounted) {
                            reload();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showError(context, e);
                          }
                        }
                      },
                    ),
                  ),
                )),
            OutlinedButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                            title: const Text('خروج از همه دستگاه‌ها؟'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('انصراف')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('خروج')),
                            ],
                          ));
                  if (ok != true) {
                    return;
                  }
                  try {
                    await api.request('POST', '/auth/revoke-all');
                    await api.forget();
                  } catch (e) {
                    if (context.mounted) {
                      showError(context, e);
                    }
                  }
                },
                child: const Text('خروج از همه دستگاه‌ها')),
          ]),
        ),
      );
}
