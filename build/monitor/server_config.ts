import server_config_json from "./server_config.json"

const packageUrl = server_config_json.network === "mainnet" ? `teku.my.ava.do` : `teku-${server_config_json.network}.my.ava.do`

export const server_config = {
    ...server_config_json,
    keymanager_token_path: `/usr/share/nginx/wizard/auth-token.txt`,
    keymanager_url: `http://localhost:7500`

}