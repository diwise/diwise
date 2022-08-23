package example.authz

default allow := false

allow {
    is_valid_token

    input.method == "GET"
    pathstart := array.slice(input.path, 0, 3)
    pathstart == ["api", "v0", "devices"]
}

issuers := {"http://keycloak:8080/realms/diwise-local"}

# Connect to the specified issuer to query for openid metadata
metadata_discovery(issuer) := http.send({
    "url": concat("", [issuers[issuer], "/.well-known/openid-configuration"]),
    "method": "GET",
    "force_cache": true,
    "force_cache_duration_seconds": 86400 # Cache response for 24 hours
}).body

# Use the jwks_uri from the metadata returned above, to request a JWKS, to be
# able to verify the supplied token
jwks_request(url) := http.send({
    "url": url,
    "method": "GET",
    "force_cache": true,
    "force_cache_duration_seconds": 3600 # Cache response for an hour
})

is_valid_token {

    # We need to replace the public issuer URL that the pod can not access, with the
    # internal URL that this pod CAN access without messing around with host networking.
    # This is for local testing using docker compose.
    issuer := replace(token.payload.iss, "https://iam.diwise.local:8444/", "http://keycloak:8080/")

    openid_config := metadata_discovery(issuer)
    jwks := jwks_request(openid_config.jwks_uri).raw_body
	
    verified := io.jwt.verify_rs256(input.token, jwks)
    verified == true
}

token := {"payload": payload} {
    [header, payload, signature] := io.jwt.decode(input.token)
}