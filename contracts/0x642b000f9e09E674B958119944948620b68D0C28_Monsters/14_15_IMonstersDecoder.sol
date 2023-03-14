// SPDX-License-Identifier: MIT

/*********************************
*                                *
*            (o.O)               *
*           (^^^^^)              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IMonstersDecoder {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}