import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:invoiceninja_flutter/data/models/serializers.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/data/web_client.dart';
import 'package:invoiceninja_flutter/utils/network.dart';

class PaymentRepository {
  const PaymentRepository({
    this.webClient = const WebClient(),
  });

  final WebClient webClient;

  Future<BuiltList<PaymentEntity>> loadList(Credentials credentials) async {
    final url = credentials.url + '/payments?include=paymentables';

    final dynamic response = await webClient.get(url, credentials.token);

    final PaymentListResponse paymentResponse = await compute<dynamic, dynamic>(
        computeDecode, <dynamic>[PaymentListResponse.serializer, response]);

    return paymentResponse.data;
  }

  Future<List<PaymentEntity>> bulkAction(
      Credentials credentials, List<String> ids, EntityAction action) async {
    final url = credentials.url + '/payments/bulk?include=paymentables';
    final dynamic response = await webClient.post(url, credentials.token,
        data: json.encode({'ids': ids, 'action': '$action'}));

    final PaymentListResponse paymentResponse =
        serializers.deserializeWith(PaymentListResponse.serializer, response);

    return paymentResponse.data.toList();
  }

  Future<PaymentEntity> saveData(Credentials credentials, PaymentEntity payment,
      {EntityAction action, bool sendEmail = false}) async {
    final data = serializers.serializeWith(PaymentEntity.serializer, payment);
    dynamic response;

    if (payment.isNew) {
      var url = credentials.url + '/payments?include=paymentables';
      if (sendEmail) {
        url += '&email_receipt=true';
      }
      response =
          await webClient.post(url, credentials.token, data: json.encode(data));
    } else {
      var url =
          '${credentials.url}/payments/${payment.id}?include=paymentables';
      if (sendEmail) {
        url += '&email_receipt=true';
      }
      if (action != null) {
        url += '&action=' + action.toString();
      }
      response =
          await webClient.put(url, credentials.token, data: json.encode(data));
    }

    final PaymentItemResponse paymentResponse =
        serializers.deserializeWith(PaymentItemResponse.serializer, response);

    return paymentResponse.data;
  }

  Future<PaymentEntity> refundPayment(
      Credentials credentials, PaymentEntity payment,
      {bool sendEmail = false}) async {
    final data = serializers.serializeWith(PaymentEntity.serializer, payment);
    dynamic response;

    var url = credentials.url + '/payments/refund?include=paymentables';
    if (sendEmail) {
      url += '&email_receipt=true';
    }
    response =
        await webClient.post(url, credentials.token, data: json.encode(data));

    final PaymentItemResponse paymentResponse =
        serializers.deserializeWith(PaymentItemResponse.serializer, response);

    return paymentResponse.data;
  }
}
