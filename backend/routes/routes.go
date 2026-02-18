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
	
	// Auth
	auth := api.Group("/auth")
	auth.Post("/register", handlers.Register)
	auth.Post("/login", handlers.Login)
	auth.Post("/google", handlers.GoogleLogin)

	// Cars
	cars := api.Group("/cars")
	cars.Get("/brands", handlers.GetCarBrands)
	cars.Get("/brands/:id", handlers.GetCarBrandByID)
	cars.Get("/models", handlers.GetCarModels)
	cars.Get("/models/:id", handlers.GetCarModelByID)
	cars.Get("/variants/:id", handlers.GetCarVariantByID)
	cars.Get("/compare", handlers.CompareCarVariants)
	cars.Get("/search", handlers.SearchCars)
	cars.Get("/browse", handlers.BrowseCarVariants)

	// Health check
	api.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "OK",
			"message": "Go Backend is running",
		})
	})
}
