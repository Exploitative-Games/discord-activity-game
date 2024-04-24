package modules

import (
	"errors"

	"github.com/diamondburned/arikawa/v3/discord"
)

type IncomingAuthPacket struct {
	Code string `json:"code"`
}

type OutgoingAuthPacket struct {
	AccessToken string        `json:"access_token"`
	User        *discord.User `json:"user"`
}

type IncomingCreateLobbyPacket struct{}

type OutgoingCreateLobbyPacket struct {
	LobbyID      int             `json:"lobby_id"`
	Players      []*discord.User `json:"players"`
	LobbyOwnerID discord.UserID  `json:"lobby_owner_id"`
}

func (event *IncomingCreateLobbyPacket) Process(client *Client) (interface{}, error) {
	if client.lobby != nil {
		return OutgoingCreateLobbyPacket{}, errors.New("client already in a lobby")
	}

	lobbyId, lobby := client.manager.CreateLobby()

	lobby.AddPlayer(client)

	return OutgoingCreateLobbyPacket{LobbyID: lobbyId, Players: lobby.GetPlayers(), LobbyOwnerID: client.DiscordUser.ID}, nil
}

type IncomingJoinLobbyPacket struct {
	LobbyID int `json:"lobby_id"`
}

type OutgoingJoinLobbyPacket struct {
	Players      []*discord.User `json:"players"`
	LobbyOwnerID discord.UserID  `json:"lobby_owner_id"`
}

func (event *IncomingJoinLobbyPacket) Process(client *Client) (interface{}, error) {
	if client.lobby != nil {
		return OutgoingJoinLobbyPacket{}, errors.New("client already in a lobby")
	}

	lobby := client.manager.Lobbies[event.LobbyID]
	if lobby == nil {
		return OutgoingJoinLobbyPacket{}, errors.New("lobby not found")
	}

	lobby.AddPlayer(client)

	return OutgoingJoinLobbyPacket{Players: lobby.GetPlayers(), LobbyOwnerID: lobby.OwnerID}, nil
}
