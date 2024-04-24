package common

import (
	"encoding/json"
	"strconv"
)

type Snowflake int64

func ToSnowflake(s string) Snowflake {
	stringToSnowflake, _ := strconv.ParseInt(s, 10, 64)
	return Snowflake(stringToSnowflake)
}

func (s Snowflake) String() string {
	return strconv.FormatInt(int64(s), 10)
}

type Packet struct {
	Op    string          `json:"op"`
	Data  json.RawMessage `json:"d"`
	Error string          `json:"e,omitempty"`
}