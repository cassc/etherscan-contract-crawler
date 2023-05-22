pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*

   Copyright Tether.to 2020

   Author Will Harborne

   Licensed under the Apache License, Version 2.0
   http://www.apache.org/licenses/LICENSE-2.0

*/


contract WithBlockedList is OwnableUpgradeable {

    /**
     * @dev Reverts if called by a blocked account
     */
    modifier onlyNotBlocked() {
      require(!isBlocked[_msgSender()], "Blocked: transfers are blocked for user");
      _;
    }

    mapping (address => bool) public isBlocked;

    function addToBlockedList (address _user) public onlyOwner {
        isBlocked[_user] = true;
        emit BlockPlaced(_user);
    }

    function removeFromBlockedList (address _user) public onlyOwner {
        isBlocked[_user] = false;
        emit BlockReleased(_user);
    }

    event BlockPlaced(address indexed _user);

    event BlockReleased(address indexed _user);

}