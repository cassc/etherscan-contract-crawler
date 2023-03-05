// SPDX-License-Identifier: MIT

/*********************************
*                                *
*             d[0_0]b            *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IRobowlsDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}