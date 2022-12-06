import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/controller/controllers/editor-controller.dart';
import 'package:visual_editor/documents/models/document.model.dart';
import 'package:visual_editor/editor/models/editor-cfg.model.dart';
import 'package:visual_editor/main.dart';
import 'package:visual_editor/toolbar/widgets/toolbar.dart';

import '../widgets/demo-page-scaffold.dart';
import '../widgets/loading.dart';

// TODO Check other pages to see alternative implementations. This one is taken from selection menu page, which is not what we want.
// While tapping on a link, a menu will open for editing / removing the link.
class LinkMenuPage extends StatefulWidget {
  const LinkMenuPage({Key? key}) : super(key: key);

  @override
  State<LinkMenuPage> createState() => _LinkMenuPageState();
}

class _LinkMenuPageState extends State<LinkMenuPage> {
  EditorController? _controller;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DemoPageScaffold(
          child: _controller != null
              ? _col(
                  children: [
                    _editor(),
                    _toolbar(),
                  ],
                )
              : Loading(),
        ),
      ],
    );
  }

  Widget _col({required List<Widget> children}) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      );

  Widget _editor() => Flexible(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
          ),
          child: VisualEditor(
            controller: _controller!,
            scrollController: _scrollController,
            focusNode: _focusNode,
            config: EditorConfigM(),
          ),
        ),
      );

  Widget _toolbar() => Container(
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          showMarkers: true,
          multiRowsDisplay: false,
        ),
      );

  // === UTILS ===

  // TODO Change document
  Future<void> _loadDocumentAndInitController() async {
    final result = await rootBundle.loadString(
      'assets/docs/selection-menu.json',
    );
    final document = DocumentM.fromJson(jsonDecode(result));

    setState(() {
      _initEditorController(document);
    });
  }

  void _initEditorController(DocumentM document) {
    _controller = EditorController(
      document: document,
    );
  }

}
