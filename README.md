# Local Installation
This application uses Docker to maintain the database.

## Dependencies

1.  Before execute the script, it's necessary add the below files in the correct path:

| Archivos                                                       | Camino (*Mac/Linux*)    |
| ---------------------------------------------------------------| ----------------------- |
| liferay-dxp-tomcat-7.4.13-ga1-20211020105546063.tar.gz         | `~/.liferay/bundles`    |

| Archivos                                                       | Camino (*Windows*)         |
| ---------------------------------------------------------------| -------------------------- |
| liferay-dxp-tomcat-7.4.13-ga1-20211020105546063.tar.gz         | `proyecto/files/bundles`   |

### To init Liferay

1. Execute the command:

```shell
./setup.sh init
```

If you have Windows:
> It's necessary to install https://github.com/bmatzelle/gow/wiki and use [Git Bash](https://gitforwindows.org/)

Using that, execute the command: 
```shell
./setup.sh init 
```

2. Use the user and password below to login in:
**http://localhost:8080**

* user: test
* pass: test


### Working with Liferay

1. Start Liferay
```sh
./setup.sh start
```
2. Stop Liferay
```sh
./setup.sh stop
```
2. Restart Liferay
```sh
./setup.sh restart
```

### Deploy your modules

```sh
./setup.sh deploy
```

### Save and load the database

1. Save database backup:
```sh
./setup.sh savestate
```

2. Load database backup:
```sh
./setup.sh loadstate
```

### Configure database

1. Go to a client who accepts MySQL database, like DBeaver

2. Use the information below:
```
Host: 127.0.0.1
Port: 3391
Database: lportal_cge
User: root
Password: cge@2021
```