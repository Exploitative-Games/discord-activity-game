package events

import (
	"encoding/json"
	"reflect"
	"server-go/errors"
)

type Packet struct {
	Op    string          `json:"op"`
	Data  json.RawMessage `json:"d"`
	Error string          `json:"e,omitempty"`
}

var typeMap = map[string]reflect.Type{
	"auth": reflect.TypeOf(IncomingAuthPacket{}),
}

type Processor interface {
	Process() (interface{}, error)
}

func ParsePacket(i []byte) (packet Packet, err error) {
	err = json.Unmarshal(i, &packet)
	return packet, err
}

func ProcessPacket(inPacket Packet) (outPacket Packet, err error) {
	outPacket = Packet{Op: inPacket.Op}

	var response interface{}

	if t, ok := typeMap[inPacket.Op]; ok {
		v := reflect.New(t).Interface()
		if err = json.Unmarshal(inPacket.Data, &v); err != nil {
			err = errors.ErrInternalServer
			return
		}

		if processor, ok := v.(Processor); ok {
			response, err = processor.Process()
		} else {
			err = errors.ErrInternalServer
		}
	}

	outPacket.Data, _ = json.Marshal(response)
	return
}
