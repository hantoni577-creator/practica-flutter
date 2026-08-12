import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Cargando extends StatelessWidget {
  const Cargando({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class VistaError extends StatelessWidget {
  const VistaError({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.peligro),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textoSecundario),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class SinDatos extends StatelessWidget {
  const SinDatos({super.key, this.mensaje = 'No hay datos registrados.'});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textoSecundario),
        ),
      ),
    );
  }
}

class ItemMenu extends StatelessWidget {
  const ItemMenu({
    super.key,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    required this.onTap,
    this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final VoidCallback onTap;
  final Color? colorIcono;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primario,
                foregroundColor: Colors.white,
                child: Icon(icono, color: colorIcono ?? Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primario,
                      ),
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textoSecundario,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}

class TituloSeccion extends StatelessWidget {
  const TituloSeccion({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primario,
        ),
      ),
    );
  }
}

class TextoErrores extends StatelessWidget {
  const TextoErrores({super.key, required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    if (mensaje.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        mensaje,
        style: const TextStyle(color: AppTheme.peligro, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}
