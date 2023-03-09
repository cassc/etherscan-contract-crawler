// SPDX-License-Identifier: MIT

/*********************************
*                                *
*              (oo)              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IOinkDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}