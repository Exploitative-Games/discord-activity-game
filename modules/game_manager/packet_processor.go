package modules

import (
	"encoding/json"
	"reflect"
	"server-go/common"
	"server-go/errors"
	"server-go/events"
)

type Processor interface {
	Process(client *Client) (interface{}, error)
}

var typeMap = map[string]reflect.Type{
	"auth": reflect.TypeOf(events.IncomingAuthPacket{}),
}

func ProcessPacket(client *Client, inPacket common.Packet) (outPacket common.Packet, err error) {
	outPacket = common.Packet{Op: inPacket.Op}

	var response interface{}

	if t, ok := typeMap[inPacket.Op]; ok {
		v := reflect.New(t).Interface()
		if err = json.Unmarshal(inPacket.Data, &v); err != nil {
			err = errors.ErrInternalServer
			return
		}

		if processor, ok := v.(Processor); ok {
			response, err = processor.Process(client)
		} else {
			err = errors.ErrInternalServer
		}
	}

	outPacket.Data, _ = json.Marshal(response)
	return
}
