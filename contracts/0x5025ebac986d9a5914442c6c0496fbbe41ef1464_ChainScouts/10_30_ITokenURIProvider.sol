//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenURIProvider {
    function tokenURI(uint tokenId) external view returns (string memory);
}