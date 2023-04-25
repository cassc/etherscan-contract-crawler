//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

/**
 * Skillet <> Arcade
 * Vault Router Interface
 * https://etherscan.io/address/0x4B95640d56f81Fc851F952793f4e5485E352bED2#code
 */
interface IVaultRouter {
  function depositERC721(address vaultAddress, address collectionAddress, uint256 tokenId) external;
}