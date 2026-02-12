package handlers

import (
	"comparebuddy-backend/config"
	"comparebuddy-backend/models"
	"github.com/gofiber/fiber/v2"
)

func GetMainCategories(c *fiber.Ctx) error {
	rows, err := config.DB.Query("SELECT id, name, name_en, icon_name FROM main_categories ORDER BY id")
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch categories"})
	}
	defer rows.Close()
	
	var categories []models.MainCategory
	for rows.Next() {
		var cat models.MainCategory
		rows.Scan(&cat.ID, &cat.Name, &cat.NameEn, &cat.IconName)
		categories = append(categories, cat)
	}
	
	return c.JSON(categories)
}

func GetSubCategories(c *fiber.Ctx) error {
	mainCategoryID := c.Query("main_category_id")
	
	query := "SELECT id, main_category_id, name, name_en FROM categories"
	args := []interface{}{}
	
	if mainCategoryID != "" {
		query += " WHERE main_category_id = ?"
		args = append(args, mainCategoryID)
	}
	
	query += " ORDER BY id"
	
	rows, err := config.DB.Query(query, args...)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch categories"})
	}
	defer rows.Close()
	
	var categories []models.Category
	for rows.Next() {
		var cat models.Category
		rows.Scan(&cat.ID, &cat.MainCategoryID, &cat.Name, &cat.NameEn)
		categories = append(categories, cat)
	}
	
	return c.JSON(categories)
}
