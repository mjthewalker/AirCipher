//
//  Generated code. Do not modify.
//  source: cipher.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class Message extends $pb.GeneratedMessage {
  factory Message({
    $core.String? senderUid,
    $core.String? recieverUid,
    $core.String? payload,
    $fixnum.Int64? timestamp,
  }) {
    final $result = create();
    if (senderUid != null) {
      $result.senderUid = senderUid;
    }
    if (recieverUid != null) {
      $result.recieverUid = recieverUid;
    }
    if (payload != null) {
      $result.payload = payload;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    return $result;
  }
  Message._() : super();
  factory Message.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Message.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Message', package: const $pb.PackageName(_omitMessageNames ? '' : 'aircipher'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'senderUid')
    ..aOS(2, _omitFieldNames ? '' : 'recieverUid')
    ..aOS(3, _omitFieldNames ? '' : 'payload')
    ..aInt64(4, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message clone() => Message()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message copyWith(void Function(Message) updates) => super.copyWith((message) => updates(message as Message)) as Message;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Message create() => Message._();
  Message createEmptyInstance() => create();
  static $pb.PbList<Message> createRepeated() => $pb.PbList<Message>();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Message>(create);
  static Message? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get senderUid => $_getSZ(0);
  @$pb.TagNumber(1)
  set senderUid($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSenderUid() => $_has(0);
  @$pb.TagNumber(1)
  void clearSenderUid() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get recieverUid => $_getSZ(1);
  @$pb.TagNumber(2)
  set recieverUid($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRecieverUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecieverUid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get payload => $_getSZ(2);
  @$pb.TagNumber(3)
  set payload($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => $_clearField(4);
}

class MessageAck extends $pb.GeneratedMessage {
  factory MessageAck({
    $core.bool? recieved,
    $core.String? status,
  }) {
    final $result = create();
    if (recieved != null) {
      $result.recieved = recieved;
    }
    if (status != null) {
      $result.status = status;
    }
    return $result;
  }
  MessageAck._() : super();
  factory MessageAck.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MessageAck.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MessageAck', package: const $pb.PackageName(_omitMessageNames ? '' : 'aircipher'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'recieved')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAck clone() => MessageAck()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAck copyWith(void Function(MessageAck) updates) => super.copyWith((message) => updates(message as MessageAck)) as MessageAck;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageAck create() => MessageAck._();
  MessageAck createEmptyInstance() => create();
  static $pb.PbList<MessageAck> createRepeated() => $pb.PbList<MessageAck>();
  @$core.pragma('dart2js:noInline')
  static MessageAck getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageAck>(create);
  static MessageAck? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get recieved => $_getBF(0);
  @$pb.TagNumber(1)
  set recieved($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasRecieved() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecieved() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
