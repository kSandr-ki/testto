# vendor-postgres

Install Postgres from community YUM repos.

## Role Variables

`pg_version` - desired Postgres version *as a string*. Make sure to quote it, so that YAML doesn't cast it to float, especially on versions like 10.0.

## Example Playbook

    - hosts: postgres-servers
      roles:
         - role: vendor-postgres
           pg_version: "10.0"

# License

GPL3+

# Author Information

Copyright 2017, Development Gateway.
