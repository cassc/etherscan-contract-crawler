// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INefturianArtifact is IERC1155 {
  event UseArtifact(uint256 tokenId, uint256 quantity);

  event UseArtifacts(uint256[] tokenIds, uint256[] quantities);

  event UpdateOdds(uint256[] oldOdds, uint256[] newOdds);

  event AddRareItem(uint256 rarity, uint256 quantity, bool isConsumable);

  function giveEgg(address to) external;

  function transferOwnership(address to) external;
}