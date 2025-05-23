//
//  Generated code. Do not modify.
//  source: cipher.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'sender_uid', '3': 1, '4': 1, '5': 9, '10': 'senderUid'},
    {'1': 'reciever_uid', '3': 2, '4': 1, '5': 9, '10': 'recieverUid'},
    {'1': 'payload', '3': 3, '4': 1, '5': 9, '10': 'payload'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 3, '10': 'timestamp'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEh0KCnNlbmRlcl91aWQYASABKAlSCXNlbmRlclVpZBIhCgxyZWNpZXZlcl91aW'
    'QYAiABKAlSC3JlY2lldmVyVWlkEhgKB3BheWxvYWQYAyABKAlSB3BheWxvYWQSHAoJdGltZXN0'
    'YW1wGAQgASgDUgl0aW1lc3RhbXA=');

@$core.Deprecated('Use messageAckDescriptor instead')
const MessageAck$json = {
  '1': 'MessageAck',
  '2': [
    {'1': 'recieved', '3': 1, '4': 1, '5': 8, '10': 'recieved'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `MessageAck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageAckDescriptor = $convert.base64Decode(
    'CgpNZXNzYWdlQWNrEhoKCHJlY2lldmVkGAEgASgIUghyZWNpZXZlZBIWCgZzdGF0dXMYAiABKA'
    'lSBnN0YXR1cw==');

