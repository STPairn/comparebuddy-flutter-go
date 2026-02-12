package models

type Item struct {
	ID         int     `json:"id"`
	CategoryID int     `json:"category_id"`
	Brand      string  `json:"brand"`
	Name       string  `json:"name"`
	Duration   string  `json:"duration"`
	Price      float64 `json:"price"`
	Field      string  `json:"field"`
}
