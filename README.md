# GRPC Streaming Chat GO server with Swift client app

## Feature Try out
- SwiftUI 
- Combine 
- GRPC-Swift
- Golang GRPC
- MongoDB
- Evans CLI

## Setup
- follow the guide of installing GRPC Go at Reference section
- Copy `ChatService` Dir to your `Go` directory
- to generate proto of swift client go to the directory of protos
```
protoc chat_proto.proto --swift_out=. --swiftgrpc_out=Client=true,Server=false:.
```
- to generate proto of Go Server go to the root directory of project
```
protoc --proto_path=protos/ --go_out=plugins=grpc:protos/genbuf chat_proto.proto
```
or run the script
```
./generate.sh
```

## Reference
- https://grpc.io/
- https://github.com/grpc/grpc-swift
- https://github.com/nickffox/KeyboardObserving
- https://talk.objc.io/
- https://github.com/ktr0731/evans

### Notes: Open For Everybody, Feel Free to do PR, Let's Learn together!
