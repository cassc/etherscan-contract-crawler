//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

/**
 * Skillet <> Arcade
 * Asset Vault Interface
 * https://etherscan.io/address/0xd898456e39a461b102ce4626aac191582c38acb6#code
 */
interface IAssetVault {
  function enableWithdraw() external;
  function withdrawERC721(address token, uint256 tokenId, address to) external;
}