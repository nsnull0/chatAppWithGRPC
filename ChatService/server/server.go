package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"time"

	chatservice "github.com/nsnull0/ChatService/protocol/service"
	chatservicepb "github.com/nsnull0/ChatService/protos/genbuf"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	var chatConnections []*chatservice.Connection

	fmt.Println("Coonecting to MongoDB")
	client, err := mongo.NewClient(options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		log.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	err = client.Connect(ctx)
	defer cancel()
	chatservice.CollectionUser = client.Database("chatdb").Collection("user")
	chatservice.CollectionRoom = client.Database("chatdb").Collection("room")
	chatservice.CollectionMessages = client.Database("chatdb").Collection("messages")
	fmt.Println("mongoDB is ready...")

	s := grpc.NewServer()
	chatservicepb.RegisterChatServiceServer(s, &chatservice.Server{Connnection: chatConnections})
	reflection.Register(s)

	lis, err := net.Listen("tcp", "0.0.0.0:8080")
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	go func() {
		fmt.Println("Starting Server 1...")
		if err := s.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	// Wait for Control C to exit
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt)

	// Block until a signal is received
	<-ch
	fmt.Println("Stoppping the server")
	s.Stop()
	fmt.Println("Closing the listener")
	lis.Close()
	fmt.Println("Close MongoDB Connections")
	client.Disconnect(ctx)
	fmt.Println("End of Program")
}
