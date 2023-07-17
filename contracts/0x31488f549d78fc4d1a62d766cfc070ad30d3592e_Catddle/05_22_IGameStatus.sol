// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IGameStatus {
   function resolveEncodes(uint256 tokenId, uint256 encode) external;
   function generateEncodes(uint256 tokenId) external view returns(uint256);
}