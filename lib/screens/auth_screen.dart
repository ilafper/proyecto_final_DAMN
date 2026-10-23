import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/bbdd_service.dart';
import 'admin_screen.dart';
import 'user_screen.dart';

// vista de login y registro
enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _authMode = AuthMode.login;

  final AuthService _authService = AuthService();

  // Controllers para Login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Controllers para Registro
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  bool _obscureLoginPassword = true;
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final respuesta = await _authService.login(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (respuesta['success'] == true) {
      final usuario = respuesta['usuario'];
      final String rol = (usuario['rol'] ?? 'cliente').toString().toLowerCase();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${usuario['nombre'] ?? usuario['nombre_completo'] ?? usuario['email']}!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Redirigir según el rol recibido del backend
      if (rol == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminScreen(usuario: usuario),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserScreen(usuario: usuario),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final respuesta = await _authService.registro(
      email: _regEmailController.text.trim(),
      password1: _regPasswordController.text,
      password2: _regConfirmPasswordController.text,
      nombre: _regNameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (respuesta['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? 'Cuenta de usuario creada exitosamente'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Cambiamos a pestaña de login y rellenamos los datos
      setState(() {
        _authMode = AuthMode.login;
        _loginEmailController.text = _regEmailController.text.trim();
        _loginPasswordController.text = _regPasswordController.text;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? 'Error al crear la cuenta'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Logo sobrio y encabezado
                  _buildBrandHeader(),
                  const SizedBox(height: 32),

                  // 2. Selector sobrio de pestaña (Iniciar Sesión / Registrarse)
                  _buildSegmentedSwitch(),
                  const SizedBox(height: 28),

                  // 3. Formulario activo con animación de desvanecimiento
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _authMode == AuthMode.login
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: _buildLoginForm(),
                    secondChild: _buildRegisterForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header de la marca
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.domain_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'ESPACIOS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _authMode == AuthMode.login
              ? 'Introduce tus credenciales para acceder'
              : 'Completa los datos para registrarte',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  // Switch de pestañas
  Widget _buildSegmentedSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              title: 'Iniciar Sesión',
              mode: AuthMode.login,
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              title: 'Registrarse',
              mode: AuthMode.register,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({required String title, required AuthMode mode}) {
    final isSelected = _authMode == mode;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _authMode = mode;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  // Formulario de Login
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: AppTheme.textMuted),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Introduce tu correo';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Correo no válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscureLoginPassword = !_obscureLoginPassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Introduce tu contraseña';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Se enviará un correo para restablecer la contraseña'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  // Formulario de Registro
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          TextFormField(
            controller: _regNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.textMuted),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Introduce tu nombre' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: AppTheme.textMuted),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Introduce un correo';
              if (!value.contains('@') || !value.contains('.')) return 'Correo no válido';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscureRegPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscureRegPassword = !_obscureRegPassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Introduce una contraseña';
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regConfirmPasswordController,
            obscureText: _obscureRegConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                onPressed: () {
                  setState(() => _obscureRegConfirmPassword = !_obscureRegConfirmPassword);
                },
              ),
            ),
            validator: (value) {
              if (value != _regPasswordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitRegister,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Crear Cuenta'),
          ),
        ],
      ),
    );
  }
}
