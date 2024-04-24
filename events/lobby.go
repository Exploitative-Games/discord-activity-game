package events

type IncomingCreateLobbyPacket struct {}

type OutgoingCreateLobbyPacket struct {}

func (event *IncomingCreateLobbyPacket) Process() (interface{}, error) {
	return OutgoingCreateLobbyPacket{}, nil
}