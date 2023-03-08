// SPDX-License-Identifier: MIT

/*********************************
*                                *
*            (\_/)               *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IRaBitDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}