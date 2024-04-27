package modules

import (
	"fmt"
	"math/rand/v2"
	"server-go/common"
	questionmanager "server-go/modules/question_manager"
	"sync"
	"time"
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
	if client.lobby != nil {
		gm.RemoveClientFromLobby(client.lobby.ID, client)
	}

	gm.Lock()
	defer gm.Unlock()

	delete(gm.Clients, common.Snowflake(client.DiscordUser.ID))
}

func (gm *GameManager) CreateLobby() (int, *Lobby) {
	lobby := Lobby{Clients: make(map[common.Snowflake]*Client), MaxLobbySize: 2, state: LOBBY_STATE_WAITING}

	// synchorize this operation so stupid stuff dont happen
	gm.Lock()
	defer gm.Unlock()

	lobbyID := rand.Int()

	lobby.ID = lobbyID

	// make sure we dont have a lobby with the same id
	for gm.Lobbies[lobbyID] != nil {
		lobbyID = rand.Int()
	}

	gm.Lobbies[lobbyID] = &lobby

	return lobbyID, &lobby
}

func (gm *GameManager) deleteLobby(id int) {
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

	if len(lobby.Clients) == 0 {
		gm.deleteLobby(lobbyID)
	}
}

func (gm *GameManager) StartGame(lobbyID int) {
	gm.Lock()
	defer gm.Unlock()

	lobby := gm.Lobbies[lobbyID]

	if lobby == nil {
		return
	}

	categories, err := questionmanager.GetRandomCategories(3)

	if err != nil {
		fmt.Println("An error occured while getting random categories ", err)
		return
	}

	lobby.selectedCategories = []int32{}

	for _, category := range categories {
		lobby.selectedCategories = append(lobby.selectedCategories, category.ID)
	}

	lobby.state = LOBBY_STATE_CATEGORY_SELECTION

	lobby.categorySelectionCountdown = time.AfterFunc(5*time.Second, func() {
		lobby.state = LOBBY_STATE_QUIZ_IN_PROGRESS

		categorySelections := make(map[int]int)

		for _, client := range lobby.Clients {
			categorySelections[client.votedCategory]++
		}

		var maxCategoryID int

		for categoryID, count := range categorySelections {
			if count > categorySelections[maxCategoryID] {
				maxCategoryID = categoryID
			}
		}

		cat, err := questionmanager.GetCategoryWithID(maxCategoryID)
		if err != nil {
			// TODO properly handle this
			fmt.Println("An error occured while getting category with id ", maxCategoryID, err)
			return
		}

		gm.BroadcastToLobby(lobbyID, "game_category_selected", OutgoingCategorySelectionPacket{
			SelectedCategory: cat.Name,
		})

		// TODO asking questions

	})

	gm.BroadcastToLobby(lobbyID, "game_start", OutgoingStartGamePacket{
		Countdown: 5,
		Categories: categories,
	})
}
