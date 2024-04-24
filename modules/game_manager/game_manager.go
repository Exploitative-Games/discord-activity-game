package modules

import (
	"math/rand/v2"
	"server-go/common"
	"sync"
)

type GameManager struct {
	Lobbies map[int]*Lobby
	Clients map[common.Snowflake]*Client

	sync.RWMutex
}

func NewGameManager() *GameManager {
	return &GameManager{
		Lobbies: make(map[int]*Lobby),
		Clients: make(map[common.Snowflake]*Client),
	}
}

func (gm *GameManager) AddClient(client *Client) {
	gm.Lock()
	defer gm.Unlock()

	gm.Clients[common.Snowflake(client.DiscordUser.ID)] = client
}

func (gm *GameManager) RemoveClient(client *Client) {
	gm.Lock()
	defer gm.Unlock()

	delete(gm.Clients, common.Snowflake(client.DiscordUser.ID))
}

func (gm *GameManager) CreateLobby() (int, *Lobby) {
	lobby := Lobby{Clients: make(map[common.Snowflake]*Client)}

	// synchorize this operation so stupid stuff dont happen
	gm.Lock()
	defer gm.Unlock()

	lobbyID := rand.Int()

	// make sure we dont have a lobby with the same id
	for gm.Lobbies[lobbyID] != nil {
		lobbyID = rand.Int()
	}

	gm.Lobbies[lobbyID] = &lobby

	return lobbyID, &lobby
}

func (gm *GameManager) DeleteLobby(id int) {
	gm.Lock()
	defer gm.Unlock()

	delete(gm.Lobbies, id)
}

func (gm *GameManager) AddClientToLobby(lobbyID int, client *Client) {
	gm.Lock()
	defer gm.Unlock()

	lobby := gm.Lobbies[lobbyID]

	lobby.Clients[common.Snowflake(client.DiscordUser.ID)] = client
	client.lobby = lobby
}

func (gm *GameManager) RemoveClientFromLobby(lobbyID int, client *Client) {
	gm.Lock()
	defer gm.Unlock()

	lobby := gm.Lobbies[lobbyID]

	delete(lobby.Clients, common.Snowflake(client.DiscordUser.ID))
}
