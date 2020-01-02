package main

import (
	"bufio"
	"context"
	"fmt"
	"log"
	"os"
	"sync"

	chatservice "github.com/nsnull0/ChatService/protos/genbuf"
	"google.golang.org/grpc"
)

var client chatservice.ChatServiceClient
var wait *sync.WaitGroup

func init() {
	wait = &sync.WaitGroup{}
}

func connect(user *chatservice.StreamConnect) error {
	var streamerror error

	stream, err := client.CreateStream(context.Background(), &chatservice.StreamConnect{
		Senderalias: user.GetSenderalias(),
		RoomId:      user.GetRoomId(),
		Active:      true,
	})

	if err != nil {
		return fmt.Errorf("connection failed: %v", err)
	}

	wait.Add(1)
	go func(str chatservice.ChatService_CreateStreamClient) {
		defer wait.Done()

		for {
			msg, err := str.Recv()
			if err != nil {
				streamerror = fmt.Errorf("Error reading message: %v", err)
				break
			}

			fmt.Printf("%v : %s\n", msg.GetSenderId(), msg.Content)

		}
	}(stream)

	return streamerror
}

func main() {
	done := make(chan int)

	conn, err := grpc.Dial("0.0.0.0:8080", grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Couldnt connect to service: %v", err)
	}

	client = chatservice.NewChatServiceClient(conn)
	user := &chatservice.StreamConnect{
		Senderalias: "Yoseph201908",
		RoomId:      "Yosephaliasroom",
	}

	connect(user)

	wait.Add(1)
	go func() {
		defer wait.Done()

		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			msg := &chatservice.ContentMessage{
				RoomId:   "Yosephaliasroom",
				Content:  scanner.Text(),
				SenderId: "Yoseph201908",
			}

			_, err := client.SendMessage(context.Background(), msg)
			if err != nil {
				fmt.Printf("Error Sending Message: %v", err)
				break
			}
		}

	}()

	go func() {
		wait.Wait()
		close(done)
	}()

	<-done
}
