package protocol

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
)

const (
	HeaderIdentifier = "header"
)

type Message struct {
	Content interface{}
	Type    int
}

func EnPacket(m *Message) []byte {
	json, err := json.Marshal(m)

	if err != nil {
		fmt.Println("json marshal error", err)
		return nil
	}
	fmt.Println("json is ", string(json))
	fmt.Println("json length", len(json))
	return append(append([]byte(HeaderIdentifier), IntToBytes(len(json))...), json...)
}

func IntToBytes(n int) []byte {
	x := int64(n)
	fmt.Println("x is", x)
	bytesBuffer := bytes.NewBuffer([]byte{})
	binary.Write(bytesBuffer, binary.BigEndian, x)
	fmt.Println("IntToBytes", bytesBuffer)
	return bytesBuffer.Bytes()
}
