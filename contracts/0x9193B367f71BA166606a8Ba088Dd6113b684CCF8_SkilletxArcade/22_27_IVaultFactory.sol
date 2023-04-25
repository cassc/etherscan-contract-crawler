//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * Skillet <> Arcade
 * Vault Factory Interface
 * https://etherscan.io/address/0x6e9B4c2f6Bd57b7b924d29b5dcfCa1273Ecc94A2#code
 */
interface IVaultFactory is IERC721 {
  function instanceAt(uint256 tokenId) external view returns (address);  
  function initializeBundle(address to) external returns(uint256);
  function approve(address controller, uint256 vaultAddress) external;
}