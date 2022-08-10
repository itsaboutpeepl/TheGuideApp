import 'package:equatable/equatable.dart';
import 'package:guide_liverpool/models/app_state.dart';
import 'package:guide_liverpool/models/community/community.dart';
import 'package:guide_liverpool/models/plugins/plugins.dart';
import 'package:guide_liverpool/redux/actions/home_page_actions.dart';
import 'package:guide_liverpool/redux/actions/vesting_actions.dart';
import 'package:redux/redux.dart';

class AccountViewModel extends Equatable {
  final String walletAddress;
  final String avatarUrl;
  final String displayName;
  final Plugins plugins;
  final bool isBackup;
  final Function() onStart;

  AccountViewModel(
      {required this.plugins,
      required this.walletAddress,
      required this.avatarUrl,
      required this.displayName,
      required this.isBackup,
      required this.onStart});

  static AccountViewModel fromStore(Store<AppState> store) {
    String? communityAddress = store.state.cashWalletState.communityAddress;
    Community? community =
        store.state.cashWalletState.communities[communityAddress];
    return AccountViewModel(
      isBackup: store.state.userState.backup,
      plugins: community?.plugins ?? Plugins(),
      displayName: store.state.userState.displayName,
      avatarUrl: store.state.userState.avatarUrl,
      walletAddress: store.state.userState.walletAddress,
      onStart: () {
        store.dispatch(getUserVestingCount());

        store.dispatch(UpdateVestingIsLoading(isLoading: true));
      },
    );
  }

  @override
  List<Object> get props => [
        walletAddress,
        avatarUrl,
        displayName,
        isBackup,
        plugins,
        onStart,
      ];
}
