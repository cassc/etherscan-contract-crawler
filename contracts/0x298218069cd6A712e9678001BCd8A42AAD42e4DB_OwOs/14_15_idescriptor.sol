// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               OwO              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IOwODescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}