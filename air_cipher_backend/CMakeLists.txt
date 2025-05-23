cmake_minimum_required(VERSION 3.10)
project(aircipher)

find_package(Protobuf CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

add_executable(server server.cpp artifacts/cipher.pb.cc artifacts/cipher.grpc.pb.cc)
target_link_libraries(server gRPC::grpc++ protobuf::libprotobuf)
