import 'package:flutter/material.dart';

class CategoryArticle extends StatelessWidget {
  const CategoryArticle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.65,
            child: Column(
              children: [
                Text(
                  "City Council release statement following news that Liverpool is to be given £22m of Government funding",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                SizedBox(height: 5),
                Text(
                  "Going out as a group for a meal or drink for a special occasion is great, but sometimes you want somewhere that’s exclusively for you, your family and friends.",
                ),
              ],
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Expanded(
            child: Container(
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                child: Image.network(
                  "https://www.cityam.com/wp-content/uploads/2021/07/CAMD-G89-1024-GBrown-copy-1.jpg",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
