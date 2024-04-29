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

	if lobby == nil {
		return
	}

	delete(lobby.Clients, common.Snowflake(client.DiscordUser.ID))

	if len(lobby.Clients) == 0 {
		gm.deleteLobby(lobbyID)
		return
	}

	lobby.state = LOBBY_STATE_WAITING

	// lets be sure lobby isnt closed
	client.manager.BroadcastToLobby(lobby.ID, "player_left", OutgoingLobbyPlayerLeftPacket{
		Player: client.DiscordUser,
	})

	if lobby.startCountdown != nil {
		lobby.startCountdown.Stop()

		client.manager.BroadcastToLobby(lobby.ID, "game_start_countdown_cancel", EmptyPacket{})
	}

	if lobby.categorySelectionCountdown != nil {
		lobby.categorySelectionCountdown.Stop()
	}

	if lobby.quizCountdown != nil {
		lobby.quizCountdown.Stop()
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

		num := rand.IntN(1)

		for _, client := range lobby.Clients {
			if num == 1 {
				lobby.currentPlayerTurn = client.DiscordUser.ID
			}
			num++

			if client.votedCategory != 0 {
				categorySelections[client.votedCategory]++
			}
		}

		var maxCategoryID int

		if len(categorySelections) == 0 {
			maxCategoryID = int(lobby.selectedCategories[rand.IntN(len(lobby.selectedCategories)-1)])
		} else {
			for categoryID, count := range categorySelections {
				if count > categorySelections[maxCategoryID] {
					maxCategoryID = categoryID
				}
			}
		}

		cat, err := questionmanager.GetCategoryWithID(maxCategoryID)
		if err != nil {
			// TODO properly handle this
			fmt.Println("An error occured while getting category with id ", maxCategoryID, err)
			return
		}

		question, err := questionmanager.GetRandomQuestionWithCategoryID(int(cat.ID))

		if err != nil {
			// TODO properly handle this
			fmt.Println("An error occured while getting random question with category id ", cat.ID, err)
			return
		}

		lobby.question = &question

		gm.BroadcastToLobby(lobbyID, "game_quiz_start", OutgoingCategorySelectionPacket{
			SelectedCategory: cat.Name,
			Question:         question.Question,
			CurrentPlayer:    lobby.currentPlayerTurn,
			QuestionCooldown: common.Config.AnswerTimeout,
		})

		lobby.quizCountdown = time.AfterFunc(time.Duration(common.Config.AnswerTimeout)*time.Second, func() {
			lobby.currentPlayerTurn = lobby.GetNextPlayer(lobby.currentPlayerTurn)

			gm.BroadcastToLobby(lobby.ID, "turn_change", OutgoingTurnChangePacket{
				CurrentPlayer: lobby.currentPlayerTurn,
			})
		})

	})

	gm.BroadcastToLobby(lobbyID, "game_start", OutgoingStartGamePacket{
		Countdown:  5,
		Categories: categories,
	})
}
