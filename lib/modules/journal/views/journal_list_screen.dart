import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import '../../../data/models/journal/controllers/journal_controller.dart';
import '../../../data/models/journal_model.dart';
import '../../../core/bindings/theme_controller.dart';

class JournalListScreen extends StatelessWidget {
  final JournalController _journalController = Get.find<JournalController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      appBar: AppBar(
        title: Text('Journal Entries',
            style: TextStyle(color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add,
                color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black),
            onPressed: () {
              _showAddEditJournalDialog();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _themeController.themeMode.value == ThemeMode.dark
                ? [const Color(0xFF1E1E2C), const Color(0xFF2D2E40)]
                : [Colors.white, Colors.grey.shade200],
          ),
        ),
        child: SafeArea(
          child: Obx(() => _journalController.isLoading.value
              ? Center(child: CircularProgressIndicator(
            color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.purple,
          ))
              : _journalController.journals.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, size: 64,
                    color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white54 : Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No journal entries yet',
                  style: TextStyle(
                      fontSize: 18,
                      color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first entry',
                  style: TextStyle(
                      color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white70 : Colors.grey
                  ),
                ),
              ],
            ),
          )
              : AnimationLimiter(
            child: ListView.builder(
              itemCount: _journalController.journals.length,
              itemBuilder: (context, index) {
                final journal = _journalController.journals[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildJournalItem(journal),
                    ),
                  ),
                );
              },
            ),
          )),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditJournalDialog();
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.purple,
      ),
    ));
  }

  Widget _buildJournalItem(JournalEntry journal) {
    return Obx(() => Dismissible(
      key: Key(journal.id),
      background: Container(
        color: Colors.red.withOpacity(0.3),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete,
            color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: Get.context!,
          builder: (context) => AlertDialog(
            backgroundColor: _themeController.themeMode.value == ThemeMode.dark
                ? const Color(0xFF2D2E40)
                : Colors.white,
            title: Text('Confirm Delete',
                style: TextStyle(
                    color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                )),
            content: Text('Are you sure you want to delete this journal entry?',
                style: TextStyle(
                    color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white70 : Colors.grey
                )),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Cancel',
                    style: TextStyle(
                        color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white70 : Colors.grey
                    )),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _journalController.deleteJournal(journal.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: _themeController.themeMode.value == ThemeMode.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _themeController.themeMode.value == ThemeMode.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  journal.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(journal.content,
                        style: TextStyle(
                            color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white70 : Colors.grey
                        )),
                    const SizedBox(height: 8),
                    Text(
                      'Updated: ${DateFormat('MMM dd, yyyy - HH:mm').format(journal.updatedAt)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white54 : Colors.grey
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit,
                      color: _themeController.themeMode.value == ThemeMode.dark ? Colors.blue : Colors.purple),
                  onPressed: () {
                    _showAddEditJournalDialog(journal: journal);
                  },
                ),
                onTap: () {
                  _showJournalDetailDialog(journal);
                },
              ),
            ),
          ),
        ),
      ),
    ));
  }

  void _showAddEditJournalDialog({JournalEntry? journal}) {
    TextEditingController titleController = TextEditingController(text: journal?.title ?? '');
    TextEditingController contentController = TextEditingController(text: journal?.content ?? '');

    showDialog(
      context: Get.context!,
      builder: (context) {
        return Obx(() => Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: _themeController.themeMode.value == ThemeMode.dark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _themeController.themeMode.value == ThemeMode.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    journal == null ? 'Add Journal Entry' : 'Edit Journal Entry',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                        color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Title',
                      labelStyle: TextStyle(
                          color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white70 : Colors.grey
                      ),
                      filled: true,
                      fillColor: _themeController.themeMode.value == ThemeMode.dark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    style: TextStyle(
                        color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: 'Content',
                      labelStyle: TextStyle(
                          color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white70 : Colors.grey
                      ),
                      filled: true,
                      fillColor: _themeController.themeMode.value == ThemeMode.dark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel',
                            style: TextStyle(
                                color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                            )),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isEmpty || contentController.text.isEmpty) {
                            Get.snackbar(
                              'Error',
                              'Please fill all fields',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }

                          if (journal == null) {
                            _journalController.addJournal(
                              titleController.text,
                              contentController.text,
                            );
                          } else {
                            _journalController.updateJournal(
                              journal.id,
                              titleController.text,
                              contentController.text,
                            );
                          }

                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: Text(journal == null ? 'Add' : 'Update', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  void _showJournalDetailDialog(JournalEntry journal) {
    showDialog(
      context: Get.context!,
      builder: (context) {
        return Obx(() => Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: _themeController.themeMode.value == ThemeMode.dark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _themeController.themeMode.value == ThemeMode.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journal.title,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white : Colors.black
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(journal.content,
                      style: TextStyle(
                          color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white70 : Colors.grey
                      )),
                  const SizedBox(height: 16),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy - HH:mm').format(journal.createdAt)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white54 : Colors.grey
                    ),
                  ),
                  Text(
                    'Updated: ${DateFormat('MMM dd, yyyy - HH:mm').format(journal.updatedAt)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: _themeController.themeMode.value == ThemeMode.dark ? Colors.white54 : Colors.grey
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Close', style: TextStyle(color: Colors.purple)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }
}