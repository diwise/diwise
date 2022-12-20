#
# Use https://play.openpolicyagent.org for easier editing/validation of this policy file
#

package example.authz

default allow := false

allow = response {
    not input.method == "DELETE"

    response := {
        "ok": true
    }
}
