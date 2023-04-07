import 'package:a_eye/utils/app_theme.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MapScreen extends StatefulWidget {
  late Map labels;
  MapScreen(this.labels);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  TextEditingController textController = new TextEditingController();

  @override
  initState() {
    super.initState();
    textController.addListener(() {
      print(textController.text);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height) / 2;
    final double itemWidth = size.width / 3;
    Map labelsMap = widget.labels;
    ScrollController controller = ScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Text("Object Types"),
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, labelsMap),
        ),
        actions: [
          AnimSearchBar(
              style: AppTheme.title,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppTheme.appIndigo,
              ),
              suffixIcon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.appIndigo,
              ),
              closeSearchOnSuffixTap: true,
              rtl: true,
              width: MediaQuery.of(context).size.width,
              textController: textController,
              onSuffixTap: () {
                textController.clear();
              })
        ],
      ),
      body: DraggableScrollbar.semicircle(
        controller: controller,
        labelConstraints: BoxConstraints.tightFor(width: 80.0, height: 30.0),
        backgroundColor: AppTheme.notWhite,
        child: GridView(
          controller: controller,
          physics: BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5.0,
            mainAxisSpacing: 5.0,
            childAspectRatio: itemHeight / itemWidth,
          ),
          children: labelsMap.keys
              .where((key) => key.toLowerCase().contains(textController.text))
              .map((key) {
            return Card(
              elevation: 4,
              child: Center(
                child: new CheckboxListTile(
                  activeColor: Colors.blueGrey,
                  title: new Text(key),
                  value: labelsMap[key],
                  onChanged: (bool? value) {
                    setState(() {
                      labelsMap[key] = value;
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
