package modules

import (
	"server-go/common"
	"server-go/errors"
	"server-go/events"

	"github.com/diamondburned/arikawa/v3/discord"
	"github.com/gorilla/websocket"
	"golang.org/x/oauth2"
)

type Client struct {
	manager *GameManager

	lobby *Lobby

	conn *websocket.Conn

	DiscordUser *discord.User

	token *oauth2.Token

	// channel to send messages to the client
	send chan interface{}
}

func NewClient(manager *GameManager, conn *websocket.Conn, token *oauth2.Token, discordUser *discord.User) *Client {
	return &Client{
		manager:     manager,
		conn:        conn,
		send:        make(chan interface{}),
		token:       token,
		DiscordUser: discordUser,
	}
}

func (c *Client) SendPacket(packet interface{}) {
	c.send <- packet
}

func (c *Client) ReadPump() {
	defer func() {
		c.lobby.RemovePlayer(c)
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

		packet, err := events.ParsePacket(message)

		if err != nil {
			// faulty packet, drop connection
			return
		}

		res, err := events.ProcessPacket(packet)

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
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			c.conn.WriteJSON(message)
		}
	}
}
