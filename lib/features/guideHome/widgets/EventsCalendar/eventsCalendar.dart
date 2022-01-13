import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:guide_liverpool/features/guideHome/widgets/EventsCalendar/singleEventItem.dart';
import 'package:guide_liverpool/models/app_state.dart';
import 'package:guide_liverpool/redux/viewsmodels/eventsCalendar.dart';

class EventCalendar extends StatefulWidget {
  const EventCalendar({Key? key}) : super(key: key);

  @override
  _EventCalendarState createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    _pageController = new PageController();

    _pageController.addListener(() {
      setState(() {
        _currentIndex = _pageController.page!.toInt();
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, EventsCalendarViewModel>(
      distinct: true,
      converter: EventsCalendarViewModel.fromStore,
      builder: (_, viewmodel) {
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          sliver: SliverToBoxAdapter(
            child: Card(
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 65,
                    left: 8,
                    child: Column(
                      children: _buildPageIndicator(),
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.24,
                    child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        physics: PageScrollPhysics(),
                        itemBuilder: (context, index) => SingleEventItem(
                              eventItem: viewmodel.eventsList[index],
                            ),
                        itemCount: viewmodel.eventsList.length),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _indicator(bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      height: 8,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        height: isActive ? 8 : 6.0,
        width: isActive ? 10 : 6.0,
        decoration: BoxDecoration(
          boxShadow: [
            isActive
                ? BoxShadow(
                    color: Color(0XFF2FB7B2).withOpacity(0.72),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                    offset: Offset(
                      0.0,
                      0.0,
                    ),
                  )
                : BoxShadow(
                    color: Colors.transparent,
                  )
          ],
          shape: BoxShape.circle,
          color: isActive ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < 5; i++) {
      list.add(i == _currentIndex ? _indicator(true) : _indicator(false));
    }
    return list;
  }
}
