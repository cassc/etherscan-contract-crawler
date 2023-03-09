// SPDX-License-Identifier: MIT

/*********************************
*                                *
*               •                *
*                                *
 *********************************/

pragma solidity ^0.8.13;

interface IBlackHoleDescriptor {
    function tokenURI(uint256 tokenId, string memory name, uint256 mergers) external view returns (string memory);
}