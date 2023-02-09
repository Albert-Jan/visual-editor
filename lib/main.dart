import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visual_editor/shared/widgets/triangle-clipper.dart';
import 'package:visual_editor/toolbar/widgets/buttons/link-style-button.dart';

import 'controller/controllers/editor-controller.dart';
import 'cursor/controllers/cursor.controller.dart';
import 'cursor/controllers/floating-cursor.controller.dart';
import 'cursor/services/caret.service.dart';
import 'doc-tree/services/coordinates.service.dart';
import 'doc-tree/services/doc-tree.service.dart';
import 'document/controllers/document.controller.dart';
import 'document/models/attributes/attributes.model.dart';
import 'document/models/attributes/styling-attributes.dart';
import 'document/models/document.model.dart';
import 'document/services/nodes/node.utils.dart';
import 'editor/models/editor-cfg.model.dart';
import 'editor/models/platform-dependent-styles.model.dart';
import 'editor/services/editor.service.dart';
import 'editor/services/gui.service.dart';
import 'editor/services/run-build.service.dart';
import 'editor/widgets/editor-textarea-renderer.dart';
import 'editor/widgets/editor-widget-renderer.dart';
import 'editor/widgets/proxy/baseline-proxy.dart';
import 'editor/widgets/scroll/editor-single-child-scroll-view.dart';
import 'embeds/services/embeds.service.dart';
import 'inputs/services/clipboard.service.dart';
import 'inputs/services/input-connection.service.dart';
import 'inputs/services/keyboard-actions.service.dart';
import 'inputs/services/keyboard.service.dart';
import 'inputs/widgets/text-gestures.dart';
import 'selection/controllers/selection-handles.controller.dart';
import 'selection/services/selection-handles.service.dart';
import 'selection/services/selection.service.dart';
import 'shared/state/editor-state-receiver.dart';
import 'shared/state/editor.state.dart';
import 'styles/services/styles-cfg.service.dart';
import 'styles/services/styles.service.dart';

// There are 2 constructors available, one for controlling all the settings of the editor in precise detail.
// The other one is the basic init that will spare you the pain of having to comb trough all the props.
// The default settings are carefully chosen to satisfy the basic needs of any app that needs rich text editing.
// The editor can be rendered either in scrollable mode or in expanded mode.
// Most apps will prefer the scrollable mode and a sticky EditorToolbar on top or at the bottom of the viewport.
// Use the expanded version when you want to stack multiple editors on top of each other.
// A placeholder text can be defined to be displayed when the editor has no contents.
// All the styles of the editor can be overridden using custom styles.
//
// Custom embeds
// Besides the existing styled text options the editor can also render custom embeds such as video players
// or whatever else the client apps desire to render in the document.
// Any kind of widget can be provided to be displayed in the middle of the document text.
//
// Multiple callbacks are available to be used when interacting with the editor
//
// Controller
// Each instance of the editor will need an EditorController.
// EditorToolbar can be synced to VisualEditor via the EditorController.
//
// Rendering
// The Editor uses Flutter TextField to render the paragraphs in a column of content.
// On top of the regular TextField we are rendering custom selection controls or highlights using the RenderBox API.
//
// Gestures
// The VisualEditor class implements TextSelectionGesturesBuilderDelegate.
// This base class is used to separate the features related to gesture detection and gives the opportunity to override them.
// ignore: must_be_immutable
class VisualEditor extends StatefulWidget with EditorStateReceiver {
  final EditorController controller;
  final FocusNode focusNode;
  final ScrollController? scrollController;
  final EditorConfigM config;

  // Used internally to retrieve the state from the EditorController instance that is linked to this controller.
  // Can't be accessed publicly (by design) to avoid exposing the internals of the library.
  late EditorState _state;

  VisualEditor({
    required this.controller,
    required this.focusNode,
    required this.config,
    this.scrollController,
    Key? key,
  }) : super(key: key) {
    controller.setStateInEditorStateReceiver(this);

    // Singleton caches.
    // Avoids prop drilling or Providers (unlike Quill).
    // Easy to read the call stack, easy to mock for testing.
    _state.refs.controller = controller;
    _state.refs.scrollController = scrollController ?? ScrollController();
    _state.refs.focusNode = focusNode;
    _state.config = config;

    // Beware that if you use the controller.toggleMarkers() and then you setState()
    // on the parent component of the editor this config value will be used again.
    _state.markersVisibility.toggleMarkers(config.markersVisibility ?? true);
    _state.markersTypes.markersTypes = [...config.markerTypes];
    _state.highlights.highlights = [...config.highlights];
  }

