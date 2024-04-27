package questionmanager

import (
	"context"
	"server-go/database"
)

func GetRandomCategories(n int) (categories []database.Category, err error) {
	err = database.DB.NewSelect().Model(&categories).Order("BY RANDOM()").Limit(n).Scan(context.Background(), &categories)
	return
}

func GetCategoryWithID(id int) (category database.Category, err error) {
	err = database.DB.NewSelect().Model(&category).Where("id = ?", id).Scan(context.Background(), &category)
	return
}
