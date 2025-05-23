#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>
#include "artifacts/cipher.grpc.pb.h"

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using aircipher::AirService;
using aircipher::Message;
using aircipher::MessageAck;

class AirServiceImpl final : public AirService::Service {
    Status SendMessage(ServerContext* context, const Message* request, MessageAck* response) override {
        std::cout << "Received message from: " << request->sender_uid() << std::endl;
        std::cout << "Content: " << request->payload() << std::endl;

        response->set_recieved(true);
        response->set_status("Message received.");
        return Status::OK;
    }
};

void RunServer() {
    std::string server_address("0.0.0.0:50051");
    AirServiceImpl service;

    ServerBuilder builder;
    builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
    builder.RegisterService(&service);

    std::unique_ptr<Server> server(builder.BuildAndStart());
    std::cout << "Server listening on " << server_address << std::endl;
    server->Wait();
}

int main() {
    RunServer();
    return 0;
}
