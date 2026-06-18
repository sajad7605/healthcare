import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    child: CustomPaint(
                      painter: ToothPainter(expression: 'happy'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'کودک قهرمان: سجاد عزیز',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  'سن: ۷ سال',
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
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.bar_chart_outlined,
                        title: 'گزارش هفتگی سلامت',
                        subtitle: 'نمودار ستاره‌های کسب شده در هفته',
                        color: const Color(0xFFF39C12),
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.manage_accounts_outlined,
                        title: 'تغییر اطلاعات پروفایل کودک',
                        subtitle: 'به‌روزرسانی سن، نام یا تصویر پروفایل',
                        color: const Color(0xFF2ECC71),
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'راهنمایی و پشتیبانی',
                        subtitle: 'پاسخ به سوالات رایج دندانپزشکی',
                        color: const Color(0xFF95A5A6),
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      _buildSettingsTile(
                        icon: Icons.logout,
                        title: 'خروج از حساب کاربری',
                        subtitle: 'خروج موقت و بازگشت به صفحه ورود',
                        color: const Color(0xFFFF7675),
                        onTap: () {
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
