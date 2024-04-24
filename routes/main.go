package routes

import (
	"fmt"
	"net/http"
	"server-go/common"
	"server-go/modules/discord"

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
	fmt.Println("Websocket connection established")

	// I should make it only accept connections from the same origin but for now its fine
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	// upgrade http con to websocket
	ws, err := upgrader.Upgrade(w, r, nil)

	if err != nil {
		println("an error occured while creating websocket" + err.Error())
		return
	}

	token, err := Authorize(ws)

	if err != nil {
		println("error while authorizing")
		ws.Close()
		return
	}

	discordUser, err := discord.GetDiscordUser(token.AccessToken)

	if err != nil {
		println("error while fetching user")
		ws.Close()
		return
	}
	// finally after all checks

	client := manager_module.NewClient(manager, ws, token, discordUser)
	manager.AddClient(client)

	go client.ReadPump()
	go client.WritePump()

	client.SendPacket(manager_module.OutgoingAuthPacket{AccessToken: token.AccessToken, User: discordUser})
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
		println("unauthorized connection")
		return
	}

	authPacket := manager_module.IncomingAuthPacket{}
	err = common.GetDataFromPacket(packet, &authPacket)

	if err != nil {
		println("faulty packet")
		return
	}

	token, err = discord.ExchangeCode(authPacket.Code, common.Config.RedirectUri)

	if err != nil {
		println("error while exchanging code")
		return
	}

	return
}