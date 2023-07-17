// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IFriendship {
   function resetFriendship(uint256 tokenId) external;
   function friendships(uint256 tokenId) external view returns (uint16);
}