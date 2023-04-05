package example.authz

# See https://www.openpolicyagent.org/docs/latest/policy-reference/ to learn more about rego

default allow := false

allow = response {
	is_valid_token

	input.method == "GET"
	pathstart := array.slice(input.path, 0, 2)
	pathstart == ["api", "v0"]

	response := {"tenants": token.payload.tenants}
}

allow = response {
	is_valid_token

	input.method == "PATCH"
	pathstart := array.slice(input.path, 0, 3)
	pathstart == ["api", "v0", "alarms"]

	response := {"tenants": token.payload.tenants}
}


issuers := {"http://keycloak:8080/realms/diwise-local"}

# Connect to the specified issuer to query for openid metadata
metadata_discovery(issuer) := http.send({
	"url": concat("", [issuers[issuer], "/.well-known/openid-configuration"]),
	"method": "GET",
	"force_cache": true,
	"force_cache_duration_seconds": 86400,
}).body

# Cache response for 24 hours

# Use the jwks_uri from the metadata returned above, to request a JWKS, to be
# able to verify the supplied token
jwks_request(url) := http.send({
	"url": url,
	"method": "GET",
	"force_cache": true,
	"force_cache_duration_seconds": 3600, # Cache response for an hour
})

is_valid_token {
	# We need to replace the public issuer URL, that the pod can not access, with the
	# internal URL that this pod CAN access without messing around with host networking.
	# This is for local testing using docker compose.

	issuer := replace(token.payload.iss, "iam.diwise.local:8444", "keycloak:8080")
	http_issuer := replace(issuer, "https", "http")

	openid_config := metadata_discovery(http_issuer)
	jwks := jwks_request(openid_config.jwks_uri).raw_body

	verified := io.jwt.verify_rs256(input.token, jwks)
	verified == true
}

token := {"payload": payload} {
	[_, payload, _] := io.jwt.decode(input.token)
}
