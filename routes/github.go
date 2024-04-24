package routes

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http"
	"os/exec"
	"server-go/common"
)

// ValidateSignature validates the GitHub webhook signature
func ValidateSignature(body []byte, signatureHeader string) bool {
	if signatureHeader == "" || len(signatureHeader) < 7 {
		return false
	}

	computedHash := hmac.New(sha256.New, []byte(common.Config.GithubWebhookSecret))
	computedHash.Write(body)
	expectedSig := hex.EncodeToString(computedHash.Sum(nil))

	return hmac.Equal([]byte(expectedSig), []byte(signatureHeader[7:]))
}

// stole it https://github.com/krzko/github-webhook-validator/blob/main/main.go
func WebhookHandler(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}
	
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	signatureHeader := r.Header.Get("X-Hub-Signature-256")
	if ValidateSignature(body, signatureHeader) {
		exec.Command("systemctl", "--user", "restart", "dcgame").Run()
		println("Restarting server")

		w.Write([]byte("Payload Validated\n"))
	} else {
		http.Error(w, "Unauthorized - Signature Mismatch", http.StatusUnauthorized)
	}
}
