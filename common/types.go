package common

import "strconv"

type Snowflake int64

func ToSnowflake(s string) Snowflake {
	stringToSnowflake, _ := strconv.ParseInt(s, 10, 64)
	return Snowflake(stringToSnowflake)
}

func (s Snowflake) String() string {
	return strconv.FormatInt(int64(s), 10)
}
