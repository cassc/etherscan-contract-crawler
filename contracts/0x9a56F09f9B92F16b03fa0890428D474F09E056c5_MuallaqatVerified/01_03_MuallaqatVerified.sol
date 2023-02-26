/*
    Copyright 2023, Abdullah Al-taheri عبدالله الطاهري (المُعلَّقَاتٌ - muallaqat.io - muallaqat.eth - معلقات.eth)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MuallaqatVerified Contract
/// @author Abdullah Al-taheri

pragma solidity ^0.8.18;


import "@openzeppelin/contracts/access/Ownable.sol";


contract MuallaqatVerified is Ownable  {

    enum LEVELS{
        Star,
        Gem,
        Fire,
        Crown,
        GOAT
    }


    struct UserLevel {
        LEVELS userLevel;
        uint256 expirationDate;
    }
    event Activity (
        address userAddress,
        LEVELS userLevel,
        uint256 expirationDate
    );
    struct LevelDataStruct {
        uint256 expirationDate;
        uint256 fees;
    }
    mapping(address => UserLevel) private users;
    mapping(uint256 => LevelDataStruct) private LevelData;
    // ADMIN FUNCTIONS
  
    function setLevel(
        uint256 level,
        uint256 level_fees,
        uint256 level_expiration_date
  
    ) public onlyOwner  {
        LevelData[level].fees = level_fees;
        LevelData[level].expirationDate = level_expiration_date;
       
    }
    // constructor
    constructor() {
        LevelData[0] = LevelDataStruct(86400 * 30, 0.01 ether);
        LevelData[1] = LevelDataStruct(86400 * 30 * 4,  0.1 ether);
        LevelData[2] = LevelDataStruct(86400 * 30 * 8,  0.2 ether);
        LevelData[3] = LevelDataStruct(86400 * 30 * 12, 1 ether);
        LevelData[4] = LevelDataStruct(86400 * 30 * 120, 20 ether);
    }


    function updateUserAdmin( 
        address _userAddress,
        uint256 level,
        uint256 expirationDate
    ) public onlyOwner   {
        users[_userAddress] = UserLevel(
            LEVELS(level),
            expirationDate
        );
    }
    function verifyUser(address _userAddress,uint256 level) public onlyOwner {
        users[_userAddress].userLevel = LEVELS(level);
        users[_userAddress].expirationDate =  block.timestamp + LevelData[level].expirationDate;
        emit Activity(_userAddress, users[_userAddress].userLevel, users[_userAddress].expirationDate);
    }
    function updateLevel(uint256 level) public payable  {
        require(msg.value >= LevelData[level].fees,  "Not enought ether ");
        // make sure user is not already verified and show "User already verified"
        require(users[msg.sender].expirationDate < block.timestamp, "User already verified");
        users[msg.sender].userLevel = LEVELS(level);
        users[msg.sender].expirationDate = block.timestamp + LevelData[level].expirationDate;
        emit Activity(msg.sender, LEVELS(level), users[msg.sender].expirationDate);
        // transfer fees to owner
        payable(owner()).transfer(msg.value);
    }

    // get user data
    function getUserData(address userAddress) public view returns (UserLevel memory) {
        return users[userAddress];
    }



    // get all leve data 
    function getLevelData() public view returns (LevelDataStruct [5] memory) {
        return [
            LevelData[0],
            LevelData[1],
            LevelData[2],
            LevelData[3],
            LevelData[4]
        ];
    }
}