# Generacion de llaves

ejemplo

ssh-keygen -t ed25519 -C "server x"

-t indica el tipo de algoritmo criptografico para generar el par de claves. 

Los mas comunes
- ed25519
- rsa

-C agrega una estiqueta descriptiva a la clave publica

recordar que la clave publica es la .publica



# Conectarse al servidor

usamos el comando ssh user@ip

ejemplo

ssh ubuntu@203.0.113.10



# Agregar llaves al servidor

copiar el contenido de la llave publica

cat ~/.ssh/server_key.pub

pegarla en el servidor

mkdir -p ~/.ssh

nano ~/.ssh/authorized_keys



# Verificar permisos
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys



# Usar despues

ssh -i ~/.ssh/server_key user@203.0.113.10

el flag -i usar un archivo de identidad para iniciar la conexion ssh



# (OPCIONAL) configurar aliases en pc local

creando ~/.ssh/config y poniendo

Host server-connection
    HostName 203.0.113.10
    User user
    IdentityFile ~/.ssh/server_key

y luego tan solo conectarse con ssh server-connection
