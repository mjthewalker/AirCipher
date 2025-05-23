//
//  Generated code. Do not modify.
//  source: cipher.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'cipher.pb.dart' as $0;

export 'cipher.pb.dart';

@$pb.GrpcServiceName('aircipher.AirService')
class AirServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  static final _$sendMessage = $grpc.ClientMethod<$0.Message, $0.MessageAck>(
      '/aircipher.AirService/SendMessage',
      ($0.Message value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.MessageAck.fromBuffer(value));

  AirServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.MessageAck> sendMessage($0.Message request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sendMessage, request, options: options);
  }
}

@$pb.GrpcServiceName('aircipher.AirService')
abstract class AirServiceBase extends $grpc.Service {
  $core.String get $name => 'aircipher.AirService';

  AirServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Message, $0.MessageAck>(
        'SendMessage',
        sendMessage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Message.fromBuffer(value),
        ($0.MessageAck value) => value.writeToBuffer()));
  }

  $async.Future<$0.MessageAck> sendMessage_Pre($grpc.ServiceCall $call, $async.Future<$0.Message> $request) async {
    return sendMessage($call, await $request);
  }

  $async.Future<$0.MessageAck> sendMessage($grpc.ServiceCall call, $0.Message request);
}
