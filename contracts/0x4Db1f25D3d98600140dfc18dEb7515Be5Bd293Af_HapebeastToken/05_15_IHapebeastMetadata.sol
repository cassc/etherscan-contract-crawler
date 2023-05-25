// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract IHapebeastMetadata {
    function tokenURI(uint256 tokenId) public virtual view returns (string memory);
}