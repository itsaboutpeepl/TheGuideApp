import 'dart:convert';
import 'dart:io';

import 'package:country_code_picker/country_code.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:peepl/models/app_state.dart';
import 'package:peepl/models/community/community.dart';
import 'package:peepl/models/jobs/base.dart';
import 'package:peepl/models/peepl_pay.dart';
import 'package:peepl/models/pro/pro_wallet_state.dart';
import 'package:peepl/models/tokens/token.dart';
import 'package:peepl/models/transactions/transfer.dart';
import 'package:peepl/redux/actions/cash_wallet_actions.dart';
import 'package:peepl/redux/actions/error_actions.dart';
import 'package:peepl/redux/actions/pro_mode_wallet_actions.dart';
import 'package:peepl/utils/addresses.dart';
import 'package:peepl/utils/biometric_local_auth.dart';
import 'package:peepl/utils/constans.dart';
import 'package:peepl/utils/contacts.dart';
import 'package:peepl/utils/format.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phone_number/phone_number.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:wallet_core/wallet_core.dart';
import 'package:peepl/services.dart';
import 'package:peepl/redux/state/store.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:peepl/utils/phone.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:http/http.dart' as http;

class CreateAccountWalletRequest {
  CreateAccountWalletRequest();
}

class CreateAccountWalletSuccess {
  CreateAccountWalletSuccess();
}

class UpdateCurrency {
  final String currency;
  UpdateCurrency({this.currency});
}

class UpdateTotalBalance {
  final num totalBalance;
  UpdateTotalBalance({this.totalBalance});
}

class HomeBackupDialogShowed {
  HomeBackupDialogShowed();
}

class ReceiveBackupDialogShowed {
  ReceiveBackupDialogShowed();
}

class SetSecurityType {
  BiometricAuth biometricAuth;
  SetSecurityType({this.biometricAuth});
}

class VerifyRequest {
  final String verificationId;
  final String verificationCode;

  VerifyRequest(
      {@required this.verificationId, @required this.verificationCode});

  @override
  String toString() {
    return 'VerifyRequest{verificationId: $verificationId, verificationCode: $verificationCode}';
  }
}

class CreateLocalAccountSuccess {
  final List<String> mnemonic;
  final String privateKey;
  final String accountAddress;
  CreateLocalAccountSuccess(
      this.mnemonic, this.privateKey, this.accountAddress);
}

class ReLogin {
  ReLogin();
}

class LoginRequest {
  final CountryCode countryCode;
  final PhoneNumber phoneNumber;
  final PhoneCodeSent codeSent;
  final PhoneVerificationCompleted verificationCompleted;
  final PhoneVerificationFailed verificationFailed;
  final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout;

  LoginRequest(
      {@required this.countryCode,
      @required this.phoneNumber,
      @required this.codeSent,
      @required this.verificationCompleted,
      @required this.verificationFailed,
      @required this.codeAutoRetrievalTimeout});
}

class LoginRequestSuccess {
  final CountryCode countryCode;
  final String phoneNumber;
  final String displayName;
  final String email;
  final String normalizedPhoneNumber;
  LoginRequestSuccess(
      {this.countryCode,
      this.phoneNumber,
      this.displayName,
      this.email,
      this.normalizedPhoneNumber});
}

class SetIsoCode {
  final CountryCode countryCode;
  final String normalizedPhoneNumber;
  SetIsoCode({this.countryCode, this.normalizedPhoneNumber});
}

class LogoutRequestSuccess {
  LogoutRequestSuccess();
}

class LoginVerifySuccess {
  final String jwtToken;
  LoginVerifySuccess(this.jwtToken);
}

class SyncContactsProgress {
  List<String> contacts;
  List<Map<String, dynamic>> newContacts;
  SyncContactsProgress(this.contacts, this.newContacts);
}

class SyncContactsRejected {
  SyncContactsRejected();
}

class SaveContacts {
  List<Contact> contacts;
  SaveContacts(this.contacts);
}

class SetPincodeSuccess {
  String pincode;
  SetPincodeSuccess(this.pincode);
}

class SetDisplayName {
  String displayName;
  SetDisplayName(this.displayName);
}

class SetUserAvatar {
  String avatarUrl;
  SetUserAvatar(this.avatarUrl);
}

class BackupRequest {
  BackupRequest();
}

class BackupSuccess {
  BackupSuccess();
}

class SetCredentials {
  PhoneAuthCredential credentials;
  SetCredentials(this.credentials);
}

