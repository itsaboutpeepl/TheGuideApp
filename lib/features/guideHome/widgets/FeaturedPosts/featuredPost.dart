import 'package:flutter/material.dart';
import 'package:guide_liverpool/features/guideHome/helpers/UrlLaunch.dart';
import 'package:guide_liverpool/features/guideHome/helpers/pageViewDetailArticle.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:guide_liverpool/models/articles/blogArticle.dart';
import 'package:intl/intl.dart';

class FeaturedPost extends StatefulWidget {
  const FeaturedPost(
      {Key? key, required this.index, required this.listOfArticles})
      : super(key: key);

  final int index;
  final List<BlogArticle> listOfArticles;

  @override
  _FeaturedPostState createState() => _FeaturedPostState();
}

class _FeaturedPostState extends State<FeaturedPost> {
  @override
  Widget build(BuildContext context) {
    return featuredPost(context, widget.listOfArticles[widget.index]);
  }

  Widget featuredPost(BuildContext context, BlogArticle article) {
    return Padding(
      padding: EdgeInsets.only(right: 15, left: 15, top: 15, bottom: 55),
      child: InkWell(
        onTap: () => {
          showBarModalBottomSheet(
            useRootNavigator: true,
            backgroundColor: Colors.cyan,
            context: context,
            builder: (context) => PagedViewDetailArticle(
              listOfArticles: widget.listOfArticles,
              currentIndex: widget.index,
            ),
          )
        },
        child: Card(
          color: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    article.imageURL,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  article.title,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Row(
                  children: [
                    Text(
                      parseHtmlString(article.category[0]),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.grey[500],
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      DateFormat("EEE, MMM d, ''yy")
                          .format(article.publishedAt),
                      style: TextStyle(color: Colors.grey[500]),
                    )
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  parseHtmlString(article.content),
                  style: TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 4,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
