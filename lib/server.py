import socket
from _thread import *

STATUS_OK = "OK"
STATUS_FALL_CONFIRM = "FALL CONFIRM"
STATUS_FALL_CONFIRMED = "FALL CONFIRMED"
STATUS_HELP_NEED = "HELP NEED"
STATUS_HELP_SENT = "HELP SENT"

client_map = {}
status_set = {STATUS_OK, STATUS_FALL_CONFIRM, STATUS_FALL_CONFIRMED, STATUS_HELP_NEED, STATUS_HELP_SENT}


class Client:
    def __init__(self, userID, connection, ip):
        self.userID = userID
        self.connection = connection
        self.ip = ip
        self.status = STATUS_OK

    def send(self, message):
        self.connection.sendall(str.encode(message))

    def recv(self):
        message = self.connection.recv(2048).decode('utf-8')
        return message

    def close(self):
        self.connection.close()


def get_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(0)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP


def threaded_client(connection, ipAddress):
    connection.send(str.encode('Connected to the Server!'))
    userID = connection.recv(2048).decode('utf-8')
    user = Client(userID, connection, ipAddress)
    client_map[ipAddress] = user

    print('Connected to ' + userID +
          " at " + ipAddress[0] + ':' + str(ipAddress[1]) +
          ' On Thread ' + str(threads_cnt))

    while True:
        data = user.recv()
        if not data:
            break
        if data in status_set:
            if data == STATUS_FALL_CONFIRM:
                print("User " + user.userID + " fall detected on phone.")
                user.send(STATUS_FALL_CONFIRM)
            if data == STATUS_HELP_NEED:
                user.send(STATUS_HELP_SENT)
            if data == STATUS_OK:
                user.send(STATUS_OK)
                if user.status == STATUS_FALL_CONFIRM:
                    print("User " + user.userID + " is OK")
        else:
            print("User " + user.userID + " says: " + data)

    user.close()


server = socket.socket()
host = get_ip()  # Standard loopback interface address (localhost)
port = 65432
threads_cnt = 0

try:
    server.bind((host, port))
    print("Running on " + host + ":" + str(port))
except socket.error as e:
    print(str(e))

print('Waiting for a Connection...')
server.listen(5)

while True:
    client, address = server.accept()
    start_new_thread(threaded_client, (client, address))
    threads_cnt += 1