  @override
  VisualEditorState createState() => VisualEditorState();

  @override
  void cacheStateStore(EditorState state) {
    _state = state;
  }
}

class VisualEditorState extends State<VisualEditor>
    with
        AutomaticKeepAliveClientMixin<VisualEditor>,
        WidgetsBindingObserver,
        TickerProviderStateMixin<VisualEditor>
    implements TextSelectionDelegate, TextInputClient {
  late final EditorService _editorService;
  late final SelectionHandlesService _selectionHandlesService;
  late final SelectionService _selectionService;
  late final CaretService _caretService;
  late final ClipboardService _clipboardService;
  late final InputConnectionService _inputConnectionService;
  late final KeyboardService _keyboardService;
  late final KeyboardActionsService _keyboardActionsService;
  late final RunBuildService _runBuildService;
  late final DocTreeService _docTreeService;
  late final StylesCfgService _stylesCfgService;
  late final GuiService _guiService;
  late final EmbedsService _embedsService;
  late final StylesService _stylesService;
  late final CoordinatesService _coordinatesService;

  // Controllers
  SelectionHandlesController? selectionHandlesController;
  KeyboardVisibilityController? kbVisibCtrl;
  late FloatingCursorController _floatingCursorController;
  late CursorController _cursorController;
  late DocumentController _documentController;

  final ClipboardStatusNotifier clipboardStatus = ClipboardStatusNotifier();
  final _editorRendererKey = GlobalKey();
  bool _didAutoFocus = false;
  ViewportOffset? _offset;
  bool _stylesInitialised = false;
  late PlatformDependentStylesM _platformStyles;
  StreamSubscription<bool>? kbVisib$L;
  StreamSubscription? runBuild$L;

  @override
  void initState() {
    _editorService = EditorService(state);
    _selectionHandlesService = SelectionHandlesService(state);
    _selectionService = SelectionService(state);
    _caretService = CaretService(state);
    _clipboardService = ClipboardService(state);
    _inputConnectionService = InputConnectionService(state);
    _keyboardService = KeyboardService(state);
    _keyboardActionsService = KeyboardActionsService(state);
    _runBuildService = RunBuildService(state);
    _docTreeService = DocTreeService(state);
    _stylesCfgService = StylesCfgService(state);
    _guiService = GuiService(state);
    _embedsService = EmbedsService(state);
    _stylesService = StylesService(state);
    _coordinatesService = CoordinatesService(state);

    super.initState();
    _cacheWidgetRef();
    _initControllersAndCacheControllersRefs();
    _listenToClipboardAndRunBuild();
    _subscribeToRunBuildAndReqKbUpdGuiElems();
    _listenToScrollAndUpdateOverlayMenu();
    _subscribeToKeyboardVisibilityAndRunBuild();
    _listenToFocusAndUpdateCaretAndOverlayMenu();
    _subscribeToKeystrokes();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    super.build(context);
    _initStylesAndCursorOnlyOnce(context);

    // If doc is empty override with a placeholder
    final document = _docTreeService.getDocOrPlaceholder();

    final editorTree = Stack(
      children: [
        _conditionalPreventKeyPropagationToParentIfWeb(
          child: _i18n(
            child: _textGestures(
              child: _hotkeysActions(
                child: _focusField(
                  child: _constrainedBox(
                    child: _conditionalScrollable(
                      child: _selectionToolbarTarget(
                        child: _editorRenderer(
                          document: document,
                          // This is where the document elements are rendered
                          children: _docTreeService.getDocumentTree(
                            document: document,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _linkMenu(),
      ],
    );

    // (!) Used to update the editor after the users changes selection, in order to
    // position link menu.
    _onBuildComplete();

    // (!) Calling after the widget tree is built ensures that we schedule the
    // onBuildComplete callback as the last addPostFrameCallback() to execute.
    _runBuildService.callBuildCompleteCallback();

    return editorTree;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initStyles();
    _autoFocus();
  }

  // `didUpdateWidget` exists for when you want to trigger side-effects when one of the parameters of your stateful widget change.
  // It is possible for developers to decide to change the params provided to the VisualEditor widget.
  // Therefore they will used setState() and rebuild the editor (that's the first instinct).
  // Some devs might decide to create a new ScrollController or a new FocusNode each time the when using setState().
  // This can happen by simply not being aware that the FocusNode, EditorController and ScrollController need to be cached.
  // In this scenario we need update our state store to use the latest references for the focus node or controllers.
  @override
  void didUpdateWidget(VisualEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resubscribeToScrollController();
    _resubscribeToFocusNode(oldWidget);
    _cacheWidgetRef();
    _cacheEditorRendererRef();
    _reCacheControllersRefs();
    _reCacheStylesAndCursorOnlyOnce();
    _updateStateOnCursorController();
    _subscribeToRunBuildAndReqKbUpdGuiElems();
    _initStyles();
    _subscribeToKeyboardVisibilityAndRunBuild();
  }

  @override
  void dispose() {
    _inputConnectionService.closeConnectionIfNeeded();
    kbVisib$L?.cancel();
    HardwareKeyboard.instance.removeHandler(
      updGuiAndBuildViaHardwareKbEvent,
    );
    selectionHandlesController?.dispose();
    selectionHandlesController = null;
    runBuild$L?.cancel();
    state.refs.focusNode.removeListener(_updateGuiElemsAfterFocus);
    if (state.refs.oldCursorController != null) {
      state.refs.oldCursorController?.dispose();
    }
    clipboardStatus
      ..removeListener(_runBuild)
      ..dispose();
    _unsubscribeFromKeystrokes();
    super.dispose();
  }

  // === CLIPBOARD OVERRIDES ===

  @override
  void copySelection(SelectionChangedCause cause) {
    _clipboardService.copySelection(cause);
  }

  @override
  void cutSelection(SelectionChangedCause cause) {
    _clipboardService.cutSelection(
      cause,
      _selectionHandlesService.hideToolbar,
    );
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async =>
      _clipboardService.pasteText(cause);

  @override
  void selectAll(SelectionChangedCause cause) {
    _selectionService.selectAll(
      cause,
      _editorService.removeSpecialCharsAndUpdateDocTextAndStyle,
    );
  }

  // === INPUT CLIENT OVERRIDES ===

  @override
  bool get wantKeepAlive => state.refs.focusNode.hasFocus;

  // Not implemented
  @override
  void insertTextPlaceholder(Size size) {}

  // Not implemented
  @override
  void removeTextPlaceholder() {}

  // No-op
  @override
  void performAction(TextInputAction action) {}

  // No-op
  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  // Autofill is not needed
  @override
  AutofillScope? get currentAutofillScope {
    return null;
  }

  // Not implemented
  @override
  void showAutocorrectionPromptRect(int start, int end) {
    throw UnimplementedError();
  }

  @override
  TextEditingValue? get currentTextEditingValue {
    return _inputConnectionService.currentTextEditingValue;
  }

  // When a user start typing, new characters are inserted by the remote input.
  // The remote input is the input used by the system to synchronize the content of the input
  // with the state of the software keyboard or other input devices.
  // The remote input stores only plain text.
  // The actual rich text is stored in the editor state store as a DocumentM.
  @override
  void updateEditingValue(TextEditingValue plainText) {
    _inputConnectionService.diffPlainTextAndUpdateDocumentModel(
      plainText,
      _selectionService.cacheSelectionAndRunBuild,
      _editorService.replaceText,
    );
  }

  // TODO better document this path on mobile. Also we need to port copy paste styles on web.
  @override
  void userUpdateTextEditingValue(
    TextEditingValue plainText,
    SelectionChangedCause cause,
  ) {
    _editorService.removeSpecialCharsAndUpdateDocTextAndStyle(
      plainText,
      cause,
    );
  }

  @override
  TextEditingValue get textEditingValue {
    return _editorService.plainText;
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    _floatingCursorController.updateFloatingCursor(point);
  }

  @override
  void connectionClosed() {
    _inputConnectionService.connectionClosed();
  }

  // === TEXT SELECTION OVERRIDES ===

  @override
  bool showToolbar() {
    return _selectionHandlesService.showToolbar();
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    _selectionHandlesService.hideToolbar(hideHandles);
  }

  @override
  void bringIntoView(TextPosition position) {
    _caretService.bringIntoView(position);
  }

  @override
  bool get cutEnabled {
    return _clipboardService.cutEnabled();
  }

  @override
  bool get copyEnabled {
    return _clipboardService.copyEnabled();
  }

  @override
  bool get pasteEnabled {
    return _clipboardService.pasteEnabled();
  }

  @override
  bool get selectAllEnabled {
    return _clipboardService.toolbarOptions().selectAll;
  }

  // Required to avoid circular reference between EditorService and KeyboardService.
  // Ugly solution but it works.
  bool updGuiAndBuildViaHardwareKbEvent(_) =>
      _keyboardService.updGuiAndBuildViaHardwareKeyboardEvent(
        _guiService,
        _runBuild,
      );

  // === PRIVATE ===

  // TODO Replace setState with refresh, I think. Also explain better why we need it.
  void _onBuildComplete() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  Widget _i18n({required Widget child}) => I18n(
        initialLocale: widget.config.locale,
        child: child,
      );

  Widget _textGestures({required Widget child}) => TextGestures(
        behavior: HitTestBehavior.translucent,
        state: state,
        child: child,
      );

  // Intercept RawKeyEvent on Web to prevent it from propagating to parents that might
  // interfere with the editor key behavior, such as SingleChildScrollView.
  // SingleChildScrollView reacts to keys.
  Widget _conditionalPreventKeyPropagationToParentIfWeb({
    required Widget child,
  }) =>
      kIsWeb
          ? RawKeyboardListener(
              focusNode: FocusNode(
                onKey: (node, event) => KeyEventResult.skipRemainingHandlers,
              ),
              child: child,
              onKey: (_) {},
            )
          : child;

  Widget _hotkeysActions({required Widget child}) => Actions(
        actions: _keyboardActionsService.getActions(context),
        child: child,
      );

  Widget _focusField({required Widget child}) => Focus(
        focusNode: state.refs.focusNode,
        child: child,
      );

  // Since SingleChildScrollView does not implement `computeDistanceToActualBaseline` it prevents
  // the editor from providing its baseline metrics.
  // To address this issue we wrap the scroll view with BaselineProxy which mimics the editor's baseline.
  // This implies that the first line has no styles applied to it.
  Widget _conditionalScrollable({required Widget child}) {
    final styles = state.styles.styles;
    final scrollable = state.config.scrollable;

    return scrollable
        ? BaselineProxy(
            textStyle: styles.paragraph!.style,
            padding: EdgeInsets.only(
              top: styles.paragraph!.verticalSpacing.top,
            ),
            child: EditorSingleChildScrollView(
              state: state,
              viewportBuilder: (_, offset) {
                _offset = offset;

                return child;
              },
            ),
          )
        : child;
  }

  Widget _constrainedBox({required Widget child}) {
    final config = state.config;

    return Container(
      constraints: config.expands
          ? const BoxConstraints.expand()
          : BoxConstraints(
              minHeight: config.minHeight ?? 0.0,
              maxHeight: config.maxHeight ?? double.infinity,
            ),
      child: child,
    );
  }

  Widget _linkMenu() {
    // TODO Move from here
    var offset = Offset.infinite;
    final selectedLinkRectangles =
        widget._state.selectedLink.selectedLinkRectangles;
    final isSelection = selectedLinkRectangles.isNotEmpty;

    if (isSelection) {
      final hasRectangles = selectedLinkRectangles[0].rectangles.isNotEmpty;

      if (hasRectangles) {
        final isLinkSelected =
            _stylesService.getSelectionStyle().attributes.containsKey('link');

        if (isLinkSelected) {
          final rectangles = selectedLinkRectangles[0].rectangles[0];
          final lineOffset = selectedLinkRectangles[0].docRelPosition;
          final scrollControllerOffset =
              widget._state.refs.scrollController.offset;

          offset = _getOffsetForLinkMenu(
            rectangles,
            lineOffset,
            scrollControllerOffset,
          );
        }
      }
    }

    return Positioned(
      top: offset.dy,
      left: offset.dx,
      child: Stack(
        children: [
          _content(),
          Positioned(
            top: 6.9,
            left: 0,
            child: _tooltipTriangle(),
          ),
        ],
      ),
    );
  }

  Widget _content() => Container(
        padding: EdgeInsets.only(top: 17.5),
        color: Colors.transparent,
        child: _menuContainer(
          children: [
            _link(),
            _removeLinkBtn(),
            _editLinkBtn(),
            _copyLinkToClipboardBtn(),
          ],
        ),
      );

  Widget _removeLinkBtn() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _removeLink,
          child: Container(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.link_off,
            ),
          ),
        ),
      );

  // TODO After Adrian pushes the big refactor commit on main, see if he moved
  // the logic from the button which is responsible for editing the text, if not,
  // move that into a service and after that create your button which does not look
  // the same as the one from the toolbar.
  Widget _editLinkBtn() => LinkStyleButton(
        controller: widget.controller,
        buttonsSpacing: 10,
      );

  // TODO Add functionality after adding the commit (158 I think) responsible for
  // keyboard shortcuts on master, you need the code from there.
  Widget _copyLinkToClipboardBtn() => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Container(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.copy,
            ),
          ),
        ),
      );

  Widget _link() => InkWell(
        onTap: _launchUrl,
        // Add underline on hover
        onHover: (_) {},
        child: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Text(
            _getLinkAttributeValue() ?? 'No Link',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      );

  Future<void> _launchUrl() async {
    await launchUrl(Uri.parse(_getLinkAttributeValue()!));
  }

  Widget _tooltipTriangle() => Stack(
        children: [
          Container(
            margin: EdgeInsets.only(left: 10),
            child: ClipPath(
              clipper: TriangleClipper(),
              child: Container(
                color: Color(0xffcfcdcd),
                height: 12,
                width: 20,
              ),
            ),
          ),
          Positioned(
            left: (12 - 11.5) / 2,
            right: (12 - 11.5) / 2,
            bottom: -1.5,
            child: Container(
              margin: EdgeInsets.only(left: 10),
              child: ClipPath(
                clipper: TriangleClipper(),
                child: Container(
                  color: Colors.white,
                  height: 11.5,
                  width: 19,
                ),
              ),
            ),
          ),
        ],
      );

  // TODO Add explanatory comment
  // TODO There's a bug when trying to remove a url (www.google.com) because it is
  // being applied again as a link, we need to do something to stop that.
  void _removeLink() {
    var index = widget.controller.selection.start;
    var length = widget.controller.selection.end - index;

    print('YOOOOOOOOOOOOOOOO $index $length');
    if (_getLinkAttributeValue() != null) {
      // TODO This might be the problem which cause the link to not be removed.
      // Se how it was done on the previous commit.
      final leaf = state.refs.documentController.queryNode(index).leaf;
      if (leaf != null) {
        print('ddddddddddddddddddddd $leaf');
        final range = widget.controller.getLinkRange(leaf);
        index = range.start;
        length = range.end - range.start;
      }
    }

    final link =
        state.refs.documentController.getPlainTextAtRange(index, length);

    widget.controller.replaceText(
      index,
      length,
      link,
      null,
    );

    widget.controller.formatSelectedText(
      index,
      link.length,
      RemovedLinkAttributeM(link),
    );
  }

  Widget _menuContainer({required List<Widget> children}) => Container(
        padding: EdgeInsets.symmetric(
          vertical: 7,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 5,
              offset: Offset(5, 5),
              blurStyle: BlurStyle.solid,
              spreadRadius: -5,
            ),
          ],
          borderRadius: BorderRadius.all(
            Radius.circular(4),
          ),
          border: Border.all(
            color: Color(0xffcfcdcd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );

  String? _getLinkAttributeValue() => _stylesService
      .getSelectionStyle()
      .attributes[AttributesM.link.key]
      ?.value;

  // TODO Add comments to explain how the placement is done and where we want it placed.
  // TODO Verify the lineOffset null safety in this code.
  Offset _getOffsetForLinkMenu(
    TextBox rectangle,
    Offset? lineOffset,
    double scrollOffset,
  ) {
    final hLeftPoint = rectangle.left;
    const triangleTooltipMargin = 10;

    final extentOffset = widget.controller.selection.extentOffset;

    final childAtOffset = _coordinatesService.childAtOffset(lineOffset!);
    final nodeUtils = NodeUtils();
    final docOffset = nodeUtils.getDocumentOffset(childAtOffset.container);

    final lineHeight = childAtOffset.preferredLineHeight(
      TextPosition(offset: extentOffset - docOffset),
    );

    // Menu Position
    final offset = Offset(
      hLeftPoint - triangleTooltipMargin,
      lineOffset.dy + lineHeight + rectangle.top,
    );

    return offset;
  }

  // Used by the selection toolbar/controls to position itself in the right location
  Widget _selectionToolbarTarget({required Widget child}) =>
      CompositedTransformTarget(
        link: state.selectionLayers.toolbarLayerLink,
        child: child,
      );

  // Computes the boundaries of the editor (performLayout).
  // We don't use a widget as the parent for the list of document elements because we need custom virtual scroll behaviour.
  // Also renders the floating cursor (cursor displayed when long tapping on mobile and dragging the cursor).
  Widget _editorRenderer({
    required DocumentM document,
    required List<Widget> children,
  }) =>
      Semantics(
        child: EditorWidgetRenderer(
          offset: _offset,
          document: document,
          textDirection: textDirection,
          state: state,
          key: _editorRendererKey,
          children: children,
        ),
      );

  // === UTILS ===

  EditorState get state {
    return widget._state;
  }

  TextDirection get textDirection {
    return Directionality.of(context);
  }

  void callUpdateKeepAlive() => updateKeepAlive();

  // === PRIVATE - INIT ===

  void _initControllersAndCacheControllersRefs() {
    // Document
    _documentController = DocumentController(
      state.document.document,
      state.document.emitChange,
      _editorService.composeCacheSelectionAndRunBuild,
    );
    state.refs.documentController = _documentController;

    // History Controller
    state.refs.historyController = _documentController.historyController;

    // Embed Builders
    _embedsService.initAndCacheEmbedBuilderController();

    // Floating Cursor
    _floatingCursorController = FloatingCursorController(state);
  }

  // TODO Find better solution.
  // The current setup is not able to deal with updated styles.
  // It's stuck on the initial set of styles.
  // In the original Quill repo they used the additional widget RawEditor as a means of getting the BuildContext.
  // After we merged the Editor and RawEditor in one widget we no longer have convenient
  // access to the context from outside of the build method.
  // Therefore we need to highjack the editor build() for getting the current theme.
  // The solution would be to improve the condition from onlyOnce to onlyOnStyleChange.
  void _initStylesAndCursorOnlyOnce(BuildContext context) {
    if (!_stylesInitialised) {
      _initStyles();
      _platformStyles = _stylesCfgService.initAndCachePlatformStyles(context);
      _cursorController = _stylesCfgService.initAndCacheCursorController();
      _stylesInitialised = true;
    }
  }

  void _initStyles() {
    var styles = _stylesCfgService.getDefaultStyles(context);

    if (state.config.customStyles != null) {
      styles = styles.merge(state.config.customStyles!);
    }

    state.styles.setStyles(styles);
  }

  // === CACHE REFS ===

  // Required if host code uses setState() for whatever reason and rebuilds the EditorController.
  // If the EditorController is rebuilt that means a new state store.
  // Since the CursorController is initialised only once, we need to make sure it gets
  // the latest state store object from the new EditorController.
  void _updateStateOnCursorController() {
    state.refs.cursorController.cacheStateStore(state);
  }

  // When a new widget tree is generated we need to find the new renderer class.
  // A new widget tree is usually created because of using setState in the client code.
  void _cacheEditorRendererRef() {
    final renderer = _editorRendererKey.currentContext?.findRenderObject()
        as EditorTextAreaRenderer?;

    if (renderer != null) {
      state.refs.renderer = renderer;
    }
  }

  // When a new controller/state store is created we need to cache these references again.
  void _reCacheStylesAndCursorOnlyOnce() {
    state.platformStyles.styles = _platformStyles;
    state.refs.cursorController = _cursorController;
  }

  void _cacheWidgetRef() {
    state.refs.widget = this;
  }

  void _reCacheControllersRefs() {
    state.refs.documentController = _documentController;
    state.refs.historyController = _documentController.historyController;
  }

  // === BUILD & SYNC GUI ===

  // Once a new widget tree build is triggered via setState the entire list of document lines and doc-tree
  // will check for changes in their own text and render these changes.
  // From here on we no longer apply changes to the document, from here on we only render the changes.
  void _runBuild() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _listenToClipboardAndRunBuild() {
    clipboardStatus.addListener(_runBuild);
  }

  void _updateGuiElemsAfterFocus() {
    _guiService.updateGuiElemsAfterFocus();
  }

  void _updateSelectionHandlesLocation() {
    selectionHandlesController?.updateSelectionHandlesLocation();
    _callOnScrollCallback();
  }

  void _autoFocus() {
    final autoFocus = state.config.autoFocus;

    if (!_didAutoFocus && autoFocus) {
      FocusScope.of(context).autofocus(state.refs.focusNode);
      _didAutoFocus = true;
    }
  }

  // === SUBSCRIPTIONS ===

  // All changes in the editor text or toolbar will trigger the update of the entire editor widget tree.
  // From here on no more data model / document changes are executed, only widget tree updates following the updated document.
  // On each build, before the document tree (text widgets) is updated several pre build steps are executed.
  void _subscribeToRunBuildAndReqKbUpdGuiElems() {
    // In case this is called a second time because a new editor controller was provided.
    runBuild$L?.cancel();

    // Run Build
    runBuild$L = _runBuildService.runBuild$.listen((_) {
      _guiService.reqKbUpdateGuiElemsAndBuild(_runBuild);
    });
  }

  void _listenToFocusAndUpdateCaretAndOverlayMenu() {
    state.refs.focusNode.addListener(_updateGuiElemsAfterFocus);
  }

  void _resubscribeToFocusNode(VisualEditor oldWidget) {
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_updateGuiElemsAfterFocus);
      state.refs.focusNode = widget.focusNode;
      widget.focusNode.addListener(_updateGuiElemsAfterFocus);
      updateKeepAlive();
    }
  }

  void _subscribeToKeyboardVisibilityAndRunBuild() {
    _keyboardService.subscribeToKeyboardVisibilityAndRunBuild(
      _guiService,
      _runBuild,
    );
  }

  // On init
  void _listenToScrollAndUpdateOverlayMenu() {
    final _scrollController = state.refs.scrollController;
    _scrollController.addListener(_updateSelectionHandlesLocation);
  }

  // On widget update
  void _resubscribeToScrollController() {
    final _scrollController = state.refs.scrollController;

    if (widget.scrollController != _scrollController) {
      _scrollController.removeListener(_updateSelectionHandlesLocation);
      state.refs.scrollController =
          widget.scrollController ?? ScrollController();
      _scrollController.addListener(_updateSelectionHandlesLocation);
    }
  }

  // === CACHE KEYSTROKES ===

  // TODO call from didUpdateWidget.
  // If the controller gets swapped then caching keys will no longer work.
  // Pay attention to properly implement disconnect and reconnect (look at the other examples).
  // Right now this is not so urgent since we don't use cached keys at all for now.
  // But we will need them soon when implementing typing shortcuts.
  void _subscribeToKeystrokes() {
    HardwareKeyboard.instance.addHandler(_cachePressedKeys);
  }

  void _unsubscribeFromKeystrokes() {
    HardwareKeyboard.instance.removeHandler(_cachePressedKeys);
  }

  // Cache the pressed keys in the state store for later reads.
  bool _cachePressedKeys(_) {
    _keyboardService.setPressedKeys(
      HardwareKeyboard.instance.logicalKeysPressed,
    );

    return false;
  }

  // === CALLBACKS ===

  void _callOnScrollCallback() {
    final onScroll = state.config.onScroll;

    if (onScroll != null) {
      onScroll();
    }
  }

  @override
  void didChangeInputControl(
      TextInputControl? oldControl, TextInputControl? newControl) {
    // TODO: implement didChangeInputControl
  }

  @override
  void performSelector(String selectorName) {
    // TODO: implement performSelector
  }
}
