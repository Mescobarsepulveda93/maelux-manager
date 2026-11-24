import 'package:flutter/material.dart';

import '../services/auth_service.dart';

// ==========================================================
// PANTALLA DE ACCESO PRIVADO
// ==========================================================

/// Permite que las personas autorizadas accedan al área
/// administrativa de MAELUX mediante correo y contraseña.
///
/// Las cuentas se crean exclusivamente desde Firebase Console.
/// Esta pantalla no permite el registro público de usuarios.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ========================================================
  // SERVICIO DE AUTENTICACIÓN
  // ========================================================

  /// Servicio compartido encargado de gestionar la sesión.
  final AuthService authService = AuthService.instancia;

  // ========================================================
  // FORMULARIO Y CONTROLADORES
  // ========================================================

  /// Clave utilizada para validar conjuntamente los campos.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Correo electrónico de la cuenta autorizada.
  final TextEditingController correoController = TextEditingController();

  /// Contraseña de la cuenta autorizada.
  final TextEditingController contrasenaController = TextEditingController();

  // ========================================================
  // ESTADO DE LA INTERFAZ
  // ========================================================

  /// Indica si se está procesando una solicitud.
  bool procesando = false;

  /// Controla si la contraseña está visible.
  bool mostrarContrasena = false;

  // ========================================================
  // INICIO DE SESIÓN
  // ========================================================

  /// Valida los campos e intenta iniciar sesión.
  Future<void> _iniciarSesion() async {
    final bool formularioValido = _formKey.currentState?.validate() ?? false;

    if (!formularioValido || procesando) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      procesando = true;
    });

    final String? error = await authService.iniciarSesion(
      correo: correoController.text,
      contrasena: contrasenaController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      procesando = false;
    });

    // Si el acceso fue correcto, AuthGate detectará
    // automáticamente la nueva sesión.
    if (error == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  // ========================================================
  // RECUPERACIÓN DE CONTRASEÑA
  // ========================================================

  /// Envía un correo para restablecer la contraseña.
  Future<void> _recuperarContrasena() async {
    if (procesando) {
      return;
    }

    final String correo = correoController.text.trim();

    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce primero tu correo electrónico.'),
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      procesando = true;
    });

    final String? error = await authService.enviarRecuperacion(correo: correo);

    if (!mounted) {
      return;
    }

    setState(() {
      procesando = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));

      return;
    }

    // Se utiliza un mensaje general para no revelar
    // públicamente qué correos están registrados.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Si el correo corresponde a una cuenta autorizada, '
          'recibirás instrucciones para restablecer la contraseña.',
        ),
      ),
    );
  }

  // ========================================================
  // VALIDACIONES
  // ========================================================

  /// Comprueba que el correo tenga una estructura básica válida.
  String? _validarCorreo(String? valor) {
    final String correo = valor?.trim() ?? '';

    if (correo.isEmpty) {
      return 'Introduce tu correo electrónico.';
    }

    final bool formatoValido = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(correo);

    if (!formatoValido) {
      return 'Introduce un correo electrónico válido.';
    }

    return null;
  }

  /// Comprueba que la contraseña no esté vacía.
  String? _validarContrasena(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Introduce tu contraseña.';
    }

    return null;
  }

  // ========================================================
  // LIBERACIÓN DE RECURSOS
  // ========================================================

  @override
  void dispose() {
    correoController.dispose();
    contrasenaController.dispose();

    super.dispose();
  }

  // ========================================================
  // INTERFAZ
  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ------------------------------------
                        // PRESENTACIÓN
                        // ------------------------------------
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'MAELUX Manager',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Acceso privado para personal autorizado',
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // ------------------------------------
                        // CORREO ELECTRÓNICO
                        // ------------------------------------
                        TextFormField(
                          controller: correoController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validarCorreo,
                        ),

                        const SizedBox(height: 16),

                        // ------------------------------------
                        // CONTRASEÑA
                        // ------------------------------------
                        TextFormField(
                          controller: contrasenaController,
                          obscureText: !mostrarContrasena,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.password_outlined),
                            suffixIcon: IconButton(
                              onPressed: procesando
                                  ? null
                                  : () {
                                      setState(() {
                                        mostrarContrasena = !mostrarContrasena;
                                      });
                                    },
                              tooltip: mostrarContrasena
                                  ? 'Ocultar contraseña'
                                  : 'Mostrar contraseña',
                              icon: Icon(
                                mostrarContrasena
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validarContrasena,
                          onFieldSubmitted: (_) {
                            _iniciarSesion();
                          },
                        ),

                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: procesando ? null : _recuperarContrasena,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ------------------------------------
                        // BOTÓN PRINCIPAL
                        // ------------------------------------
                        FilledButton.icon(
                          onPressed: procesando ? null : _iniciarSesion,
                          icon: procesando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            procesando
                                ? 'INICIANDO SESIÓN...'
                                : 'INICIAR SESIÓN',
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Las cuentas administrativas son creadas '
                          'exclusivamente por MAELUX.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
