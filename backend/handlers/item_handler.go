package handlers

import (
	"comparebuddy-backend/config"
	"comparebuddy-backend/models"
	"github.com/gofiber/fiber/v2"
)

func GetItems(c *fiber.Ctx) error {
	categoryID := c.Query("category_id")
	brand := c.Query("brand")
	field := c.Query("field")
	
	query := "SELECT id, category_id, brand, name, duration, price, COALESCE(field, '') FROM items WHERE 1=1"
	args := []interface{}{}
	
	if categoryID != "" {
		query += " AND category_id = ?"
		args = append(args, categoryID)
	}
	if brand != "" {
		query += " AND brand LIKE ?"
		args = append(args, "%"+brand+"%")
	}
	if field != "" {
		query += " AND field = ?"
		args = append(args, field)
	}
	
	query += " ORDER BY brand, price"
	
	rows, err := config.DB.Query(query, args...)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch items"})
	}
	defer rows.Close()
	
	var items []models.Item
	for rows.Next() {
		var item models.Item
		rows.Scan(&item.ID, &item.CategoryID, &item.Brand, &item.Name, &item.Duration, &item.Price, &item.Field)
		items = append(items, item)
	}
	
	return c.JSON(items)
}

func GetBrands(c *fiber.Ctx) error {
	categoryID := c.Query("category_id")
	
	query := "SELECT DISTINCT brand FROM items"
	args := []interface{}{}
	
	if categoryID != "" {
		query += " WHERE category_id = ?"
		args = append(args, categoryID)
	}
	
	query += " ORDER BY brand"
	
	rows, err := config.DB.Query(query, args...)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch brands"})
	}
	defer rows.Close()
	
	var brands []string
	for rows.Next() {
		var brand string
		rows.Scan(&brand)
		brands = append(brands, brand)
	}
	
	return c.JSON(brands)
}

func GetFields(c *fiber.Ctx) error {
	categoryID := c.Query("category_id")
	
	query := "SELECT DISTINCT field FROM items WHERE field IS NOT NULL AND field != ''"
	args := []interface{}{}
	
	if categoryID != "" {
		query += " AND category_id = ?"
		args = append(args, categoryID)
	}
	
	query += " ORDER BY field"
	
	rows, err := config.DB.Query(query, args...)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch fields"})
	}
	defer rows.Close()
	
	var fields []string
	for rows.Next() {
		var field string
		rows.Scan(&field)
		fields = append(fields, field)
	}
	
	return c.JSON(fields)
}
