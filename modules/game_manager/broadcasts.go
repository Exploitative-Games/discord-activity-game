package modules

import (
	"encoding/json"
	"server-go/common"
)

func (gm *GameManager) BroadcastToLobby(lobbyID int, op string, data interface{}) {

	lobby := gm.Lobbies[lobbyID]

	if lobby == nil {
		return
	}

	for _, client := range lobby.Clients {
		packet := &common.Packet{
			Op:   op,
		}

		jsonData, _ := json.Marshal(data)
		packet.Data = jsonData
		
		client.conn.WriteJSON(packet)
	}
}
