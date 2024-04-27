package modules

import (
	"errors"
	"server-go/database"
	"server-go/modules/discord_utils"
	"time"

	"github.com/diamondburned/arikawa/v3/discord"
)

type EmptyPacket struct{}

type IncomingAuthPacket struct {
	Code        string `json:"code"`
	AccessToken string `json:"access_token"`
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

type OutgoingGameStartCountdownPacket struct {
	Countdown int `json:"countdown"`
}

func (event *IncomingJoinLobbyPacket) Process(client *Client) (interface{}, error) {
	if client.lobby != nil {
		return OutgoingJoinLobbyPacket{}, errors.New("client already in a lobby")
	}

	lobby := client.manager.Lobbies[event.LobbyID]
	if lobby == nil {
		return OutgoingJoinLobbyPacket{}, errors.New("lobby_not_found")
	}

	if len(lobby.Clients) >= lobby.MaxLobbySize {
		return OutgoingJoinLobbyPacket{}, errors.New("lobby_full")
	}

	lobby.AddPlayer(client)

	client.manager.BroadcastToLobby(client.lobby.ID, "player_joined", OutgoingLobbyPlayerLeftPacket{
		Player: client.DiscordUser,
	})

	client.manager.BroadcastToLobby(client.lobby.ID, "game_start_countdown_start", OutgoingGameStartCountdownPacket{
		Countdown: 3,
	})

	lobby.startCountdown = time.AfterFunc(3*time.Second, func() {
		client.manager.StartGame(lobby.ID)
	})

	return OutgoingJoinLobbyPacket{Players: lobby.GetPlayers(), LobbyOwnerID: lobby.OwnerID}, nil
}

type IncomingLeaveLobbyPacket struct{}

type OutgoingLeaveLobbyPacket struct{}

func (event *IncomingLeaveLobbyPacket) Process(client *Client) (interface{}, error) {
	if client.lobby == nil {
		return OutgoingLeaveLobbyPacket{}, errors.New("client_not_in_lobby")
	}

	lobby := client.lobby

	client.manager.RemoveClientFromLobby(lobby.ID, client)

	// lets be sure lobby isnt closed
	if lobby != nil {
		client.manager.BroadcastToLobby(lobby.ID, "player_left", OutgoingLobbyPlayerLeftPacket{
			Player: client.DiscordUser,
		})

		if lobby.startCountdown != nil {
			lobby.startCountdown.Stop()

			client.manager.BroadcastToLobby(lobby.ID, "game_start_countdown_cancel", EmptyPacket{})
		}
	}

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
	Lobbies map[int]LobbyEntry `json:"lobbies"`
}

type LobbyEntry struct {
	OwnerID     discord.UserID        `json:"owner_id"`
	Players     []*discord_utils.User `json:"players"`
	PlayerCount int                   `json:"player_count"`
}

func (event *IncomingGetLobbyListPacket) Process(client *Client) (interface{}, error) {
	// should maybe just use lobby object here instead of redeclaring the struct

	lobbies := make(map[int]LobbyEntry)

	for lobbyID, lobby := range client.manager.Lobbies {
		if lobby.IsStarted {
			continue
		}

		lobbies[lobbyID] = LobbyEntry{
			OwnerID:     lobby.OwnerID,
			Players:     lobby.GetPlayers(),
			PlayerCount: len(lobby.Clients),
		}
	}

	return OutgoingGetLobbyListPacket{Lobbies: lobbies}, nil
}

type OutgoingStartGamePacket struct {
	Categories []database.Category `json:"categories"`
}
