import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) {
    return _box(
      child: _row(
        children: [
          _input(),
          _divider(),
          _nextBtn(),
          _prevBtn(),
          _closeBtn(),
        ],
      ),
    );
  }

  Widget _box({required Widget child}) => Container(
        color: Colors.grey.shade800,
        padding: EdgeInsets.all(10),
        child: child,
      );

  Widget _row({required List<Widget> children}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );

  Widget _input() => Container(
        width: 150,
        child: TextField(
          cursorColor: Colors.white,
          controller: TextEditingController(),
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 8),
            isDense: true,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.transparent,
              ),
            ),
          ),
          textInputAction: TextInputAction.go,
          onSubmitted: (text) {},
          onTap: () {},
        ),
      );

  Widget _divider() => Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        width: 1,
        height: 30,
        color: Colors.grey,
      );

  Widget _nextBtn() => Icon(
        Icons.arrow_downward_rounded,
        color: Colors.grey,
        size: 18,
      );

  Widget _prevBtn() => Container(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: Colors.grey,
          size: 18,
        ),
      );

  Widget _closeBtn() => Icon(
        Icons.close,
        color: Colors.grey,
        size: 18,
      );
}
