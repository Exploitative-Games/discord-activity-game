package events

type IncomingAuthPacket struct {
	Code string `json:"code"`
}

type OutgoingAuthPacket struct {
	AccessToken string `json:"access_token"`
}
