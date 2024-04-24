package common

import (
	"encoding/json"
	"server-go/errors"
)

func ParsePacket(i []byte) (packet Packet, err error) {
	err = json.Unmarshal(i, &packet)
	return packet, err
}

func GetDataFromPacket(inPacket Packet, v interface{}) (err error) {
	if err = json.Unmarshal(inPacket.Data, v); err != nil {
		err = errors.ErrInternalServer
	}
	return
}
