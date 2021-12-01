import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:guide_liverpool/models/app_state.dart';
import 'package:guide_liverpool/redux/actions/cash_wallet_actions.dart';
import 'package:guide_liverpool/redux/viewsmodels/home.dart';
import 'package:guide_liverpool/features/home/widgets/tabs.dart';
import 'package:guide_liverpool/features/home/widgets/header.dart';
import 'package:guide_liverpool/utils/addresses.dart';
import 'package:guide_liverpool/features/shared/widgets/my_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, HomeViewModel>(
      distinct: true,
      converter: HomeViewModel.fromStore,
      onInitialBuild: (viewModel) {
        viewModel.onStart();
      },
      onInit: (store) {
        final communities = store.state.cashWalletState.communities;
        if (!communities.containsKey(defaultCommunityAddress.toLowerCase())) {
          store.dispatch(switchCommunityCall(defaultCommunityAddress));
        }
      },
      builder: (_, viewModel) {
        return Scaffold(
          appBar: MyAppBar(
            height: 156,
            backgroundColor: Colors.black,
            child: Header(),
          ),
          body: Tabs(),
        );
      },
    );
  }
}
