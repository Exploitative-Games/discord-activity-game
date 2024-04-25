package discord_utils

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"server-go/common"

	"github.com/diamondburned/arikawa/v3/discord"
	"golang.org/x/oauth2"
)

type User struct {
	ID            discord.UserID `json:"id"`
	Username      string         `json:"username"`
	Discriminator string         `json:"discriminator"` // This is "0" if the user has migrated to the new username system.
	Avatar        discord.Hash   `json:"avatar"`
	DisplayName   string         `json:"global_name"`
}

func GetDiscordUser(token string) (user *User, err error) {
	req, _ := http.NewRequest(http.MethodGet, common.Config.ApiEndpoint+"/users/@me", nil)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := http.DefaultClient.Do(req)

	if resp != nil && resp.StatusCode != http.StatusOK {
		println("Error while fetching user, status code %s", resp.StatusCode)
		return nil, errors.New("an error occured")
	}

	if err == nil && resp.StatusCode == http.StatusOK {
		json.NewDecoder(resp.Body).Decode(&user)
		resp.Body.Close()
		return user, nil
	}
	return nil, err
}

func ExchangeCode(code, redirectUri string) (*oauth2.Token, error) {

	conf := &oauth2.Config{
		Endpoint: oauth2.Endpoint{
			AuthURL:   common.Config.ApiEndpoint + "/oauth2/authorize",
			TokenURL:  common.Config.ApiEndpoint + "/oauth2/token",
			AuthStyle: oauth2.AuthStyleInParams,
		},
		Scopes:       []string{"identify", "guilds"},
		RedirectURL:  redirectUri,
		ClientID:     common.Config.ClientId,
		ClientSecret: common.Config.ClientSecret,
	}

	token, err := conf.Exchange(context.Background(), code)

	if err != nil {
		fmt.Println(err)
		return nil, errors.New("an error occurred while exchanging code")
	} else {
		return token, nil
	}
}
