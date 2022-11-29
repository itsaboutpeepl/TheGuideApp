import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:guide_liverpool/models/app_state.dart';
import 'package:guide_liverpool/redux/actions/network_tab_actions.dart';
import 'package:guide_liverpool/utils/extensions.dart';
import 'package:redux/redux.dart';

class PeeplPaySheetViewModel extends Equatable {
  const PeeplPaySheetViewModel({
    required this.startPaymentProcess,
    required this.selectedGBPxAmount,
    required this.selectedPPLAmount,
    required this.updateSelectedValues,
    required this.transferringTokens,
    required this.errorCompletingPayment,
    required this.confirmedPayment,
    required this.restaurantName,
    required this.cartTotal,
  });

  factory PeeplPaySheetViewModel.fromStore(Store<AppState> store) {
    return PeeplPaySheetViewModel(
      cartTotal: store.state.networkTabState.cartTotal.formattedPrice,
      selectedGBPxAmount: store.state.networkTabState.selectedGBPxAmount,
      selectedPPLAmount: store.state.networkTabState.selectedPPLAmount,
      transferringTokens: store.state.networkTabState.transferringTokens,
      errorCompletingPayment:
          store.state.networkTabState.errorCompletingPayment,
      confirmedPayment: store.state.networkTabState.confirmedPayment,
      restaurantName: store.state.networkTabState.restaurantName,
      updateSelectedValues: (gbpxAmount, pplAmount) {
        store.dispatch(
          UpdateSelectedAmounts(
            gbpxAmount: gbpxAmount,
            pplAmount: pplAmount,
          ),
        );
      },
      startPaymentProcess: ({required BuildContext context}) {
        store.dispatch(startPeeplPayProcess(context: context));
      },
    );
  }
  final double selectedGBPxAmount;
  final double selectedPPLAmount;
  final String cartTotal;
  final bool transferringTokens;
  final bool errorCompletingPayment;
  final bool confirmedPayment;
  final String restaurantName;
  final void Function(double gbpxAmount, double pplAmount) updateSelectedValues;
  final void Function({required BuildContext context}) startPaymentProcess;

  @override
  List<Object> get props => [
        selectedGBPxAmount,
        selectedPPLAmount,
        transferringTokens,
        errorCompletingPayment,
        confirmedPayment,
      ];
}
