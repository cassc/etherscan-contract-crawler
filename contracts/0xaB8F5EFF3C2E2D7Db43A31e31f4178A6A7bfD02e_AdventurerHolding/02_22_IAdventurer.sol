// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAdventurer is IERC721 {
  function summon(
    uint256 parent1,
    uint256 parent2,
    bool withdrawn
  ) external;

  function gen2Count() external returns (uint256 gen2count);

  function maxGenCount() external returns (uint256 maxGenCount);
}