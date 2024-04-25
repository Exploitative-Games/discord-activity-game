package modules

import (
	"server-go/common"
	"server-go/errors"

	"server-go/modules/discord_utils"

	"github.com/gorilla/websocket"
	"golang.org/x/oauth2"
)

type Client struct {
	manager     *GameManager
	lobby       *Lobby
	conn        *websocket.Conn
	DiscordUser *discord_utils.User
	token       *oauth2.Token
	// channel to send messages to the client
	send chan interface{}
}

func NewClient(manager *GameManager, conn *websocket.Conn, token *oauth2.Token, discordUser *discord_utils.User) *Client {
	return &Client{
		manager:     manager,
		conn:        conn,
		send:        make(chan interface{}),
		token:       token,
		DiscordUser: discordUser,
	}
}

func (c *Client) SendPacket(packet common.Packet) {
	c.send <- packet
}

func (c *Client) ReadPump() {
	defer func() {
		c.manager.RemoveClientFromLobby(c.lobby.ID, c)
		c.send <- common.Packet{Op: "disconnect", Data: nil}
		c.conn.Close()
	}()

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				println("dropped connection")
			}

			println(err)
			break
		}

		packet, err := common.ParsePacket(message)

		if err != nil {
			// faulty packet, drop connection
			return
		}

		res, err := ProcessPacket(c, packet)

		if err != nil {
			res.Error = errors.ErrInternalServer.Error()
			// lets not send faulty data if we have an error
			res.Data = nil
			println(err.Error()) // for debugging purposes, should switch to slog later
		}

		c.send <- res
	}
}

func (c *Client) WritePump() {
	for {
		select {
		case message, ok := <-c.send:
			if !ok {
				print("non ok status, websocket closed")
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			c.conn.WriteJSON(message)
		}
	}
}
