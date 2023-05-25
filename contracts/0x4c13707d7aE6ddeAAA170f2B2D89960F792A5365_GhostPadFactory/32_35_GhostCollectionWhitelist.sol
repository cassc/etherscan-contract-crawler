// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract GhostCollectionWhitelist is Ownable {
    string public name;
    event UpdateCollection(address indexed _collection);

    address[] public whitelistCollections;
    mapping(address => bool) public isAlreadyRegistered;

    constructor(string memory _name) {
        name = _name;
    }

    function updateCollections(address _collection) external onlyOwner {
        require(!isAlreadyRegistered[_collection], 'GhostCollectionWhitelist : already registered collection.');
        whitelistCollections.push(_collection);
        isAlreadyRegistered[_collection] = true;
        emit UpdateCollection(_collection);
    }

    function isCollectionHolder(address _user) public view returns (bool) {
        if (whitelistCollections.length == 0) {
            return true;
        }
        for (uint256 i = 0; i < whitelistCollections.length; i++) {
            address _collection = whitelistCollections[i];
            if (IERC721(_collection).balanceOf(_user) > 0) {
                return true;
            }
        }
        return false;
    }
}