class SetVerificationId {
  String verificationId;
  SetVerificationId(this.verificationId);
}

class UpdateDisplayBalance {
  final int displayBalance;
  UpdateDisplayBalance(this.displayBalance);
}

class JustInstalled {
  final DateTime installedAt;
  JustInstalled(this.installedAt);
}

class SetIsLoginRequest {
  final bool isLoading;
  final dynamic message;
  SetIsLoginRequest({this.isLoading, this.message});
}

class SetIsVerifyRequest {
  final bool isLoading;
  final dynamic message;
  SetIsVerifyRequest({this.isLoading, this.message});
}

class DeviceIdSuccess {
  final String identifier;
  DeviceIdSuccess(this.identifier);
}

class GetUserCartItems {
  final List<PeeplPay> _peeplpay;
  List<PeeplPay> get peeplpay => this._peeplpay;

  GetUserCartItems(this._peeplpay);
}

ThunkAction setCountryCode(CountryCode countryCode) {
  return (Store store) async {
    String phone =
        '${countryCode.dialCode}${store.state.userState.phoneNumber}';
    PhoneNumber phoneNumber =
        await phoneNumberUtil.parse(phone, regionCode: countryCode.code);
    store.dispatch(SetIsoCode(
        countryCode: countryCode, normalizedPhoneNumber: phoneNumber.e164));
  };
}

ThunkAction backupWalletCall() {
  return (Store store) async {
    if (store.state.userState.backup) return;
    try {
      final logger = await AppFactory().getLogger('action');
      String communityAddress = store.state.cashWalletState.communityAddress;
      store.dispatch(BackupRequest());
      dynamic response =
          await api.backupWallet(communityAddress: communityAddress);
      dynamic jobId = response['job']['_id'];
      Community community =
          store.state.cashWalletState.communities[communityAddress];
      Token token =
          store.state.cashWalletState.tokens[community?.homeTokenAddress];
      if (community.plugins.backupBonus != null &&
          community.plugins.backupBonus.isActive &&
          ![null, ''].contains(jobId)) {
        BigInt value =
            toBigInt(community.plugins.backupBonus.amount, token.decimals);
        String walletAddress = store.state.userState.walletAddress;
        logger.info('Job $jobId - sending backup bonus');
        final String tokenAddress = token.address;
        Transfer backupBonus = new Transfer(
            tokenAddress: token.address,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            from: DotEnv().env['FUNDER_ADDRESS'],
            to: walletAddress,
            text: 'You got a backup bonus!',
            type: 'RECEIVE',
            value: value,
            status: 'PENDING',
            jobId: jobId);
        store.dispatch(AddTransaction(
            transaction: backupBonus, tokenAddress: tokenAddress));

        response['job']['arguments'] = {
          'backupBonus': backupBonus,
        };
        response['job']['jobType'] = 'backup';
        Job job = JobFactory.create(response['job']);
        store.dispatch(AddJob(job: job, tokenAddress: tokenAddress));
        store.dispatch(BackupSuccess());
      }
    } catch (e) {
      store.dispatch(BackupSuccess());
    }
  };
}

ThunkAction backupSuccessCall(Transfer transfer) {
  return (Store store) async {
    Transfer confirmedTx = transfer.copyWith(
        status: 'CONFIRMED', timestamp: DateTime.now().millisecondsSinceEpoch);
    store.dispatch(ReplaceTransaction(
        transactionToReplace: confirmedTx,
        transaction: transfer,
        tokenAddress: transfer.tokenAddress));
    store.dispatch(BackupSuccess());
    store.dispatch(segmentIdentifyCall(
        Map<String, dynamic>.from({'Wallet backed up success': true})));
    store.dispatch(segmentTrackCall('Wallet: backup success'));
  };
}

ThunkAction setDeviceId(bool reLogin) {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    String identifier = await FlutterUdid.udid;
    logger.info("device identifier: $identifier");
    store.dispatch(DeviceIdSuccess(identifier));
    if (reLogin) {
      final User currentUser = firebaseAuth.currentUser;
      final String accountAddress = store.state.userState.accountAddress;
      String token = await currentUser.getIdToken();
      String jwtToken =
          await api.login(token, accountAddress, identifier, appName: "Roost");
      store.dispatch(LoginVerifySuccess(jwtToken));
    }
  };
}

