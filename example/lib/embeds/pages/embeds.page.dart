import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/widgets/demo-page-scaffold.dart';

// Demo of the standard embeds.
class EmbedsPage extends StatefulWidget {
  const EmbedsPage({Key? key}) : super(key: key);

  @override
  State<EmbedsPage> createState() => _EmbedsPageState();
}

class _EmbedsPageState extends State<EmbedsPage> {
  late EditorController _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _setupEditorController();
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        children: [
          _editor(),
          _toolbar(),
        ],
      );

  Widget _toolbar() => EditorToolbar.basic(
        controller: _controller,
        showAlignmentButtons: true,
        multiRowsDisplay: false,
      );

  Widget _scaffold({required List<Widget> children}) => DemoPageScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _editor() => Expanded(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
            ),
            child: VisualEditor(
              controller: _controller,
              scrollController: _scrollController,
              focusNode: _focusNode,
              config: EditorConfigM(
                placeholder: 'Enter text',
              ),
            ),
          ),
        ),
      );

  // === UTILS ===

  void _setupEditorController() {
    _controller = EditorController(
      document: DocumentM.fromJson(
        jsonDecode(LOREM_LIPSUM_DOC_JSON),
      ),
    );
  }

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/embeds/assets/embeds.json',
    );
    final document = DocumentM.fromJson(jsonDecode(deltaJson)).delta;

    _controller.update(
      document,
    );
  }
}
