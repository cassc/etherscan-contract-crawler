/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/interfaces/IPlayerBonus.sol

pragma solidity ^0.8.9;

interface IPlayerBonus {
  function bonusOf(address _playerAddress) external view returns (uint256);

  function detailedBonusOf(address _playerAddress) external view returns (uint256);

  function bonusWithFortuneOf(address account) external view returns (uint256, uint256);

  function resetBonusOf(address _playerAddress) external;

  function setStashOf(address _playerAddress, uint256 _stash) external;

  function setMythicMintsOf(address _playerAddress, uint256 _mythicMints) external;

  function incrementMythicsOf(address _playerAddress) external;

  function setSpecialOf(address _playerAddress, uint256 _special) external;

  function setAllOf(address _playerAddress, uint256 _stash, uint256 _mythicMints, uint256 _special) external;
}

// File contracts/features/QuestRewardsCalculator.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract QuestRewardsCalculator {
  IPlayerBonus public playerBonus;

  constructor(address _playerBonus) {
    playerBonus = IPlayerBonus(_playerBonus);
  }

  struct MultiplierRequest {
    uint256 squadType;
    uint256 numberOfNtfs;
    uint256 raritySum;
    uint256 synergyBonus;
    uint256 traits;
    uint256 collections;
    uint256 durationInBlocks;
    address account;
  }

  function getBaseMultipliers(MultiplierRequest memory req) external view returns (uint256[] memory) {
    (uint256 globalBonus, uint256 fortuneLevel) = playerBonus.bonusWithFortuneOf(req.account);

    uint256[] memory multipliers = new uint256[](5);
    multipliers[0] =
      (getBctMultiplier(req.squadType, req.raritySum, globalBonus) * req.durationInBlocks) *
      (fortuneLevel + 1); // BCT
    multipliers[1] =
      (getEbctMultiplier(req.squadType, req.numberOfNtfs, globalBonus) * req.durationInBlocks) *
      (fortuneLevel + 1); // eMM
    multipliers[2] =
      ((getLootMultiplier(req.squadType, req.synergyBonus, req.traits, globalBonus) * req.durationInBlocks) / 28800) *
      (fortuneLevel + 1); // Loot
    multipliers[3] =
      ((getNutsMultiplier(req.collections, globalBonus) * req.durationInBlocks) / 28800) *
      (fortuneLevel + 1); // Nuts
    multipliers[4] = (req.durationInBlocks / 28800) * (fortuneLevel + 1); // Crafting Material (trait reroll, mouse boxes, mammal dna)

    return multipliers;
  }

  function getBctMultiplier(uint256 squadType, uint256 raritySum, uint256 globalBonus) public pure returns (uint256) {
    uint256 multiplier = 100 + globalBonus;

    // Mandatory Pure squads farm 20% more BCT
    if (squadType != 6) {
      multiplier += 20;
    }

    // The higher the sum of the NFTs' rarities, the more BCT they farm (up to 30%) [max: 6 nfts * 5 rarities = 30]
    multiplier += raritySum;

    return multiplier;
  }

  function getEbctMultiplier(
    uint256 squadType,
    uint256 numberOfNtfs,
    uint256 globalBonus
  ) public pure returns (uint256) {
    uint256 multiplier = 100 + globalBonus;

    // Mandatory Pure squads farm 30% more eBCT
    if (squadType != 6) {
      multiplier += 30;
    }

    // The more NFTs there are in the squad, the more eBCT they farm (up to 60%)
    if (numberOfNtfs > 1) {
      multiplier += numberOfNtfs * 10;
    }

    return multiplier;
  }

  function getLootMultiplier(
    uint256 squadType,
    uint256 synergyBonus,
    uint256 traits,
    uint256 globalBonus
  ) public pure returns (uint256) {
    uint256 multiplier = 100 + globalBonus;

    // Mandatory Pure squads farm 100% more Loot
    if (squadType != 6) {
      multiplier += 100;
    }

    // The higher the synergy bonus, the more Loot they farm [max synergy bonus: 1440] (up to 144%)
    multiplier += synergyBonus / 10;

    // The higher the number of traits, the more Loot they farm [max traits: 18] (up to 90%)
    multiplier += traits * 5;

    return multiplier;
  }

  function getNutsMultiplier(uint256 collections, uint256 globalBonus) public pure returns (uint256) {
    uint256 multiplier = 100 + globalBonus;

    // The more collection NFTs in the squad, the more nuts (up to +600%) [max collections: 6]
    // They don't have to belong to the same collection
    multiplier += collections * 100;

    return multiplier;
  }
}