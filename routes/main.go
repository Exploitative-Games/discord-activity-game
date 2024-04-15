package routes

import (
	"encoding/json"
	"net/http"
	"server-go/common"
	"server-go/modules"
)

var Auth = func(w http.ResponseWriter, r *http.Request) (str string, err error) {
	discordToken, err := modules.ExchangeCode(r.URL.Query().Get("code"), common.Config.RedirectUri)
	json.NewEncoder(w).Encode(map[string]string{"Access-Token": discordToken.AccessToken})
	if err != nil {
		return "", err
	}

	return discordToken.AccessToken, nil
}
