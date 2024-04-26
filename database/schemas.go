package database

import (
	"context"

	"github.com/uptrace/bun"
)

type Category struct {
	bun.BaseModel `bun:"table:categories" json:"-"`

	ID   int32  `bun:"id,pk,autoincrement" json:"id"`
	Name string `bun:"name" json:"name"`
}

type Question struct {
	bun.BaseModel `bun:"table:questions" json:"-"`

	ID              int32    `bun:"id,pk,autoincrement" json:"-"`
	CategoryID      int32    `bun:"category_id" json:"-"`
	Question        string   `bun:"question" json:"question"`
	PossibleAnswers []string `bun:"possible_answers" json:"possible_answers"`
}

func createSchema() error {
	models := []any{
		&Category{},
		&Question{},
	}

	for _, model := range models {
		if _, err := DB.NewCreateTable().IfNotExists().Model(model).Exec(context.Background()); err != nil {
			return err
		}
	}
	return nil
}
