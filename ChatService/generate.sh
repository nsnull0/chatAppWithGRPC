#!/bin/bash

protoc --proto_path=protos/ --go_out=plugins=grpc:protos/genbuf chat_proto.proto