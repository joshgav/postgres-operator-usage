oc port-forward deployment/fromcrd 5432 &
forwarder_pid=$!
u=postgres
p=$(oc get secret fromcrd-postgres-secret -o jsonpath="{.data['password']}" | base64 -d)
PGPASSWORD=${p} psql --port=5432 --host=127.0.0.1 --username=${u} --dbname userdb

echo "forwader_pid is ${forwarder_pid}, \`kill ${forwarder_pid}\` to kill"
