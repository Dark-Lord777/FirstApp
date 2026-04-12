import 'package:flutter/material.dart';
import 'base_anim_btn.dart';  // ← ПРАВИЛЬНЫЙ ИМПОРТ (без ./widgets/)

Future<String?> showAddSectorDialog(BuildContext context) {
  final TextEditingController textController = TextEditingController();

  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2A1A3A),
                Color(0xFF1A1A2E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(  // ← Border.all (не Bolder.all)
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Color(0xFFB874EC).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ЗАГОЛОВОК
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFB874EC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFFB874EC),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),  // ← width: 12 (с двоеточием)
                  Text(
                    "Add New Sector",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // ПОЛЕ ВВОДА
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: textController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: "Enter sector name...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),  // ← Colors.white (не color.white)
                    ),
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFFB874EC).withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  autofocus: true,
                  onSubmitted: (_) {
                    if (textController.text.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, textController.text.trim());
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // КНОПКИ
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // CANCEL
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, null);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),  // ← width: 12
                  
                  // ADD кнопка
                  SizedBox(
                    width: 100,
                    child: BaseAnimatedButton(  // ← BaseAnimatedButton (не BaseAnimationButton)
                      text: "Add",
                      onPressed: () {
                        final text = textController.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(dialogContext, text);
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text("Please enter sector name"),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      gradientColors: [
                        Color(0xFFB874EC),
                        Color(0xFF7D41B8),
                      ],
                      textColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      fontSize: 16,  // ← fontSize (не fontsize)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
