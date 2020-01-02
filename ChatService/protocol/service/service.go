package chatservice

import (
	"context"
	"fmt"
	"sync"
	"time"

	chatservice "github.com/nsnull0/ChatService/protos/genbuf"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// Message is content message sent by user
type Message struct {
	SenderAlias string `bson:"sender_alias"`
	Message     string `bson:"message"`
	Time        string `bson:"timestamp"`
}

// Room is room created by User
type Room struct {
	RoomID   string    `bson:"room_id"`
	Messages []Message `bson:"messages"`
}

// User is sender or receiver
type User struct {
	UserAlias string `bson:"user_alias"`
	RoomID    string `bson:"room_id"`
}

// CollectionUser is for user db
var CollectionUser *mongo.Collection

// CollectionRoom is for room db
var CollectionRoom *mongo.Collection

// CollectionMessages is for message db
var CollectionMessages *mongo.Collection

// Connection is for Server have several connection ?
type Connection struct {
	stream chatservice.ChatService_CreateStreamServer
	id     string
	active bool
	error  chan error
}

// Server is the interface service of this service
type Server struct {
	Connnection []*Connection
}

// RegisterOrLoginUser is for login or register
func (s *Server) RegisterOrLoginUser(ctx context.Context, req *chatservice.LoginRequest) (*chatservice.LoginResponse, error) {
	fmt.Println("Register/Login User is invoked")
	reqUser := &User{
		UserAlias: req.GetRequest().GetAliasname(),
	}
	room := &Room{}

	filter := bson.M{"user_alias": reqUser.UserAlias}
	res := CollectionUser.FindOne(ctx, filter)
	if err := res.Decode(reqUser); err != nil {
		fmt.Println("User is not existed")
		_, errInsert := CollectionUser.InsertOne(ctx, reqUser)
		if errInsert != nil {
			return nil, status.Errorf(codes.Internal, "Internal Error Occured while creating User %v\n", errInsert)
		}
		fmt.Printf("User is created %v \n", reqUser)
	}

	filter = bson.M{"room_id": reqUser.RoomID}
	res = CollectionRoom.FindOne(ctx, filter)
	if err := res.Decode(room); err != nil {
		fmt.Println("User is not join any room")
		reqUser.RoomID = ""
	} else {
		fmt.Printf("User is already join some room %v \n", room.RoomID)
	}

	fmt.Println("User is valid")

	loginRes := &chatservice.LoginResponse{
		Result: &chatservice.User{
			Aliasname: reqUser.UserAlias,
			HasRoom:   len(room.RoomID) > 0,
		},
	}
	return loginRes, nil
}

// RegisterOrJoinRoom is to register or join a room, user will move to other room if the requested user don't have room
func (s *Server) RegisterOrJoinRoom(ctx context.Context, req *chatservice.RoomRequest) (*chatservice.RoomResponse, error) {
	fmt.Println("Register or Join Room is invoked")
	room := &Room{}
	user := &User{}

	filter := bson.M{"room_id": req.GetRoomId()}

	filterUser := bson.M{"user_alias": req.GetAliasName()}
	emptyMessages := make([]Message, 0)

	res := CollectionRoom.FindOne(ctx, filter)
	if err := res.Decode(room); err != nil {
		fmt.Println("Room is new and not existed")
		room.RoomID = req.GetRoomId()
		room.Messages = emptyMessages
		_, errInsert := CollectionRoom.InsertOne(ctx, room)
		if errInsert != nil {
			return nil, status.Errorf(codes.Internal, "Internal Error occured while inserting room %v\n", errInsert)
		}
		fmt.Printf("Room has created %v\n", room)
	}

	res = CollectionUser.FindOne(ctx, filterUser)
	if err := res.Decode(user); err != nil {
		fmt.Println("Client error, should do register user first!")
		return nil, status.Errorf(codes.Unauthenticated, "Can't find User with received alias name, %v", err)
	}

	user.RoomID = room.RoomID
	_, errUpdate := CollectionUser.ReplaceOne(ctx, filterUser, user)
	if errUpdate != nil {
		fmt.Println("Update User Error")
		return nil, status.Errorf(codes.Internal, "Internal Error occured while updating User, %v \n", errUpdate)
	}

	fmt.Printf("User has updated %v \n", user)

	fmt.Println("Updating corresponding user and join room")

	var roomMessagesRes []*chatservice.UserMessage
	for _, element := range room.Messages {
		msgRes := &chatservice.UserMessage{
			Aliasname: element.SenderAlias,
			Message:   element.Message,
		}
		fmt.Printf("message %v\n", element.Message)
		roomMessagesRes = append(roomMessagesRes, msgRes)
		fmt.Printf("messages %v\n", roomMessagesRes)
	}

	user.RoomID = room.RoomID
	roomResponse := &chatservice.RoomResponse{
		Response: &chatservice.Room{
			RoomId:   room.RoomID,
			Messages: roomMessagesRes,
		},
	}
	fmt.Printf("Room has been created %v \n", room.RoomID)
	return roomResponse, nil
}

// // SendMessage is for streaming response and request messaging
// func (s *Server) SendMessage(stream chatservice.ChatService_SendMessageServer) error {
// 	fmt.Println("Stream messaging invoked")
// 	for {
// 		req, err := stream.Recv()
// 		if err == io.EOF {
// 			fmt.Printf("End of file")
// 			return nil
// 		}
// 		if err != nil {
// 			log.Fatalf("error while reading messaging stream: %v", err)
// 		}

// 		currentTime := time.Now().UTC().String()
// 		msgObject := Message{
// 			SenderAlias: req.GetSenderalias(),
// 			Message:     req.GetMessage(),
// 			Time:        currentTime,
// 		}

// 		room := &Room{}
// 		filterRoom := bson.M{"room_id": req.GetRoomId()}
// 		res := CollectionUser.FindOne(stream.Context(), filterRoom)
// 		if err := res.Decode(room); err != nil {
// 			fmt.Println("room not exist")
// 			return status.Errorf(codes.NotFound, "Room not found %v\n")
// 		}
// 		room.Messages = append(room.Messages, msgObject)
// 		updates := bson.M{
// 			"$addToSet": bson.M{"messages": bson.M{"$each": room.Messages}},
// 		}
// 		_, errUpdate := CollectionRoom.UpdateOne(stream.Context(), filterRoom, updates)
// 		if errUpdate != nil {
// 			fmt.Printf("Error on update, %v\n", errUpdate)
// 			return status.Errorf(codes.Internal, "Internal error occured while updating the message record: %v\n", errUpdate)
// 		}

// 		msgRes := &chatservice.SendMessageResponse{
// 			RoomId:      room.RoomID,
// 			Senderalias: req.GetSenderalias(),
// 			Message:     req.GetMessage(),
// 		}

// 		castingErr := stream.Send(msgRes)
// 		if castingErr != nil {
// 			log.Fatalf("error while sending casting to the client: %v", castingErr)
// 			return err
// 		}
// 	}

// }

// CreateStream is for stream the message to client
func (s *Server) CreateStream(connect *chatservice.StreamConnect, stream chatservice.ChatService_CreateStreamServer) error {
	conn := &Connection{
		stream: stream,
		id:     connect.GetSenderalias(),
		active: true,
		error:  make(chan error),
	}

	s.Connnection = append(s.Connnection, conn)

	return <-conn.error
}

// SendMessage is for broadcast all message to client
func (s *Server) SendMessage(ctx context.Context, req *chatservice.ContentMessage) (*chatservice.Empty, error) {

	currentTime := time.Now().UTC().String()
	msgObject := Message{
		SenderAlias: req.GetSenderId(),
		Message:     req.GetContent(),
		Time:        currentTime,
	}

	room := &Room{}
	filterRoom := bson.M{"room_id": req.GetRoomId()}
	res := CollectionUser.FindOne(ctx, filterRoom)
	if err := res.Decode(room); err != nil {
		fmt.Println("room not exist")
		status.Errorf(codes.NotFound, "Room not found %v\n")
	}
	room.Messages = append(room.Messages, msgObject)
	updates := bson.M{
		"$addToSet": bson.M{"messages": bson.M{"$each": room.Messages}},
	}
	updateRes, errUpdate := CollectionRoom.UpdateOne(ctx, filterRoom, updates)
	if errUpdate != nil {
		fmt.Printf("Error on update, %v\n", errUpdate)
		status.Errorf(codes.Internal, "Internal error occured while updating the message record: %v\n", errUpdate)
	}
	fmt.Printf("Messages has been added: %v - %v \n", room.Messages, updateRes.ModifiedCount)

	syncWait := sync.WaitGroup{}
	finish := make(chan int)

	for _, conn := range s.Connnection {
		syncWait.Add(1)
		go func(messageContent *chatservice.ContentMessage, conn *Connection) {
			defer syncWait.Done()
			if conn.active {
				err := conn.stream.Send(messageContent)
				fmt.Printf("Send Message to: %v\n", conn.stream)
				if err != nil {
					fmt.Printf("Error while streaming: %v\n", err)
					conn.active = false
					conn.error <- err
				}
			}
		}(req, conn)
	}

	go func() {
		syncWait.Wait()
		close(finish)
	}()

	<-finish
	return &chatservice.Empty{}, nil
}
