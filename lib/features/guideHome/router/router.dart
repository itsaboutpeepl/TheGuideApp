import 'package:auto_route/auto_route.dart';
import 'package:auto_route/empty_router_widgets.dart';
import 'package:guide_liverpool/features/guideHome/screens/guideHome.dart';
import 'package:guide_liverpool/features/guideHome/widgets/EventsCalendar/events_page.dart';

const guideHomeTab = AutoRoute(
  path: 'guideHome',
  name: 'guideHomeTab',
  page: EmptyRouterPage,
  children: [
    AutoRoute(
      initial: true,
      page: GuideHomeScreen,
      name: 'guideHomeScreen',
    ),
    AutoRoute(
      page: EventsPage,
      name: 'eventsPage',
    ),
  ],
);
