pragma solidity ^0.5.15;

import "./Ownable.sol";

/**
* @title WhiteList
* @dev A Whitelist maintaned by the governance
*/
contract WhiteList is Ownable {

    mapping (address => bool) public inWhiteList;

    constructor(address governance) public Ownable(governance) {}

    function add(address toAdd) external onlyOwner {
        inWhiteList[toAdd] = true;
    }

    function remove(address toRemove) external onlyOwner {
        inWhiteList[toRemove] = false;
    }  

}