ThunkAction restoreWalletCall(
    List<String> _mnemonic, VoidCallback successCallback) {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      logger.info('restore wallet');
      String mnemonic = _mnemonic.join(' ');
      logger.info('mnemonic: $mnemonic');
      logger.info('compute pk');
      String privateKey = await compute(Web3.privateKeyFromMnemonic, mnemonic);
      logger.info('privateKey: $privateKey');
      Credentials credentials = EthPrivateKey.fromHex(privateKey);
      EthereumAddress accountAddress = await credentials.extractAddress();
      store.dispatch(CreateLocalAccountSuccess(
          mnemonic.split(' '), privateKey, accountAddress.toString()));
      store.dispatch(initWeb3Call(privateKey: privateKey));
      store.dispatch(segmentTrackCall("Wallet: restored mnemonic"));
      successCallback();
    } catch (e) {
      logger.severe('ERROR - restoreWalletCall $e');
      store.dispatch(ErrorAction('Could not restore wallet'));
    }
  };
}

ThunkAction createLocalAccountCall(
    VoidCallback successCallback, VoidCallback errorCallback) {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      logger.info('create wallet');
      String mnemonic = Web3.generateMnemonic();
      logger.info('mnemonic: $mnemonic');
      logger.info('compute pk');
      String privateKey = await compute(Web3.privateKeyFromMnemonic, mnemonic);
      logger.info('privateKey: $privateKey');
      Credentials credentials = EthPrivateKey.fromHex(privateKey);
      EthereumAddress accountAddress = await credentials.extractAddress();
      store.dispatch(CreateLocalAccountSuccess(
          mnemonic.split(' '), privateKey, accountAddress.toString()));
      store.dispatch(initWeb3Call(privateKey: privateKey));
      store.dispatch(segmentTrackCall("Wallet: Create wallet"));
      successCallback();
    } catch (e, s) {
      logger.severe('ERROR - createLocalAccountCall $e');
      store.dispatch(ErrorAction('Could not create wallet'));
      await AppFactory().reportError(e, stackTrace: s);
      errorCallback();
    }
  };
}

ThunkAction logoutCall() {
  return (Store store) async {
    store.dispatch(LogoutRequestSuccess());
  };
}

ThunkAction reLoginCall() {
  return (Store store) async {
    store.dispatch(ReLogin());
    store.dispatch(segmentTrackCall("Wallet: Login clicked"));
  };
}

ThunkAction syncContactsCall(List<Contact> contacts) {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      store.dispatch(SaveContacts(contacts));
      List<String> syncedContacts = store.state.userState.syncedContacts;
      List<String> newPhones = List<String>();
      String countryCode = store.state.userState.countryCode;
      String isoCode = store.state.userState.isoCode;
      for (Contact contact in contacts) {
        Future<List<String>> phones =
            Future.wait(contact.phones.map((Item phone) async {
          String value = clearNotNumbersAndPlusSymbol(phone.value);
          try {
            PhoneNumber phoneNumber = await phoneNumberUtil.parse(value);
            return phoneNumber.e164;
          } catch (e) {
            String formatted = formatPhoneNumber(value, countryCode);
            bool isValid = await phoneNumberUtil.validate(formatted, isoCode);
            if (isValid) {
              String phoneNum =
                  await phoneNumberUtil.format(formatted, isoCode);
              PhoneNumber phoneNumber = await phoneNumberUtil.parse(phoneNum);
              return phoneNumber.e164;
            }
            return '';
          }
        }));
        List<String> result = await phones;
        result = result.toSet().toList()
          ..removeWhere((element) => element == '');
        for (String phone in result) {
          if (!syncedContacts.contains(phone)) {
            newPhones.add(phone);
          }
        }
      }
      if (newPhones.length == 0) {
        dynamic response = await api.syncContacts(newPhones);
        store.dispatch(SyncContactsProgress(newPhones,
            List<Map<String, dynamic>>.from(response['newContacts'])));
        await api.ackSync(response['nonce']);
      } else {
        int limit = 100;
        List<String> partial = newPhones.take(limit).toList();
        while (partial.length > 0) {
          dynamic response = await api.syncContacts(partial);
          store.dispatch(SyncContactsProgress(partial,
              List<Map<String, dynamic>>.from(response['newContacts'])));

          await api.ackSync(response['nonce']);
          newPhones = newPhones.sublist(partial.length);
          partial = newPhones.take(limit).toList();
        }
      }
    } catch (e) {
      logger.severe('ERROR - syncContactsCall $e');
    }
  };
}

