package modules

import (
	"server-go/common"
)

func (gm *GameManager) BroadcastToLobby(lobbyID int, packet *common.Packet) {
	gm.Lock()
	defer gm.Unlock()

	lobby := gm.Lobbies[lobbyID]
	
	if lobby == nil {
		return
	}

	for _, player := range lobby.Players {
		player.conn.WriteJSON(packet)
	}
}
