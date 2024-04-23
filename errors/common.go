package errors

import "errors"

var (
	ErrInternalServer = errors.New("internal server error")
	ErrInvalidCode    = errors.New("invalid code")
)

// This exists so I dont need to import errors package in every file
func Is(err, target error) bool {
	return errors.Is(err, target)
}
