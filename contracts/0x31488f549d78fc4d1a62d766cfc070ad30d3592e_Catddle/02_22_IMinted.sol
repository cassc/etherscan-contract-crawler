// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMinted {
   function authorizedMint(address user, uint256 tokenId) external;
}