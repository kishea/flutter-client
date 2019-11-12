import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/payment/payment_actions.dart';
import 'package:invoiceninja_flutter/redux/payment/payment_selectors.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';
import 'package:invoiceninja_flutter/ui/payment/payment_list.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';

class PaymentListBuilder extends StatelessWidget {
  const PaymentListBuilder({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, PaymentListVM>(
      converter: PaymentListVM.fromStore,
      builder: (context, viewModel) {
        return PaymentList(
          viewModel: viewModel,
        );
      },
    );
  }
}

class PaymentListVM {
  PaymentListVM({
    @required this.user,
    @required this.paymentList,
    @required this.paymentMap,
    @required this.clientMap,
    @required this.filter,
    @required this.isLoading,
    @required this.isLoaded,
    @required this.onPaymentTap,
    @required this.onRefreshed,
    @required this.onEntityAction,
    @required this.onClearEntityFilterPressed,
    @required this.onViewEntityFilterPressed,
    @required this.listState,
  });

  static PaymentListVM fromStore(Store<AppState> store) {
    Future<Null> _handleRefresh(BuildContext context) {
      if (store.state.isLoading) {
        return Future<Null>(null);
      }
      final completer = snackBarCompleter<Null>(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(LoadPayments(completer: completer, force: true));
      return completer.future;
    }

    final state = store.state;

    return PaymentListVM(
      user: state.user,
      paymentList: memoizedFilteredPaymentList(
          state.paymentState.map,
          state.paymentState.list,
          state.invoiceState.map,
          state.clientState.map,
          state.paymentListState),
      paymentMap: state.paymentState.map,
      clientMap: state.clientState.map,
      isLoading: state.isLoading,
      isLoaded: state.paymentState.isLoaded,
      filter: state.paymentUIState.listUIState.filter,
      listState: state.paymentListState,
      onPaymentTap: (context, payment) {
        store.dispatch(ViewPayment(paymentId: payment.id, context: context));
      },
      onEntityAction: (BuildContext context, List<BaseEntity> payments,
              EntityAction action) =>
          handlePaymentAction(context, payments, action),
      onClearEntityFilterPressed: () =>
          store.dispatch(FilterPaymentsByEntity()),
      onViewEntityFilterPressed: (BuildContext context) => viewEntityById(
          context: context,
          entityId: state.paymentListState.filterEntityId,
          entityType: state.paymentListState.filterEntityType),
      onRefreshed: (context) => _handleRefresh(context),
    );
  }

  final UserEntity user;
  final ListUIState listState;
  final List<String> paymentList;
  final BuiltMap<String, PaymentEntity> paymentMap;
  final BuiltMap<String, ClientEntity> clientMap;
  final String filter;
  final bool isLoading;
  final bool isLoaded;
  final Function(BuildContext, PaymentEntity) onPaymentTap;
  final Function(BuildContext) onRefreshed;
  final Function onClearEntityFilterPressed;
  final Function(BuildContext) onViewEntityFilterPressed;
  final Function(BuildContext, List<PaymentEntity>, EntityAction)
      onEntityAction;
}
