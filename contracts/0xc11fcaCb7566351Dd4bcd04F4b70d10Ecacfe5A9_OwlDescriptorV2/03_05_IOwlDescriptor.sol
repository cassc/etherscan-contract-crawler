// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               0,0              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IOwlDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}