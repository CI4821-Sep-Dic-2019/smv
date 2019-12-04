# Sistema Manejador de Versiones (Distribuido)
Para la materia _Sistemas de Operación II (CI4821)_ de la Universidad Simón Bolívar, Venezuela.

## Cómo levantar el sistema
___
_Nótese que varios modulos del sistema dependen de variables de entorno. Si decide setearlas con `export` no tendría que setearlas cada vez que se ejecute un comando._

_Una variable de entorno que no aparece en los siguientes ejemplos pero que está disponible es `TOL`, la cual especifica el número de fallas que debe soportar el sistema. De no setearse se asume una 2-tolerancia a fallas._
___

A continuación algunos ejemplos para poder correr los distintos nodos.
### DNS
#### Local
```bash
iex --sname dns -S mix
```
#### Distribuido
```bash
iex --name dns@ec2-666-666-666.amanaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix
```

### Servidor de Almacenamiento (y potencial Servidor Central)
#### Local
```bash
DNS=dns@gus-Canaima-novich-420 iex --sname foo -S mix run -e "Server.init()"
```
o
```bash
export DNS=dns@gus-Canaima-novich-420 
iex --sname foo -S mix run -e "Server.init()"
```

Si la variable de entorno `DNS` no es seteada, se asumirá `dns@ec2-54-226-208-169.compute-1.amazonaws.com` como el DNS por defecto.

#### Distribuido
```bash
DNS=dns@ec2-666-666-666.amanaws.co iex --name s1@ec2-69-69-69.compute-1.amazonaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix
```
o
```bash
export DNS=dns@ec2-666-666-666.amanaws.co 
iex --name s1@ec2-69-69-69.compute-1.amazonaws.com --cookie 'rgc' --erl '-kernel inet_dist_listen_min 9000' --erl '-kernel inet_dist_listen_max 9000' -S mix
```

### Cliente
Para disponer de los comandos del cliente en tu sesión actual:
```bash
source apps/client/function.sh 
```

Luego puedes ejecutar los comandos así:
```bash
HOST=gus-Aspire-A515-51 smv help
```
o
```bash
export HOST=gus-Aspire-A515-51
smv help
```