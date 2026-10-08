import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/widgets.dart';

class LoginPage extends StatefulWidget {
  final BonyeApi api;
  const LoginPage({super.key, required this.api});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final mobile = TextEditingController(),
      password = TextEditingController(),
      code = TextEditingController(),
      name = TextEditingController();
  bool busy = false;
  String purpose = 'login';
  String? challenge;
  Object? error;
  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
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
  void dispose() {
    mobile.dispose();
    password.dispose();
    code.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: PageBody(
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.pets, size: 72, color: brand),
                  const SectionTitle(
                    'همراه همیشگی پت شما',
                    'برنامه غذایی، آموزش و تمام مزایای باشگاه بنیه در یک جا.',
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'login', label: Text('ورود')),
                      ButtonSegment(value: 'register', label: Text('عضویت')),
                      ButtonSegment(value: 'recovery', label: Text('بازیابی')),
                    ],
                    selected: {purpose},
                    onSelectionChanged: busy
                        ? null
                        : (v) => setState(() {
                              purpose = v.first;
                              challenge = null;
                              error = null;
                              code.clear();
                            }),
                  ),
                  TextField(
                    controller: mobile,
                    enabled: !busy && challenge == null,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration:
                        const InputDecoration(labelText: 'شماره موبایل'),
                  ),
                  if (purpose == 'register')
                    TextField(
                      controller: name,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'نام و نام خانوادگی',
                      ),
                    ),
                  if (purpose != 'login' || challenge == null)
                    TextField(
                      controller: password,
                      enabled: !busy,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: purpose == 'login'
                            ? 'رمز عبور'
                            : 'رمز جدید (حداقل ۱۲ کاراکتر)',
                      ),
                    ),
                  if (challenge != null)
                    TextField(
                      controller: code,
                      enabled: !busy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'کد پیامکی'),
                    ),
                  if (error != null)
                    Text(
                      error is ApiError
                          ? (error as ApiError).message
                          : 'ورود انجام نشد.',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => run(() async {
                              if (challenge != null) {
                                await widget.api.verify(
                                  challenge!,
                                  code.text,
                                  name: purpose == 'register'
                                      ? name.text.trim()
                                      : null,
                                  password:
                                      purpose == 'login' ? null : password.text,
                                );
                              } else if (purpose == 'login') {
                                await widget.api
                                    .login(mobile.text, password.text);
                              } else {
                                final data = await widget.api.challenge(
                                  mobile.text,
                                  purpose,
                                );
                                if (mounted) {
                                  setState(
                                    () => challenge =
                                        data['challenge_id'] as String,
                                  );
                                }
                              }
                            }),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            challenge != null
                                ? 'تأیید و ادامه'
                                : purpose == 'login'
                                    ? 'ورود به بنیه'
                                    : 'دریافت کد تأیید',
                          ),
                  ),
                  if (purpose == 'login' && challenge == null)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => run(() async {
                                final data = await widget.api.challenge(
                                  mobile.text,
                                  'login',
                                );
                                if (mounted) {
                                  setState(
                                    () => challenge =
                                        data['challenge_id'] as String,
                                  );
                                }
                              }),
                      child: const Text('ورود با کد پیامکی'),
                    ),
                  if (challenge != null)
                    TextButton(
                      onPressed:
                          busy ? null : () => setState(() => challenge = null),
                      child: const Text('تغییر شماره یا درخواست کد جدید'),
                    ),
                  const Text(
                    'حساب شما همان حساب باشگاه مشتریان بنیه است. ثبت‌نام و ورود پیامکی به فعال بودن سرویس پیامک بستگی دارد.',
                    style: TextStyle(color: Colors.black54, height: 1.8),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
