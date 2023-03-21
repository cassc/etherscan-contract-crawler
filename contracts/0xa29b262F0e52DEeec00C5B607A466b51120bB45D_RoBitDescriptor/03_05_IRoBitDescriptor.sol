// SPDX-License-Identifier: MIT

/********************************
*                               *
*            [ o_0 ]            *
*                               *
 ********************************/

pragma solidity ^0.8.13;

interface IRoBitDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}