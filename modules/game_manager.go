package modules

import (
	"server-go/common"
)

type GameManager struct {
	Lobbies     map[int]Lobby
	LastLobbyID int
}

type Lobby struct {
	Players map[string]Player
}

type Player struct {
	DiscordID common.Snowflake
	Username  string
	AvatarURL string
}

func (gm *GameManager) CreateLobby() {
	lobby := Lobby{Players: make(map[string]Player)}
	gm.Lobbies[gm.LastLobbyID] = lobby
	gm.LastLobbyID++
}
