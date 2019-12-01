# Client

Es necesario cargar el archivo `function.sh` para que se puedan ejecutar los comandos:
(desde la carpeta principal de la aplicación)
```
source apps/client/function.sh
```
El uso es:
```
svm <comando> <argumentos>
```

# # Comandos
- `help`: muestra al usuario los posibles comandos para el SMV.
- `log <file name> <n>`: muestra al usuario información de los últimos `<n>` commits del archivo cuyo nombre sea `<file name>`.
- `update <file name>`: se le proporciona al usuario la última versión del archivo cuyo nombre es `<file name>` que se encuentrenen los servidores.
- `checkout <file name> <timestamp>`: se le proporciona al usuario la versión del archivo con nombre `<file name>` cuyo commit fue creado en el tiempo `<timestamp>`.
- `commit <path file> <file name> <message>`: guarda el archivo local que se encuentre en `<path file>` como una nueva versión de `<file name>` y cuyo commit tiene un mensaje `<message>`.
