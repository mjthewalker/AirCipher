import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:frontend/grpc/artifacts/cipher.pbgrpc.dart';
class ChatClient {
  late final AirServiceClient stub;
  late final ClientChannel channel;

  Future<void> init() async {
    channel = ClientChannel(
      '192.168.1.6',
      port: 50051,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    stub = AirServiceClient(channel);
  }

  Future<void> sendMessage(String senderId, String receiverId, String payload) async {
    final message = Message()
      ..senderUid = senderId
      ..recieverUid = receiverId
      ..payload = payload
      ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch);

    final ack = await stub.sendMessage(message);
    print('Server ACK: ${ack.recieved}, ${ack.status}');
  }

  Future<void> shutdown() async {
    await channel.shutdown();
  }
}
