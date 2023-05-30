// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../utils/FurLib.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title IFurballEdition
/// @author LFG Gaming LLC
/// @notice Interface for a single edition within Furballs
interface IFurballEdition is IERC165 {
  function index() external view returns(uint8);
  function count() external view returns(uint16);
  function maxCount() external view returns (uint16); // total max count in this edition
  function addCount(address to, uint16 amount) external returns(bool);

  function liveAt() external view returns(uint64);
  function minted(address addr) external view returns(uint16);
  function maxMintable(address addr) external view returns(uint16);
  function maxAdoptable() external view returns (uint16); // how many can be adopted, out of the max?
  function purchaseFur() external view returns(uint256); // amount of FUR for buying

  function spawn() external returns (uint256, uint16);

  /// @notice Calculates the effects of the loot in a Furball's inventory
  function modifyReward(
    FurLib.RewardModifiers memory modifiers, uint256 tokenId
  ) external view returns(FurLib.RewardModifiers memory);

  /// @notice Renders a JSON object for tokenURI
  function tokenMetadata(
    bytes memory attributes, uint256 tokenId, uint256 number
  ) external view returns(bytes memory);
}