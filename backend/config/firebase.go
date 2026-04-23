package config

import (
	"context"
	"log"

	firebase "firebase.google.com/go"
	"google.golang.org/api/option"
)

var AuthClient *firebase.App

func InitFirebase() {
	opt := option.WithCredentialsFile("firebase-service-account.json")

	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		log.Fatal("Firebase init error:", err)
	}

	AuthClient = app
	log.Println("Firebase initialized")
}