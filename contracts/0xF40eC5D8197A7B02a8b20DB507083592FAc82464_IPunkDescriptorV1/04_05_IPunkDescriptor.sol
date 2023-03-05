// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               PU,NK            *
*                                *
 *********************************/

pragma solidity ^0.8.9;

interface IPunkDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}