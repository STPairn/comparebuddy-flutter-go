package main

import (
	"comparebuddy-backend/config"
	"comparebuddy-backend/routes"
	"log"
	"os"
	
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/joho/godotenv"
)

func main() {
	godotenv.Load()
	
	// Connect to database
	config.ConnectDB()
	defer config.DB.Close()
	
	// Create Fiber app
	app := fiber.New(fiber.Config{
		AppName: "CompareBuddy API v1.0",
	})
	
	// CORS middleware
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowHeaders: "Origin, Content-Type, Accept",
		AllowMethods: "GET, POST, PUT, DELETE",
	}))
	
	// Setup routes
	routes.SetupRoutes(app)
	
	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	
	log.Printf("🚀 Go Backend running on http://localhost:%s\n", port)
	log.Fatal(app.Listen(":" + port))
}
