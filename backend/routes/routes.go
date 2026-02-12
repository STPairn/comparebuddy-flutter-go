package routes

import (
	"comparebuddy-backend/handlers"
	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(app *fiber.App) {
	api := app.Group("/api")
	
	// Categories
	api.Get("/categories/main", handlers.GetMainCategories)
	api.Get("/categories/sub", handlers.GetSubCategories)
	
	// Items
	api.Get("/items", handlers.GetItems)
	api.Get("/items/meta/brands", handlers.GetBrands)
	api.Get("/items/meta/fields", handlers.GetFields)
	
	// Health check
	api.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "OK",
			"message": "Go Backend is running",
		})
	})
}