ThunkAction identifyFirstTimeCall() {
  return (Store store) async {
    String fullPhoneNumber = store.state.userState.normalizedPhoneNumber ?? '';
    store.dispatch(enablePushNotifications());
    store.dispatch(segmentAliasCall(fullPhoneNumber));
    store.dispatch(segmentIdentifyCall(Map<String, dynamic>.from({
      "Wallet Generated": true,
      "Phone Number": fullPhoneNumber,
      "Wallet Address": store.state.userState.walletAddress,
      "Account Address": store.state.userState.accountAddress,
      "Display Name": store.state.userState.displayName,
      "Identifier": store.state.userState.identifier
    })));
  };
}

ThunkAction identifyCall() {
  return (Store store) async {
    store.dispatch(segmentIdentifyCall(Map<String, dynamic>.from({
      "Phone Number": store.state.userState.normalizedPhoneNumber ?? '',
      "Wallet Address": store.state.userState.walletAddress,
      "Account Address": store.state.userState.accountAddress,
      "Display Name": store.state.userState.displayName,
      "Identifier": store.state.userState.identifier,
      "Joined Communities":
          store.state.cashWalletState.communities.keys.toList(),
    })));
  };
}

ThunkAction setDisplayNameCall(String displayName) {
  return (Store store) async {
    try {
      store.dispatch(SetDisplayName(displayName));
      store.dispatch(segmentTrackCall("Wallet: display name added"));
    } catch (e) {}
  };
}

ThunkAction create3boxAccountCall(walletAddress) {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    String displayName = store.state.userState.displayName;
    try {
      Map user = {
        "accountAddress": walletAddress,
        "email": 'wallet-user@fuse.io',
        "provider": 'HDWallet',
        "subscribe": false,
        "source": 'wallet-v2',
        "displayName": displayName
      };
      await api.saveUserToDb(user);
      logger.info('save user $walletAddress');
    } catch (e) {
      logger.severe('user $walletAddress already saved');
    }
  };
}

ThunkAction loadContacts() {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      bool isPermitted = await Contacts.checkPermissions();
      if (isPermitted) {
        logger.info('Start - load contacts');
        List<Contact> contacts = await ContactController.getContacts();
        logger.info('Done - load contacts');
        store.dispatch(syncContactsCall(contacts));
      }
    } catch (error) {
      logger.severe('ERROR - load contacts $error');
    }
  };
}

ThunkAction updateTotalBalance() {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      ProWalletState proWalletState = store.state.proWalletState;
      num combiner(num previousValue, Token token) => token?.priceInfo != null
          ? previousValue +
              num.parse(Decimal.parse(token?.priceInfo?.total).toString())
          : previousValue + 0;
      List<Token> foreignTokens = List<Token>.from(
              proWalletState.erc20Tokens?.values ?? Iterable.empty())
          .where((Token token) =>
              num.parse(formatValue(token.amount, token.decimals,
                      withPrecision: true))
                  .compareTo(0) ==
              1)
          .toList();
      List<Token> allTokens = [...foreignTokens];
      num value = allTokens.fold<num>(0, combiner);
      store.dispatch(UpdateTotalBalance(totalBalance: value));
    } catch (error) {
      logger.severe('ERROR while update total balance $error');
    }
  };
}

ThunkAction setupWalletCall(walletData) {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      List<String> networks = List<String>.from(walletData['networks']);
      String walletAddress = walletData['walletAddress'];
      bool backup = walletData['backup'];
      String communityManagerAddress = walletData['communityManager'];
      String transferManagerAddress = walletData['transferManager'];
      String dAIPointsManagerAddress = walletData['dAIPointsManager'];
      store.dispatch(GetWalletAddressesSuccess(
          backup: backup,
          walletAddress: walletAddress,
          daiPointsManagerAddress: dAIPointsManagerAddress,
          communityManagerAddress: communityManagerAddress,
          transferManagerAddress: transferManagerAddress,
          networks: networks));
      store.dispatch(initWeb3Call(
          communityManagerAddress: communityManagerAddress,
          transferManagerAddress: transferManagerAddress,
          dAIPointsManagerAddress: dAIPointsManagerAddress));
      if (networks.contains(foreignNetwork)) {
        store.dispatch(initWeb3ProMode(
            communityManagerAddress: communityManagerAddress,
            transferManagerAddress: transferManagerAddress,
            dAIPointsManagerAddress: dAIPointsManagerAddress));
        Future.delayed(Duration(seconds: intervalSeconds), () {
          store.dispatch(startListenToTransferEvents());
          store.dispatch(startFetchBalancesOnForeign());
          store.dispatch(fetchTokensBalances());
          store.dispatch(startFetchTransferEventsCall());
          store.dispatch(startFetchTokensLastestPrices());
          store.dispatch(startProcessingTokensJobsCall());
        });
      } else {
        store.dispatch(createForiegnWalletOnlyIfNeeded());
      }
    } catch (e) {
      logger.severe('ERROR - getWalletAddressCall $e');
      store.dispatch(new ErrorAction('Could not get wallet address'));
    }
  };
}

