import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:dio/dio.dart';

class DetailPage extends StatefulWidget {
  final heroTag;

  const DetailPage({Key key, this.heroTag}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Future saveImage(String path) async {
    var response = await Dio()
        .get(path, options: Options(responseType: ResponseType.bytes));
    final result =
        await ImageGallerySaver.saveImage(Uint8List.fromList(response.data));
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) => ListView(
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).padding.top),
            Container(
              height: 50,
              padding: EdgeInsets.only(left: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  InkWell(
                    onTap: () {
                      saveImage(widget.heroTag).then((onvalue) {
                        final snackBar = SnackBar(content: Text('저장 완료'));

                        Scaffold.of(context).showSnackBar(snackBar);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.file_download,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 5, right: 5, bottom: 50),
              height: MediaQuery.of(context).size.height -
                  50 -
                  2 * MediaQuery.of(context).padding.top,
              child: Hero(
                tag: widget.heroTag,
                child: CachedNetworkImage(
                  imageUrl: widget.heroTag,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error_outline),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
