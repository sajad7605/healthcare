import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final activeChild = HealthcareApi.instance.currentChild;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE0F7FA), // Light Cyan theme
                Color(0xFFF5FDFD),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SquishPopButton(
                        onTap: () => Navigator.of(context).pop(),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                        ),
                      ),
                      const Text(
                        'تنظیمات سلامت دندان',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Giant Tooth Avatar
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: activeChild?.avatarUrl != null && activeChild!.avatarUrl!.startsWith('http')
                        ? ClipOval(
                            child: Image.network(
                              activeChild.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => CustomPaint(
                                painter: ToothPainter(expression: 'happy'),
                              ),
                            ),
                          )
                        : CustomPaint(
                            painter: ToothPainter(expression: 'happy'),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'کودک قهرمان: ${activeChild?.childName ?? 'مهمان'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  'سن: ${activeChild?.childAge ?? 0} سال',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 30),

                // Settings List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSettingsTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'یادآوری مسواک صبح و شب',
                        subtitle: 'تنظیم ساعت‌های هشدار روزانه',
                        color: const Color(0xFF00D2D3),
                        onTap: _showReminderDialog,
                      ),
                      _buildSettingsTile(
                        icon: Icons.bar_chart_outlined,
                        title: 'گزارش دستاوردها و جوایز',
                        subtitle: 'مشاهده ستاره‌ها، مدال‌ها و جوایز کسب شده',
                        color: const Color(0xFFF39C12),
                        onTap: () => Navigator.pushNamed(context, '/achievements'),
                      ),
                      _buildSettingsTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'تغییر اطلاعات پروفایل کودک',
                        subtitle: 'به‌روزرسانی سن، نام یا تصویر پروفایل',
                        color: const Color(0xFF2ECC71),
                        onTap: _showProfileUpdateDialog,
                      ),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'راهنمایی و پشتیبانی',
                        subtitle: 'پاسخ به سوالات رایج دندانپزشکی و اطلاعات تماس',
                        color: const Color(0xFF95A5A6),
                        onTap: _showSupportDialog,
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsTile(
                        icon: Icons.logout,
                        title: 'خروج از حساب کاربری',
                        subtitle: 'خروج موقت و بازگشت به صفحه ورود',
                        color: const Color(0xFFFF7675),
                        onTap: () {
                          HealthcareApi.instance.apiClient.setAuthToken(null);
                          HealthcareApi.instance.currentParent = null;
                          HealthcareApi.instance.currentChild = null;
                          HealthcareApi.instance.childrenList = null;
                          Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReminderDialog() async {
    final activeChild = HealthcareApi.instance.currentChild;
    if (activeChild == null) {
      _showSnack('لطفاً ابتدا وارد حساب کاربری شوید.');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00D2D3))),
    );

    NotificationSettings settings;
    try {
      settings = await HealthcareApi.instance.children.getReminderSettings(activeChild.id);
    } catch (_) {
      settings = NotificationSettings(
        morningReminderTime: '08:00',
        nightReminderTime: '21:00',
        pushNotificationsEnabled: true,
      );
    }
    if (!mounted) return;
    Navigator.pop(context); // close spinner

    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        return TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0);
      }
      return const TimeOfDay(hour: 8, minute: 0);
    }

    TimeOfDay morning = parseTime(settings.morningReminderTime);
    TimeOfDay night = parseTime(settings.nightReminderTime);
    bool enabled = settings.pushNotificationsEnabled;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Row(
                  children: [
                    Icon(Icons.alarm, color: Color(0xFF00D2D3)),
                    SizedBox(width: 8),
                    Text('تنظیم یادآوری مسواک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('فعال‌سازی هشدارها', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: enabled,
                      activeThumbColor: const Color(0xFF00D2D3),
                      onChanged: (val) => setDialogState(() => enabled = val),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_rounded, color: Colors.amber),
                      title: const Text('یادآوری صبح'),
                      trailing: Text(morning.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onTap: enabled
                          ? () async {
                              final picked = await showTimePicker(context: context, initialTime: morning);
                              if (picked != null) setDialogState(() => morning = picked);
                            }
                          : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
                      title: const Text('یادآوری شب'),
                      trailing: Text(night.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onTap: enabled
                          ? () async {
                              final picked = await showTimePicker(context: context, initialTime: night);
                              if (picked != null) setDialogState(() => night = picked);
                            }
                          : null,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D2D3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final newSettings = NotificationSettings(
                        morningReminderTime: '${morning.hour.toString().padLeft(2, '0')}:${morning.minute.toString().padLeft(2, '0')}',
                        nightReminderTime: '${night.hour.toString().padLeft(2, '0')}:${night.minute.toString().padLeft(2, '0')}',
                        pushNotificationsEnabled: enabled,
                      );
                      try {
                        await HealthcareApi.instance.children.updateReminderSettings(activeChild.id, newSettings);
                        _showSnack('تنظیمات یادآوری با موفقیت ذخیره شد! ⏰');
                      } catch (e) {
                        _showSnack('خطا در ذخیره تنظیمات: $e', isError: true);
                      }
                    },
                    child: const Text('ذخیره', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showProfileUpdateDialog() {
    final activeChild = HealthcareApi.instance.currentChild;
    if (activeChild == null) {
      _showSnack('لطفاً ابتدا وارد حساب کاربری شوید.');
      return;
    }

    final nameController = TextEditingController(text: activeChild.childName);
    final ageController = TextEditingController(text: activeChild.childAge.toString());
    final avatarController = TextEditingController(text: activeChild.avatarUrl ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.edit, color: Color(0xFF2ECC71)),
                SizedBox(width: 8),
                Text('ویرایش پروفایل کودک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'نام کودک',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'سن کودک (سال)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: avatarController,
                    decoration: InputDecoration(
                      labelText: 'آدرس اینترنتی آواتار (اختیاری)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.image),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final age = int.tryParse(ageController.text.trim()) ?? activeChild.childAge;
                  final avatar = avatarController.text.trim().isNotEmpty ? avatarController.text.trim() : null;

                  if (name.isEmpty) {
                    _showSnack('لطفاً نام کودک را وارد کنید.', isError: true);
                    return;
                  }

                  Navigator.pop(context);
                  try {
                    final updated = await HealthcareApi.instance.children.updateChild(
                      activeChild.id,
                      UpdateChildRequest(childName: name, childAge: age, avatarUrl: avatar),
                    );
                    setState(() {
                      HealthcareApi.instance.currentChild = updated;
                    });
                    _showSnack('پروفایل با موفقیت به‌روزرسانی شد! ✨');
                  } catch (e) {
                    _showSnack('خطا در به‌روزرسانی: $e', isError: true);
                  }
                },
                child: const Text('ذخیره تغییرات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.help_center_rounded, color: Color(0xFF34495E)),
                SizedBox(width: 8),
                Text('راهنمایی و پشتیبانی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFaqItem(
                    'چند بار در روز باید مسواک بزنیم؟',
                    'حداقل دو بار در روز: صبح بعد از صبحانه و شب قبل از خواب.',
                  ),
                  _buildFaqItem(
                    'آیا استفاده از نخ دندان برای کودکان لازم است؟',
                    'بله، به محض اینکه دو دندان در کنار هم قرار گرفتند، تمیز کردن بین آن‌ها با نخ دندان ضروری است.',
                  ),
                  _buildFaqItem(
                    'چگونه ستاره و مدال کسب کنیم؟',
                    'با استفاده از تایمر مسواک‌زنی، انجام چالش‌های روزانه و آپلود عکس دندان‌های تمیز در گالری.',
                  ),
                  const Divider(height: 24),
                  Row(
                    children: const [
                      Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2ECC71)),
                      SizedBox(width: 8),
                      Text('تلفن پشتیبانی: ۰۲۱-۱۲۳۴', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('پاسخگویی روزهای کاری از ساعت ۹ صبح تا ۱۷', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            actions: [
              Center(
                child: SquishPopButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34495E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('متوجه شدم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('❓ $question', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
          const SizedBox(height: 4),
          Text(answer, style: const TextStyle(fontSize: 13, color: Color(0xFF57606F), height: 1.4)),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF2ECC71),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
