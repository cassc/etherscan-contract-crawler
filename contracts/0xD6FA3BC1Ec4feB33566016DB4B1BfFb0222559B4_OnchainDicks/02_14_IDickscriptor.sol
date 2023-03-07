// SPDX-License-Identifier: MIT

/*********************************
*                                *
*          8======D              *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IDickscriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}