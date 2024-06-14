package example.authz

# See https://www.openpolicyagent.org/docs/latest/policy-reference/ to learn more about rego

default allow := false

allow = response {
	response := {
		"tenants": ["default"]
	}
}
