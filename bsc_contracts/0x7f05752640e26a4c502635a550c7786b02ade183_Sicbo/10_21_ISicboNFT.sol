// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "../libraries/Lib.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1155Upgradeable.sol";

interface ISicboNFT is IERC721Upgradeable {
  function nextTokenId() external returns (uint256);

  function mint(address minter) external returns (uint256);

  function mintBatch(address minter, uint256 amount)
    external
    returns (uint256[] memory);

  function burn(uint256 tokenId) external;
}