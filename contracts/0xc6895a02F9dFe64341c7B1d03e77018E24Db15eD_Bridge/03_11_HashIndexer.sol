// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract HashIndexer {
    mapping(string => bool) private hashes;

    event HashAdded(string hash);

    constructor () {}

    modifier onlyInexistentHash(string memory _hash) {
        require(!hashes[_hash], "HashIndexer: such hash already exists");
        _;
    }

    function _addHash(string memory _hash) internal {
        hashes[_hash] = true;
        emit HashAdded(_hash);
    }

    function containsHash(string memory _hash) external view returns (bool){
        return _containsHash(_hash);
    }

    function _containsHash(string memory _hash) internal view returns (bool){
        return hashes[_hash];
    }
}