package config

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

// FirebaseAuth adalah instance Firebase Auth yang dipakai untuk verify token
var FirebaseAuth *auth.Client

func InitFirebase() {
	credPath := os.Getenv("FIREBASE_CREDENTIALS_PATH")

	if credPath == "" {
		log.Fatal("FIREBASE_CREDENTIALS_PATH tidak diset di .env\n" +
			"Download service account key dari Firebase Console:\n" +
			"  Project Settings → Service accounts → Generate new private key\n" +
			"Simpan file JSON ke folder backend/ lalu set FIREBASE_CREDENTIALS_PATH=nama-file.json di .env")
	}

	if _, err := os.Stat(credPath); os.IsNotExist(err) {
		log.Fatalf("File Firebase credentials tidak ditemukan: %s\n"+
			"Download service account key dari Firebase Console:\n"+
			"  Project Settings → Service accounts → Generate new private key\n"+
			"Simpan sebagai: backend/%s", credPath, credPath)
	}

	opt := option.WithCredentialsFile(credPath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		log.Fatalf("Gagal init Firebase: %v", err)
	}

	FirebaseAuth, err = app.Auth(context.Background())
	if err != nil {
		log.Fatalf("Gagal mendapatkan Firebase Auth client: %v", err)
	}

	log.Println("Firebase Admin SDK berhasil diinisialisasi")
}
