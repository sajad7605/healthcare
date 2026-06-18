import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true; // true = Login (2 fields), false = Register (6 fields)
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _parentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _parentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Simulate successful login/register
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Playful Cloud Frame Header with Kids & Tooth illustration
              SizedBox(
                height: 260,
                width: double.infinity,
                child: CustomPaint(
                  painter: AuthHeaderPainter(),
                ),
              ),
              const SizedBox(height: 20),

              // Title Header
              Text(
                _isLogin ? 'ورود به حساب دندون‌یار' : 'ساخت حساب کاربری جدید',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'برای ورود شماره موبایل و رمز عبور خود را وارد کنید' : 'اطلاعات دندان‌پزشکی کوچولوی قهرمان را تکمیل کنید',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Input Form Container (with auto-resizing height)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutBack,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Button (Blue full-width)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SquishPopButton(
                  onTap: _submit,
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF35B8FF), Color(0xFF00A2E8)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A2E8).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _isLogin ? 'ورود' : 'ثبت نام و شروع',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Switch Link
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? 'ثبت نام نکرده‌اید؟ حساب جدید بسازید' : 'قبلاً ثبت نام کرده‌اید؟ وارد شوید',
                  style: const TextStyle(
                    color: Color(0xFF00A2E8),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Login Form with 2 fields
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('LoginFormKey'),
      children: [
        _buildInputField(
          controller: _phoneController,
          label: 'شماره تلفن همراه',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً شماره تلفن خود را وارد کنید';
            }
            if (value.length < 10) {
              return 'شماره تلفن معتبر نیست';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _passwordController,
          label: 'رمز عبور',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً رمز عبور را وارد کنید';
            }
            if (value.length < 4) {
              return 'رمز عبور باید حداقل ۴ رقم باشد';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Registration Form with 6 fields
  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('RegisterFormKey'),
      children: [
        _buildInputField(
          controller: _nameController,
          label: 'نام کودک قهرمان',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً نام کودک را وارد کنید';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _ageController,
          label: 'سن کودک',
          icon: Icons.child_care_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً سن کودک را وارد کنید';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _phoneController,
          label: 'شماره تلفن همراه والدین',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً شماره تلفن را وارد کنید';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _parentController,
          label: 'نام پدر یا مادر',
          icon: Icons.family_restroom,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً نام یکی از والدین را وارد کنید';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _passwordController,
          label: 'رمز عبور دلخواه',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً رمز عبور را وارد کنید';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'تکرار رمز عبور',
          icon: Icons.lock_reset,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'لطفاً تکرار رمز عبور را وارد کنید';
            }
            if (value != _passwordController.text) {
              return 'رمز عبور مطابقت ندارد';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Rounded Input Field builder helper
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF2C3E50),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF00A2E8)),
        filled: true,
        fillColor: const Color(0xFFF8FCFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF35B8FF).withOpacity(0.15),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF00A2E8),
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
