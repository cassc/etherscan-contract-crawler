// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* @dev Interface to interact with POAP contract
* - Limited functionality as needed
**/
interface IPOAP {
    // Verifies the token event ID of a token
    function tokenEvent(uint256 tokenId) external returns (uint256);

    function ownerOf(uint256 tokenId) external returns (address);

    function balanceOf(address owner) external returns (uint256);
}