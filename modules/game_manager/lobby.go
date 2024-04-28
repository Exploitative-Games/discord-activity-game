package modules

import (
	"server-go/common"
	"server-go/database"
	"server-go/modules/discord_utils"
	"time"

	"github.com/diamondburned/arikawa/v3/discord"
)

const (
	LOBBY_STATE_WAITING = iota
	LOBBY_STATE_CATEGORY_SELECTION
	LOBBY_STATE_QUIZ_IN_PROGRESS
)

type LobbyState int

type Lobby struct {
	ID           int
	Clients      map[common.Snowflake]*Client
	OwnerID      discord.UserID
	IsStarted    bool
	MaxLobbySize int

	state LobbyState

	selectedCategories []int32
	question           *database.Question
	currentPlayerTurn  discord.UserID

	startCountdown             *time.Timer
	categorySelectionCountdown *time.Timer
	quizCountdown              *time.Timer
}

func (l *Lobby) AddPlayer(client *Client) {
	l.Clients[common.Snowflake(client.DiscordUser.ID)] = client
	client.lobby = l
}

func (l *Lobby) RemovePlayer(client *Client) {
	delete(l.Clients, common.Snowflake(client.DiscordUser.ID))
	client.lobby = nil
}

func (l *Lobby) IsOwner(client *Client) bool {
	return client.DiscordUser.ID == l.OwnerID
}

func (l *Lobby) GetPlayers() []*discord_utils.User {
	players := make([]*discord_utils.User, 0, len(l.Clients))

	for _, client := range l.Clients {
		players = append(players, client.DiscordUser)
	}

	return players
}

func (l *Lobby) GetNextPlayer(userID discord.UserID) discord.UserID {
	for _, client := range l.Clients {
		if client.DiscordUser.ID != userID {
			return client.DiscordUser.ID
		}
	}

	return 0
}
