import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet_species.dart';
import '../services/pet_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

/// Экран создания уникального питомца: выбор вида + имя.
class CreatePetScreen extends StatefulWidget {
  const CreatePetScreen({super.key});

  @override
  State<CreatePetScreen> createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
  late PetSpecies _selected;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _selected = PetSpecies.all.first;
    _nameController =
        TextEditingController(text: _selected.defaultName);
  }

  void _pick(PetSpecies s) {
    if (s.id == _selected.id) return;
    setState(() {
      _selected = s;
      // Предлагаем имя вида, если пользователь не менял его вручную.
      _nameController.text = s.defaultName;
    });
  }

  void _create() {
    final service = context.read<PetService>();
    service.createPet(_nameController.text, _selected.id);
    Navigator.of(context).pushReplacement(
      const MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.ink),
                  ),
                  const Expanded(
                    child: Text(
                      'Создай питомца',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Кто будет твоим финансовым другом?',
                style:
                    TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Выбор вида.
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: PetSpecies.all.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final s = PetSpecies.all[i];
                          final selected = s.id == _selected.id;
                          return GestureDetector(
                            onTap: () => _pick(s),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              width: 84,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? s.color.withValues(alpha: 0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? s.color
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: selected
                                        ? s.color
                                            .withValues(alpha: 0.3)
                                        : Colors.black
                                            .withValues(alpha: 0.05),
                                    blurRadius: selected ? 14 : 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(s.stageEmojis[0],
                                      style:
                                          const TextStyle(fontSize: 34)),
                                  const SizedBox(height: 6),
                                  Text(
                                    s.displayName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? s.color
                                          : AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _selected.tagline,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Поле имени.
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _nameController,
                        maxLength: 14,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Имя питомца',
                          hintStyle:
                              const TextStyle(color: AppColors.inkSoft),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Превью + создание.
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _selected.color.withValues(alpha: 0.25),
                            _selected.color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _selected.color
                                      .withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(_selected.stageEmojis[0],
                                  style:
                                      const TextStyle(fontSize: 56)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nameController.text.isEmpty
                                ? _selected.defaultName
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: _create,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🐾', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            'Создать питомца',
                            style: TextStyle(fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
