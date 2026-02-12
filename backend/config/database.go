package config

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	_ "github.com/go-sql-driver/mysql"
	"github.com/joho/godotenv"
)

var DB *sql.DB

func ConnectDB() {
	godotenv.Load()
	
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_NAME"),
	)
	
	var err error
	DB, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal("❌ Database connection failed:", err)
	}
	
	if err = DB.Ping(); err != nil {
		log.Fatal("❌ Database ping failed:", err)
	}
	
	log.Println("✅ Database connected successfully")
}
