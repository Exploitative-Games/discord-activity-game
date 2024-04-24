package events

import (
	"encoding/json"
	"reflect"
	"server-go/common"
	errors "server-go/errors"
)

var typeMap = map[string]reflect.Type{
	"auth": reflect.TypeOf(IncomingAuthPacket{}),
}

func ParsePacket(i []byte) (packet common.Packet, err error) {
	err = json.Unmarshal(i, &packet)
	return packet, err
}

func GetDataFromPacket(inPacket common.Packet, v interface{}) (err error) {
	if err = json.Unmarshal(inPacket.Data, v); err != nil {
		err = errors.ErrInternalServer
	}
	return
}

func ProcessPacket(inPacket common.Packet) (outPacket common.Packet, err error) {
	outPacket = common.Packet{Op: inPacket.Op}

	var response interface{}

	if t, ok := typeMap[inPacket.Op]; ok {
		v := reflect.New(t).Interface()
		if err = json.Unmarshal(inPacket.Data, &v); err != nil {
			err = errors.ErrInternalServer
			return
		}

		if processor, ok := v.(common.Processor); ok {
			response, err = processor.Process()
		} else {
			err = errors.ErrInternalServer
		}
	}

	outPacket.Data, _ = json.Marshal(response)
	return
}
