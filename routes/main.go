package routes

import (
	"encoding/json"
	"fmt"
	"net/http"
	"server-go/common"
	"server-go/modules"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

func Auth(w http.ResponseWriter, r *http.Request) (str string, err error) {
	discordToken, err := modules.ExchangeCode(r.URL.Query().Get("code"), common.Config.RedirectUri)
	json.NewEncoder(w).Encode(map[string]string{"access_token": discordToken.AccessToken})
	if err != nil {
		return "", err
	}

	return discordToken.AccessToken, nil
}

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

	defer ws.Close()

	for {
		// ReadMessage function is blocking so we wait for new message in endless loop
		_, _, err := ws.ReadMessage()
		if err != nil {
			println(err)
			return
		}

		// this ones obvious
		ws.WriteMessage(websocket.TextMessage, []byte("pong"))
	}
}
