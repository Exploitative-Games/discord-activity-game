package events

import (
	errors "server-go/errors"
	"server-go/common"
	"server-go/modules"
)

type IncomingAuthPacket struct {
	Code string `json:"code"`
}

type OutgoingAuthPacket struct {
	AccessToken string `json:"access_token"`
}

func (event *IncomingAuthPacket) Process() (interface{}, error) {
	discordToken, err := modules.ExchangeCode(event.Code, common.Config.RedirectUri)
	if err != nil {
		return OutgoingAuthPacket{}, errors.ErrInvalidCode
	}

	return OutgoingAuthPacket{AccessToken: discordToken.AccessToken}, nil
}
