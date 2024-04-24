package modules

import (
	"server-go/common"

	"github.com/diamondburned/arikawa/v3/discord"
)

type Lobby struct {
	ID        int
	Clients   map[common.Snowflake]*Client
	OwnerID   discord.UserID
	IsStarted bool
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

func (l *Lobby) GetPlayers() []*discord.User {
	players := make([]*discord.User, 0, len(l.Clients))

	for _, client := range l.Clients {
		players = append(players, client.DiscordUser)
	}

	return players
}
