package modules

import (
	"errors"
	"server-go/common"
	"server-go/modules/discord_utils"

	"github.com/diamondburned/arikawa/v3/discord"
)

type IncomingAuthPacket struct {
	Code string `json:"code"`
}

type OutgoingAuthPacket struct {
	AccessToken string              `json:"access_token"`
	User        *discord_utils.User `json:"user"`
}

type IncomingCreateLobbyPacket struct{}

type OutgoingCreateLobbyPacket struct {
	LobbyID      int                   `json:"lobby_id"`
	Players      []*discord_utils.User `json:"players"`
	LobbyOwnerID discord.UserID        `json:"lobby_owner_id"`
}

func (event *IncomingCreateLobbyPacket) Process(client *Client) (interface{}, error) {
	if client.lobby != nil {
		return OutgoingCreateLobbyPacket{}, errors.New("client already in a lobby")
	}

	lobbyId, lobby := client.manager.CreateLobby()

	lobby.AddPlayer(client)
	lobby.OwnerID = client.DiscordUser.ID

	return OutgoingCreateLobbyPacket{LobbyID: lobbyId, Players: lobby.GetPlayers(), LobbyOwnerID: client.DiscordUser.ID}, nil
}

type IncomingJoinLobbyPacket struct {
	LobbyID int `json:"lobby_id"`
}

type OutgoingJoinLobbyPacket struct {
	Players      []*discord_utils.User `json:"players"`
	LobbyOwnerID discord.UserID        `json:"lobby_owner_id"`
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

	client.manager.BroadcastToLobby(client.lobby.ID, "player_joined", OutgoingLobbyPlayerLeftPacket{
		Player: client.DiscordUser,
	})

	return OutgoingJoinLobbyPacket{Players: lobby.GetPlayers(), LobbyOwnerID: lobby.OwnerID}, nil
}

type IncomingLeaveLobbyPacket struct{}

type OutgoingLeaveLobbyPacket struct{}

func (event *IncomingLeaveLobbyPacket) Process(client *Client) (interface{}, error) {
	if client.lobby == nil {
		return OutgoingLeaveLobbyPacket{}, errors.New("client not in a lobby")
	}

	client.lobby.RemovePlayer(client)

	client.manager.BroadcastToLobby(client.lobby.ID, "player_left", OutgoingLobbyPlayerLeftPacket{
		Player: client.DiscordUser,
	})

	client.lobby = nil

	return OutgoingLeaveLobbyPacket{}, nil
}

type OutgoingLobbyPlayerJoinedPacket struct {
	Player *discord_utils.User `json:"player"`
}

type OutgoingLobbyPlayerLeftPacket struct {
	Player *discord_utils.User `json:"player"`
}

type IncomingGetLobbyListPacket struct{}

type OutgoingGetLobbyListPacket struct {
	Lobbies map[int]struct {
		Owner       *discord_utils.User `json:"owner"`
		PlayerCount int                 `json:"player_count"`
	} `json:"lobbies"`
}

func (event *IncomingGetLobbyListPacket) Process(client *Client) (interface{}, error) {
	lobbies := make(map[int]struct {
		Owner       *discord_utils.User `json:"owner"`
		PlayerCount int                 `json:"player_count"`
	})

	for lobbyID, lobby := range client.manager.Lobbies {
		if lobby.IsStarted {
			continue
		}

		lobbies[lobbyID] = struct {
			Owner       *discord_utils.User `json:"owner"`
			PlayerCount int                 `json:"player_count"`
		}{
			Owner:       lobby.Clients[common.Snowflake(lobby.OwnerID)].DiscordUser,
			PlayerCount: len(lobby.Clients),
		}
	}

	return OutgoingGetLobbyListPacket{Lobbies: lobbies}, nil
}
