package blockchain

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
)

type rpcRequest struct {
	JSONRPC string `json:"jsonrpc"`
	ID      int    `json:"id"`
	Method  string `json:"method"`
	Params  []any  `json:"params"`
}

type rpcResponse struct {
	Result json.RawMessage `json:"result"`
	Error  *struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
}

const (
	rpcURL      string = "http://127.0.0.1:18443/"
	// i know what you're thinking, but this is just a demo.
	rpcPassword string = "man"// TODO: use env var
	rpcUser     string = "bitcoinrpc"// TODO: use env var
)

func RPC(method string, params []any, wallet string, out any) error {
	endpoint := rpcURL

	if wallet != "" {
		endpoint += "wallet/" + url.PathEscape(wallet)
	}

	reqBody := rpcRequest{
		JSONRPC: "1.0",
		ID:      1,
		Method:  method,
		Params:  params,
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		return fmt.Errorf("marshal request: %w", err)
	}

	req, err := http.NewRequest(
		http.MethodPost,
		endpoint,
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.SetBasicAuth(rpcUser, rpcPassword)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("send request: %w", err)
	}
	defer resp.Body.Close()
	/**/
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status: %s", resp.Status)
	} //**/

	var rpcResp rpcResponse
	if err := json.NewDecoder(resp.Body).Decode(&rpcResp); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}

	if rpcResp.Error != nil {
		return fmt.Errorf(
			"rpc error %d: %s",
			rpcResp.Error.Code,
			rpcResp.Error.Message,
		)
	}

	if out == nil {
		return nil
	}

	if err := json.Unmarshal(rpcResp.Result, out); err != nil {
		return fmt.Errorf("decode result: %w", err)
	}

	return nil
}
