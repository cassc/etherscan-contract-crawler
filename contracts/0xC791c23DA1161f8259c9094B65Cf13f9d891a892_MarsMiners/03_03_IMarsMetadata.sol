// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMarsMetadata {
    function tokenURI(uint _tokenId,bytes32 _hash, uint _supplyAtMint, uint _opened) external view returns (string memory);
}