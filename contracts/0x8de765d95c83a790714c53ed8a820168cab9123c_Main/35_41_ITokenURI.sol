// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.19;

interface ITokenURI {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}