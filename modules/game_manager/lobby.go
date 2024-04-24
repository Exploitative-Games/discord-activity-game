package modules

import (
	"server-go/common"
)

type Lobby struct {
	OwnerID string
	Clients map[common.Snowflake]*Client
}

func (l *Lobby) AddPlayer(client *Client) {
	l.Clients[common.Snowflake(client.DiscordUser.ID)] = client
}

func (l *Lobby) RemovePlayer(client *Client) {
	delete(l.Clients, common.Snowflake(client.DiscordUser.ID))
}
