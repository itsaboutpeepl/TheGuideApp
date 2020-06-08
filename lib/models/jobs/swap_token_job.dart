import 'package:fusecash/constans/exchangable_tokens.dart';
import 'package:fusecash/models/jobs/base.dart';
import 'package:fusecash/models/pro/pro_wallet_state.dart';
import 'package:fusecash/models/pro/token.dart';
import 'package:fusecash/redux/actions/cash_wallet_actions.dart';
import 'package:fusecash/redux/actions/pro_mode_wallet_actions.dart';
import 'package:fusecash/redux/state/store.dart';
import 'package:fusecash/services.dart';
import 'package:json_annotation/json_annotation.dart';

part 'swap_token_job.g.dart';

@JsonSerializable(explicitToJson: true, createToJson: false)
class SwapTokenJob extends Job {
  SwapTokenJob(
      {id,
      jobType,
      name,
      status,
      data,
      arguments,
      lastFinishedAt,
      timeStart,
      isReported,
      isFunderJob})
      : super(
            id: id,
            jobType: jobType,
            name: name,
            status: status,
            data: data,
            arguments: arguments,
            lastFinishedAt: lastFinishedAt,
            isReported: isReported,
            timeStart: timeStart ?? new DateTime.now().millisecondsSinceEpoch,
            isFunderJob: isFunderJob);

  bool isPending() => this.status == 'PENDING';
  bool isFailed() => this.status == 'FAILED';
  bool isConfirmed() => this.status == 'DONE';

  @override
  fetch() async {
    return api.getJob(this.id);
  }

  @override
  onDone(store, dynamic fetchedData) async {
    final logger = await AppFactory().getLogger('Job');
    logger.info('perform SwapTokenJob - $id');
    if (isReported == true) {
      this.status = 'FAILED';
      logger.info('SwapTokenJob FAILED');
      store.dispatch(segmentTrackCall('Wallet: SwapTokenJob FAILED'));
      return;
    }
    Job job = JobFactory.create(fetchedData);
    int current = DateTime.now().millisecondsSinceEpoch;
    int jobTime = this.timeStart;
    final int millisecondsIntoMin = 2 * 60 * 1000;
    if ((current - jobTime) > millisecondsIntoMin &&
        isReported != null &&
        !isReported) {
      store.dispatch(segmentTrackCall('Wallet: pending job',
          properties: new Map<String, dynamic>.from({'id': id, 'name': name})));
      this.isReported = true;
    }

    if (fetchedData['failReason'] != null && fetchedData['failedAt'] != null) {
      logger.info('SwapTokenJob FAILED');
      this.status = 'FAILED';
      String failReason = fetchedData['failReason'];
      ProWalletState proWalletState = store.state.proWalletState;
      Map<String, SwapTokenJob> newOne = Map<String, SwapTokenJob>.from(proWalletState.swapActions);
      newOne[this.id] = this;
      store.dispatch(new UpdateSwapActions(swapActions: newOne));
      store.dispatch(segmentTrackCall('Wallet: job failed',
          properties: new Map<String, dynamic>.from(
              {'id': id, 'failReason': failReason, 'name': name})));
      return;
    }

    if (job.lastFinishedAt == null || job.lastFinishedAt.isEmpty) {
      logger.info('SwapTokenJob not done');
      return;
    }
    this.status = 'DONE';
    ProWalletState proWalletState = store.state.proWalletState;
    String tokenAddress = arguments['toToken'].address;
    Token newToken =
        proWalletState.erc20Tokens[tokenAddress] ?? exchangableTokens[tokenAddress];
    Map<String, Token> erc20Tokens = proWalletState.erc20Tokens
      ..putIfAbsent(
          tokenAddress.toLowerCase(),
          () => arguments['toToken'].copyWith(
                address: newToken?.address,
                name: newToken?.name,
                amount: BigInt.zero,
                decimals: newToken?.decimals,
                symbol: newToken?.symbol,
              ));
    store.dispatch(segmentTrackCall('Wallet: job succeeded',
      properties: new Map<String, dynamic>.from({'id': id, 'name': name})));
    store.dispatch(new GetTokenListSuccess(erc20Tokens: erc20Tokens));
    Future.delayed(Duration(seconds: 10) , () {
      store.dispatch(new UpdateSwapActions(
          swapActions: proWalletState.swapActions
            ..removeWhere((String id, SwapTokenJob value) => id == this.id)));
    });
  }

  @override
  dynamic argumentsToJson() => {
        'fromToken': arguments['fromToken'].toJson(),
        'toToken': arguments['toToken'].toJson()
      };

  @override
  Map<String, dynamic> argumentsFromJson(arguments) {
    if (arguments == null) {
      return arguments;
    }
    if (arguments.containsKey('fromToken') &&
        arguments.containsKey('toToken')) {
      if (arguments['fromToken'] is Map && arguments['toToken'] is Map) {
        Map<String, dynamic> nArgs = Map<String, dynamic>.from(arguments);
        nArgs['toToken'] = SwapTokenJobFactory.fromJson(arguments['toToken']);
        nArgs['fromToken'] =
            SwapTokenJobFactory.fromJson(arguments['fromToken']);
        return nArgs;
      }
    }
    return arguments;
  }

  factory SwapTokenJob.fromJson(Map<String, dynamic> json) =>
      _$SwapTokenJobFromJson(json);
}

class SwapTokenJobFactory {
  static fromJson(Map<String, dynamic> json) => SwapTokenJob.fromJson(json);
}