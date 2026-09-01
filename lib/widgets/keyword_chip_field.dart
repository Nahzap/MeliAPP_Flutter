import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme_config.dart';
import '../models/search_models.dart';

/// Campo de búsqueda que acumula palabras clave como chips.
///
/// Equivale al `keywordBox` de la web: el usuario no escribe frases, va
/// sumando términos. Retroceso con el campo vacío elimina el último chip.
class KeywordChipField extends StatelessWidget {
  final List<KeywordChip> chips;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final ValueChanged<KeywordChip> onRemove;
  final VoidCallback onBackspaceEmpty;
  final bool isBusy;

  const KeywordChipField({
    super.key,
    required this.chips,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onRemove,
    required this.onBackspaceEmpty,
    this.isBusy = false,
  });

  bool get _isFull => chips.length >= 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppTheme.slate400, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips.map(_buildChip),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140),
                  child: _buildInput(context),
                ),
              ],
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(KeywordChip chip) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.amber100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chip.term,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () => onRemove(chip),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 15,
                color: const Color(0xFF92400E).withValues(alpha: 0.8),
                semanticLabel: 'Quitar ${chip.term}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            controller.text.isEmpty &&
            chips.isNotEmpty) {
          onBackspaceEmpty();
        }
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !_isFull,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          hintText: _hintText,
          hintStyle: TextStyle(color: AppTheme.slate400, fontSize: 14),
        ),
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }

  String get _hintText {
    if (_isFull) return 'Máximo 5 palabras clave';
    if (chips.isEmpty) return 'Ej: ulmo, Valdivia, polen de tineo';
    return 'Añade otra palabra clave';
  }
}
