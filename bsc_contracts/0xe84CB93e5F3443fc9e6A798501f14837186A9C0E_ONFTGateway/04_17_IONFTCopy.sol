// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IONFTCopy {
    function burn(uint256 tokenId) external;
    function mint(address owner, uint256 tokenId, string memory tokenURI) external;
    function setOwnership(address newOwner) external;
}