// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IWorlds_ERC721.sol";
import "./IWorldsEscrow.sol";
import "./IWorldsRental.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library WorldsEscrowStorage {
  
  bytes32 private constant STORAGE_SLOT = keccak256("slot.worlds.escrow");

  struct Layout {
    address rewardTokenAddress;
    IWorlds_ERC721 Worlds_ERC721;
    IWorldsRental WorldsRental;
    IWorldsEscrow.WorldInfo[10001] worldInfo; // World tokenId is in N [1,10000]
    IWorldsEscrow.RewardsPeriod rewardsPeriod;
    IWorldsEscrow.RewardsPerWeight rewardsPerWeight;
    mapping(address => IWorldsEscrow.UserRewards) rewards;
    mapping(address => EnumerableSet.UintSet) userStakes;
    address signer;
  }

  function layout() internal pure returns (Layout storage _layout) {
    bytes32 slot = STORAGE_SLOT;

    assembly {
      _layout.slot := slot
    }
  }
}