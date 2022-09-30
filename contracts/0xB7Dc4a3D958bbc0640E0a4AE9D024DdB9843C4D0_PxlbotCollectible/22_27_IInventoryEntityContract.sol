//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//defines an "Entity" that can hold an item in inventory (e.g. a pxlbot; consisting of pxlbot contract address and a token ID)
interface IInventoryEntityContract {
  // Base id is determined by the contract. Examples might be tokenId in an ERC721 or simply putting 1 for ERC20
  function irlOwner(uint256 _baseId) external returns (address);
}