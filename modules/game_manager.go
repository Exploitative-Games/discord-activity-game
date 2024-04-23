package modules

import (
	"math/rand/v2"
	"server-go/common"
	"sync"

	"github.com/gorilla/websocket"
)

type Client struct {
	lobby *Lobby

	conn websocket.Conn

	DiscordID common.Snowflake
	Username  string
	AvatarURL string

	// channel to send messages to the client
	send chan interface{}
}

type GameManager struct {
	Lobbies map[int]*Lobby
	Clients map[string]*Client

	sync.RWMutex
}

type Lobby struct {
	OwnerID string
	Players map[common.Snowflake]*Client
}

type Player struct {
	DiscordID common.Snowflake
	Username  string
	AvatarURL string
}

func (gm *GameManager) CreateLobby() int {
	lobby := Lobby{Players: make(map[common.Snowflake]*Client)}

	// synchorize this operation so stupid stuff dont happen
	gm.Lock()
	defer gm.Unlock()

	lobbyID := rand.Int()

	// make sure we dont have a lobby with the same id
	for gm.Lobbies[lobbyID] != nil {
		lobbyID = rand.Int()
	}

	gm.Lobbies[lobbyID] = &lobby

	return lobbyID
}

func (gm *GameManager) DeleteLobby(id int) {
	gm.Lock()
	defer gm.Unlock()

	delete(gm.Lobbies, id)
}

func (gm *GameManager) AddPlayerToLobby(lobbyID int, client *Client) {
	gm.Lock()
	defer gm.Unlock()

	lobby := gm.Lobbies[lobbyID]

	lobby.Players[client.DiscordID] = client
	client.lobby = lobby
}

func (gm *GameManager) RemovePlayerFromLobby(lobbyID int, client *Client) {
	gm.Lock()
	defer gm.Unlock()

	lobby := gm.Lobbies[lobbyID]

	delete(lobby.Players, client.DiscordID)
}

