// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoviWallets {
  struct Link {
    address signer;
    bytes signature;
  }  
  function isOwnerOf(Link[] calldata links, address token, uint256 tokenId) external view returns (bool);
  function balanceOf(Link[] calldata links, address token) external view returns (uint256);
  function confirmLinks(Link[] calldata links) external pure returns (bool);
}