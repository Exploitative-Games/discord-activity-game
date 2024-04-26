package database

import (
	"database/sql"
	"fmt"
	"log"

	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/sqlitedialect"
	"github.com/uptrace/bun/driver/sqliteshim"
	//"github.com/uptrace/bun/extra/bundebug"
)

var DB *bun.DB

func InitDB() {
	sqldb, err := sql.Open(sqliteshim.ShimName, "file:dcgame.sqlite?cache=shared")

	if err != nil {
		log.Println("Failed to open database")
		log.Panic(err)
	}

	sqldb.SetMaxIdleConns(1000)
	sqldb.SetConnMaxLifetime(0)

	DB = bun.NewDB(sqldb, sqlitedialect.New())

	fmt.Println("Database Loaded")

	// create database structure if doesn't exist
	if err := createSchema(); err != nil {
		log.Println("Failed to create schema")
		log.Panic(err)
	}
}
