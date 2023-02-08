import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visual_editor/visual-editor.dart';

import '../../shared/const/dimensions.const.dart';
import '../../shared/widgets/demo-page-scaffold.dart';
import '../../shared/widgets/loading.dart';
import '../widgets/search-bar.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPagePageState createState() => _SearchPagePageState();
}

class _SearchPagePageState extends State<SearchPage> {
  EditorController? _controller;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _loadDocumentAndInitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _scaffold(
        child: _stack(
          children: _controller != null
              ? [
                  _col(
                    children: [
                      _whitePage(
                        child: _editor(),
                      ),
                      _toolbar(),
                    ],
                  ),
                  _searchBar(),
                ]
              : [
                  Loading(),
                ],
        ),
      );

  Widget _stack({required List<Widget> children}) => Container(
        child: Stack(
          children: children,
        ),
      );

  Widget _scaffold({required Widget child}) => DemoPageScaffold(
        pageWidth: double.infinity,
        child: child,
      );

  Widget _col({required List<Widget> children}) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      );

  Widget _searchBar() => Positioned(
        top: 1,
        right: 30,
        child: SearchBar(),
      );

  Widget _whitePage({required Widget child}) => Flexible(
        child: Container(
          width: 800,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(60, 10, 60, 30),
          child: child,
        ),
      );

  Widget _toolbar() => Container(
        width: 800,
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        child: EditorToolbar.basic(
          controller: _controller!,
          showMarkers: true,
          showSearch: true,
          multiRowsDisplay: false,
        ),
      );

  Widget _editor() => VisualEditor(
        controller: _controller!,
        scrollController: _scrollController,
        focusNode: _focusNode,
        config: EditorConfigM(),
      );

  Future<void> _loadDocumentAndInitController() async {
    final deltaJson = await rootBundle.loadString(
      'lib/controller/assets/search-page.json',
    );
    final document = DocumentM.fromJson(jsonDecode(deltaJson));

    setState(() {
      _controller = EditorController(
        document: document,
      );
    });
  }
}
