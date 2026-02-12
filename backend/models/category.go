package models

type MainCategory struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	NameEn   string `json:"name_en"`
	IconName string `json:"icon_name"`
}

type Category struct {
	ID             int    `json:"id"`
	MainCategoryID int    `json:"main_category_id"`
	Name           string `json:"name"`
	NameEn         string `json:"name_en"`
}
