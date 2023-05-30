// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../editions/IFurballEdition.sol";
import "../utils/FurLib.sol";

/// @title ILootEngine
/// @author LFG Gaming LLC
/// @notice The loot engine is patchable by replacing the Furballs' engine with a new version
interface ILootEngine is IERC165 {
  /// @notice When a Furball comes back from exploration, potentially give it some loot.
  function dropLoot(uint32 intervals, FurLib.RewardModifiers memory mods) external returns(uint128);

  /// @notice Players can pay to re-roll their loot drop on a Furball
  function upgradeLoot(
    FurLib.RewardModifiers memory modifiers,
    address owner,
    uint128 lootId,
    uint8 chances
  ) external returns(uint128);

  /// @notice Some zones may have preconditions
  function enterZone(uint256 tokenId, uint32 zone, uint256[] memory team) external returns(uint256);

  /// @notice Calculates the effects of the loot in a Furball's inventory
  function modifyReward(
    FurLib.Furball memory furball,
    FurLib.RewardModifiers memory baseModifiers,
    FurLib.Account memory account,
    bool contextual
  ) external view returns(FurLib.RewardModifiers memory);

  /// @notice Loot can have different weight to help prevent over-powering a furball
  function weightOf(uint128 lootId) external pure returns (uint16);

  /// @notice JSON object for displaying metadata on OpenSea, etc.
  function attributesMetadata(uint256 tokenId) external view returns(bytes memory);

  /// @notice Get a potential snack for the furball by its ID
  function getSnack(uint32 snack) external view returns(FurLib.Snack memory);

  /// @notice Proxy registries are allowed to act as 3rd party trading platforms
  function canProxyTrades(address owner, address operator) external view returns(bool);

  /// @notice Authorization mechanics are upgradeable to account for security patches
  function approveSender(address sender) external view returns(uint);

  /// @notice Called when a Furball is traded to update delegate logic
  function onTrade(
    FurLib.Furball memory furball, address from, address to
  ) external;

  /// @notice Handles experience gain during collection
  function onExperience(
    FurLib.Furball memory furball, address owner, uint32 experience
  ) external returns(uint32 totalExp, uint16 level);

  /// @notice Gets called at the beginning of token render; could add underlaid artwork
  function render(uint256 tokenId) external view returns(string memory);

  /// @notice The loot engine can add descriptions to furballs metadata
  function furballDescription(uint256 tokenId) external view returns (string memory);
}