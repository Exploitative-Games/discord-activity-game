package routes

import (
	"fmt"
	"net/http"
	errors "server-go/errors"
	"server-go/events"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
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

	authorized := false
	
	for {
		// TODO make this code more organized and readable
		// ReadMessage function is blocking so we wait for new message in endless loop
		msgType, message, err := ws.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				println("dropped connection")
				return
			}

			println(err)
			return
		}

		if msgType == websocket.CloseMessage {
			// if we get close message we close the connection
			return
		}

		packet, err := events.ParsePacket(message)

		if err != nil {
			// faulty packet, drop connection
			return
		}

		if !authorized && packet.Op != "auth" {
			// prevent non auth packets from being processed and drop connection if not authorized
			return
		}

		if packet.Op == "auth" && authorized {
			// prevent multiple auth packets
			return
		}

		res, err := events.ProcessPacket(packet)

		if err != nil {
			if errors.Is(err, errors.ErrInvalidCode) {
				// if we fail authorization drop connection
				return
			} else {
				res.Error = errors.ErrInternalServer.Error()
				// lets not send faulty data if we have an error
				res.Data = nil
			}

			println(err.Error()) // for debugging purposes, should switch to slog later
		}

		if packet.Op == "auth" {
			authorized = true
		}

		// we send the response back to the client
		ws.WriteJSON(res)
	}
}
