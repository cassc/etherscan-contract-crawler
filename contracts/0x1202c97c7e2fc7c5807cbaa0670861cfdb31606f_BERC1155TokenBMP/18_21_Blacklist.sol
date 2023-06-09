// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// Openzeppelin imports
import '@openzeppelin/contracts/access/Ownable.sol';


contract Blacklist is Ownable {

    mapping (address => bool) private _isBlacklisted;

    constructor() {
    }

    function isInBlacklist(address addr_) public view returns (bool) {
        return _isBlacklisted[addr_];
    }

    function addToBlacklist(address addr_) public onlyOwner {

        require(! _isBlacklisted[addr_], 'Address already in blacklist');
        _isBlacklisted[addr_] = true;
    }

    function removeFromBlacklist(address addr_) public onlyOwner {

        require(_isBlacklisted[addr_], 'Address is not in blacklist');
        _isBlacklisted[addr_] = false;
    }
}