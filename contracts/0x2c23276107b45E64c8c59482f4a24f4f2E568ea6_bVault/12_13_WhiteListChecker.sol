pragma solidity ^0.5.15;

import "./WhiteList.sol";

/**
* @title WhiteListChecker
* @dev Inherit this contract to check if a contract is whitelisted
*/
contract WhiteListChecker {

    WhiteList public whiteList;

    modifier onlyWhiteListed() {
        require((tx.origin == msg.sender) || whiteList.inWhiteList(msg.sender), "not in white list");
        _;
    }

    constructor(address whiteListAddress) public {
        whiteList = WhiteList(whiteListAddress);
    }
}