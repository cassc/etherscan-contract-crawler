// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMetadata {
    function tokenURI(uint _tokenId,bytes32 _hash) external view returns (string memory);
}