// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TestContract is Ownable {
    

    mapping(address => bool) public OG_ALLOW_LIST;


    constructor(string memory _initBaseURI, string memory _initNotRevealedUri){
        // do something
    }

        // Owner functions
    function addToOGList(address[] memory _allow) external onlyOwner {
        for (uint256 i; i < _allow.length; i++) {
            OG_ALLOW_LIST[_allow[i]] = true;
        }
    }
    
}