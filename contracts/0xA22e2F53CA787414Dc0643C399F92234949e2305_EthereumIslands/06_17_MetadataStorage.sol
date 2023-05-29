// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMetadataStorage {
    function getMetadata(uint256 id, uint256 fallbackId) external view returns (string memory);
}

contract MetadataStorage is IMetadataStorage, Ownable {
    mapping(uint256 => string) private _idToMetadata;

    // solhint-disable-next-line no-empty-blocks
    constructor() {
        // nothing to do
    }

    function getMetadata(uint256 id, uint256 fallbackId) external view returns (string memory) {
        if (keccak256(abi.encodePacked(_idToMetadata[id])) == keccak256("")) {
            return _idToMetadata[fallbackId];
        } else {
            return _idToMetadata[id];
        }
    }

    function setMetadata(uint256 id, string memory metadata) external onlyOwner {
        _idToMetadata[id] = metadata;
    }
}