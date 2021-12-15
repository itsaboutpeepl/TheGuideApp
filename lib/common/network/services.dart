import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:guide_liverpool/common/router/route_guards.dart';
import 'package:guide_liverpool/common/router/routes.dart';
import 'package:wallet_core/wallet_core.dart' show API, Graph;

@module
abstract class ServicesModule {
  @lazySingleton
  Graph get graph => Graph(
        dotenv.env['GRAPH_BASE_URL']!,
        dotenv.env['NFT_SUB_GRAPH_URL'] ??
            'https://api.thegraph.com/subgraphs/name/mul53/nft-subgraph',
      );

  @lazySingleton
  API get api => API(
        dotenv.env['API_BASE_URL']!,
      );

  @singleton
  RootRouter get rootRouter => RootRouter(authGuard: AuthGuard());
}
