const sqlite3 = require('sqlite3').verbose()
const path = require('path')

class UserService {
    constructor() {
        this.db = new sqlite3.Database(
            __dirname + '../../database/users.db',
            (err) => {
                if (err) {
                    console.error("Failed to open users database.", err);
                } else {
                    console.log("User service database connected");
                }
            }
        );
    }

    getUserInfo(userId) {
        // TODO:
        return info;
    }
}

module.exports = UserService