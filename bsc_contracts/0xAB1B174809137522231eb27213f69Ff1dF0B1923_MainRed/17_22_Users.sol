// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../secutiry/Administered.sol";

contract Users is Administered {
    /// @dev struct user
    struct User {
        address userReferrer;
        address referredBy;
        uint timestamp;
        bool active;
    }

    /// @dev list user
    mapping(string => User) public listUsers;

    /// @dev add user
    function addUserRed(
        string memory _code,
        address _userReferrer,
        address _referredBy
    ) external onlyUser {
        _addUser(_code, _userReferrer, _referredBy);
    }

    /// @dev add internal user
    function _addUser(
        string memory _code,
        address _user,
        address _referredBy
    ) internal {
        /// @dev is exist user
        require(
            listUsers[_code].userReferrer == address(0),
            "Referred: user is exist"
        );

        listUsers[_code] = User(_user, _referredBy, block.timestamp, true);
    }

    /// @dev get user
    function getUser(string memory _code) public view returns (User memory) {
        return listUsers[_code];
    }

    /// @dev is user exist
    function isUserExist(string memory _code) public view returns (bool) {
        return listUsers[_code].userReferrer != address(0);
    }

    /// @dev Edit  User
    function editUser(
        string memory _code,
        uint256 _type,
        uint256 _number,
        address _addrs,
        bool _bool
    ) external onlyUser {
        if (_type == 1) {
            listUsers[_code].userReferrer = _addrs;
        } else if (_type == 2) {
            listUsers[_code].referredBy = _addrs;
        } else if (_type == 3) {
            listUsers[_code].timestamp = _number;
        } else if (_type == 4) {
            listUsers[_code].active = _bool;
        }
    }
}