package routes

import (
	"encoding/json"
	"fmt"
	"net/http"
	"server-go/common"
	"server-go/modules/discord_utils"

	manager_module "server-go/modules/game_manager"

	"github.com/gorilla/websocket"
	"golang.org/x/oauth2"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

var manager = manager_module.NewGameManager()

func WS(w http.ResponseWriter, r *http.Request) {
	fmt.Println("Websocket connection received")

	// I should make it only accept connections from the same origin but for now its fine
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	// upgrade http con to websocket
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		println("an error occured while creating websocket" + err.Error())
		return
	}

	fmt.Println("Websocket connection estabilished")

	token, err := Authorize(ws)

	if err != nil {
		println("error while authorizing")
		ws.Close()
		return
	}

	fmt.Println("Authorization successful")


	discordUser, err := discord_utils.GetDiscordUser(token.AccessToken)

	if err != nil {
		println("error while fetching user")
		ws.Close()
		return
	}

	if manager.Clients[common.Snowflake(discordUser.ID)] != nil {
		// this code probably wont get called but better to check just in case
		println("client already connected, disconnecting old client")
		oldClient := manager.Clients[common.Snowflake(discordUser.ID)]
		oldClient.Disconnect()
	}

	// finally after all checks

	client := manager_module.NewClient(manager, ws, token, discordUser)
	manager.AddClient(client)

	go client.ReadPump()
	go client.WritePump()

	authPacket, _ := json.Marshal(manager_module.OutgoingAuthPacket{AccessToken: token.AccessToken, User: discordUser})
	client.SendPacket(common.Packet{Op: "auth", Data: authPacket})
}

func Authorize(ws *websocket.Conn) (token *oauth2.Token, err error) {
	_, message, err := ws.ReadMessage()

	if err != nil {
		println("error while reading message")
		return
	}

	packet, err := common.ParsePacket(message)

	if err != nil {
		println("error while parsing packet")
		return
	}

	if packet.Op != "auth" {
		err = fmt.Errorf("unauthorized connection")
		println("unauthorized connection")
		return
	}

	authPacket := manager_module.IncomingAuthPacket{}
	err = common.GetDataFromPacket(packet, &authPacket)

	if err != nil {
		println("faulty packet")
		return
	}

	if authPacket.AccessToken != "" {
		// TODO for debugging purposes remove on production
		token = &oauth2.Token{AccessToken: authPacket.AccessToken}
		return
	}

	token, err = discord_utils.ExchangeCode(authPacket.Code, common.Config.RedirectUri)

	if err != nil {
		println("error while exchanging code")
		return
	}

	return
}
