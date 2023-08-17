// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ITokenMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
}