ThunkAction getWalletAddressessCall() {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      dynamic walletData = await api.getWallet();
      store.dispatch(setupWalletCall(walletData));
    } catch (e) {
      logger.severe('ERROR - getWalletAddressCall $e');
      store.dispatch(new ErrorAction('Could not get wallet address'));
    }
  };
}

ThunkAction createForiegnWalletOnlyIfNeeded() {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      String walletAddress = store.state.userState.walletAddress;
      List transfersEvents = await ethereumExplorerApi
          .getTransferEventsByAccountAddress(walletAddress);
      if (transfersEvents.isNotEmpty) {
        dynamic response = await api.createWalletOnForeign(force: true);
        String jobId = response['job']['_id'];
        logger.info('Create wallet on foreign jobId - $jobId');
        store.dispatch(initWeb3ProMode());
        Future.delayed(Duration(seconds: intervalSeconds), () {
          store.dispatch(startListenToTransferEvents());
          store.dispatch(startFetchBalancesOnForeign());
          store.dispatch(fetchTokensBalances());
          store.dispatch(startFetchTransferEventsCall());
          store.dispatch(startFetchTokensLastestPrices());
          store.dispatch(startProcessingTokensJobsCall());
        });
        store.dispatch(segmentIdentifyCall(Map<String, dynamic>.from({
          "Pro mode active": true,
        })));
      }
    } catch (e) {
      logger.severe('ERROR - createForiegnWallet $e');
      store.dispatch(new ErrorAction('Could not get wallet address'));
    }
  };
}

ThunkAction activateProModeCall() {
  return (Store store) async {
    final logger = await AppFactory().getLogger('action');
    try {
      bool deployForeignToken =
          store.state.userState.networks.contains(foreignNetwork);
      if (!deployForeignToken) {
        dynamic response = await api.createWalletOnForeign();
        store.dispatch(initWeb3ProMode());
        String jobId = response['job']['_id'];
        logger.info('Create wallet on foreign jobId - $jobId');
        store.dispatch(segmentTrackCall('Activate pro mode clicked'));
        store.dispatch(startListenToTransferEvents());
        store.dispatch(startFetchBalancesOnForeign());
        store.dispatch(fetchTokensBalances());
        store.dispatch(startFetchTransferEventsCall());
        store.dispatch(startFetchTokensLastestPrices());
        store.dispatch(startProcessingTokensJobsCall());
        store.dispatch(segmentIdentifyCall(Map<String, dynamic>.from({
          "Pro mode active": true,
        })));
      }
    } catch (error) {
      logger.severe('Error createWalletOnForeign', error);
    }
  };
}

ThunkAction updateDisplayNameCall(String displayName) {
  return (Store store) async {
    try {
      String accountAddress = store.state.userState.accountAddress;
      await api.updateDisplayName(accountAddress, displayName);
      store.dispatch(SetDisplayName(displayName));
      store.dispatch(segmentTrackCall("Wallet: display name updated"));
      store.dispatch(segmentIdentifyCall(Map<String, dynamic>.from({
        "Display Name": displayName,
      })));
    } catch (e) {}
  };
}

ThunkAction updateUserAvatarCall(ImageSource source) {
  return (Store store) async {
    final picker = ImagePicker();
    final file = await picker.getImage(source: source);
    try {
      final uploadResponse = await api.uploadImage(File(file.path));
      print(uploadResponse);
      String accountAddress = store.state.userState.accountAddress;
      await api.updateAvatar(accountAddress, uploadResponse['hash']);
      store.dispatch(SetUserAvatar(uploadResponse['uri']));
      store.dispatch(segmentTrackCall("User avatar updated"));
    } catch (e) {}
  };
}

ThunkAction<AppState> getUserCartItems = (Store<AppState> store) async {
  http.Response response =
      await http.get('https://api.itsaboutpeepl.com/v1/paymentintent/create');
  final List<dynamic> responseData = json.decode(response.body);
  print(responseData);
  List<PeeplPay> peeplpay = [];
  responseData.forEach((peeplpayData) {
    final PeeplPay peeplPay = PeeplPay.fromJson(peeplpayData);
  });
  store.dispatch(GetUserCartItems(peeplpay));
};
