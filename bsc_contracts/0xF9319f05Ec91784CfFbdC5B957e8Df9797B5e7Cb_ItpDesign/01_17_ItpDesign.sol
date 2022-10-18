// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ItpDetails.sol";
import "./IItpDesign.sol";
import "./Utils.sol";

contract ItpDesign is AccessControlUpgradeable, UUPSUpgradeable, IItpDesign {
  struct StatsRange {
    uint256 min;
    uint256 max;
  }

  struct Stats {
    StatsRange stamina;
    StatsRange speed;
    uint256 bombCount;
    StatsRange bombPower;
    uint256 bombRange;
    uint256 ability;
  }

  using ItpDetails for ItpDetails.Details;

  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    
  uint256 private constant COLOR_COUNT = 5;
  uint256 private constant SKIN_COUNT = 8;
  uint256 private constant BOMB_SKIN_COUNT = 20;

  // Mapping from rarity to stats.
  mapping(uint256 => Stats) private rarityStats;

  uint256[] private abilityIds;
  uint256 private tokenLimit;
  uint256 private mintCostBNB;
  uint256[] private dropRate;
  uint256 private mintCost;
  uint256 private maxLevel;
  uint256[][] private upgradeCosts;
  uint256[][] private upgradeCostsBNB;
  uint256[] private abilityRate;

  function initialize() public initializer {
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPGRADER_ROLE, msg.sender);
    _setupRole(DESIGNER_ROLE, msg.sender);

    rarityStats[0] = Stats(
      StatsRange(1, 3), // stamina
      StatsRange(1, 3), // speed  //     uint8 rarity; // 0: random rarity, 1 - 6: specified rarity. from b hero token sol
      1, // bombCount
      StatsRange(1, 3), // bombPower
      1, // bombRange
      1 // ability burda abiility düzz sayı ama aslıdna biz kaç tane abilitsi olacağını yazıyoruz , tamam anladım statslar bunlar power 3 fln gibi ok
    ); //  rand yapacak işte abiility staslarını  ??
    rarityStats[1] = Stats(
      StatsRange(3, 6), //
      StatsRange(3, 6),
      2,
      StatsRange(3, 6),
      2,
      2
    );
    rarityStats[2] = Stats(
      StatsRange(6, 9), //
      StatsRange(6, 9),
      3,
      StatsRange(6, 9),
      3,
      3
    );
    rarityStats[3] = Stats(
      StatsRange(9, 12), //
      StatsRange(9, 12),
      4,
      StatsRange(9, 12),
      4,
      4
    );
    rarityStats[4] = Stats(
      StatsRange(12, 15), //
      StatsRange(12, 15),
      5,
      StatsRange(12, 15),
      5,
      5
    );
    rarityStats[5] = Stats(
      StatsRange(15, 18), //
      StatsRange(15, 18),
      6,
      StatsRange(15, 18),
      6,
      6
    );
    abilityIds = [1, 2, 3, 4, 5, 6, 7]; 
    abilityRate = [1, 2, 1, 1, 1, 2, 2]; 
    tokenLimit = 500;
    dropRate = [8287, 1036, 518, 104, 52, 4]; // 8287 + 1036 + 518 + 104 + 52 + 4 = 10000 (100%)  
    mintCost = 0.00005 ether;
    mintCostBNB = 0.00005 ether;
    maxLevel = 5;
    upgradeCosts.push([1 ether, 2 ether, 4 ether, 7 ether]); 
    upgradeCosts.push([2 ether, 4 ether, 5 ether, 9 ether]); 
    upgradeCosts.push([2 ether, 4 ether, 5 ether, 10 ether]); 
    upgradeCosts.push([3 ether, 7 ether, 11 ether, 22 ether]); 
    upgradeCosts.push([7 ether, 18 ether, 40 ether, 146 ether]);
    upgradeCosts.push([9 ether, 25 ether, 56 ether, 199 ether]);

    upgradeCostsBNB.push([1 ether, 2 ether, 4 ether, 7 ether]);
    upgradeCostsBNB.push([2 ether, 4 ether, 5 ether, 9 ether]);
    upgradeCostsBNB.push([2 ether, 4 ether, 5 ether, 10 ether]);
    upgradeCostsBNB.push([3 ether, 7 ether, 11 ether, 22 ether]);
    upgradeCostsBNB.push([7 ether, 18 ether, 40 ether, 146 ether]);
    upgradeCostsBNB.push([9 ether, 25 ether, 56 ether, 199 ether]);

  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /** Sets the rarity stats. */
  function setRarityStats(uint256 rarity, Stats memory stats) external onlyRole(DESIGNER_ROLE) {
    rarityStats[rarity] = stats;
  }

  /** Sets the token limit. */
  function setTokenLimit(uint256 value) external onlyRole(DESIGNER_ROLE) {
    tokenLimit = value;
  }

  /** Sets the drop rate. */
  function setDropRate(uint256[] memory value) external onlyRole(DESIGNER_ROLE) {
    dropRate = value;
  }

  /** Sets the minting fee. */
  function setMintCost(uint256 value) external onlyRole(DESIGNER_ROLE) {
    mintCost = value;
  }

  /** Sets the minting fee in BNB. */
  function setMintCostBNB(uint256 value) external onlyRole(DESIGNER_ROLE) {
    mintCostBNB = value;
  }

  /** Sets max upgrade level. */
  function setMaxLevel(uint256 value) external onlyRole(DESIGNER_ROLE) {
    maxLevel = value;
  }

  /** Sets the current upgrade cost. */
  function setUpgradeCosts(uint256[][] memory value) external onlyRole(DESIGNER_ROLE) {
    upgradeCosts = value;
  }

  /** Sets the current upgrade cost in BNB. */
  function setUpgradeCostsBNB(uint256[][] memory value) external onlyRole(DESIGNER_ROLE) {
    upgradeCostsBNB = value;
  }

  function setAbilityRate(uint256[] memory value) external onlyRole(DESIGNER_ROLE) {
    abilityRate = value;
  }

  function getRarityStats() external view returns (Stats[] memory) {
    uint256 size = dropRate.length; 
    Stats[] memory result = new Stats[](size);
    for (uint256 i = 0; i < size; ++i) {
      result[i] = rarityStats[i]; 
    }
    return result;
  }

  function getTokenLimit() external view override returns (uint256) {
    return tokenLimit;
  }

  function getDropRate() external view returns (uint256[] memory) {
    return dropRate;
  }

  function getMintCost() external view override returns (uint256) {
    return mintCost;
  }

  function getMintCostBNB() external view override returns (uint256) {
    return mintCostBNB;
  }

  function getMaxLevel() external view override returns (uint256) {
    return maxLevel;
  }

  function getUpgradeCost(uint256 rarity, uint256 level) external view override returns (uint256) {
    return upgradeCosts[rarity][level];
  }

  function getUpgradeCosts() external view returns (uint256[][] memory) {
    return upgradeCosts;
  }

  function getUpgradeCostBNB(uint256 rarity, uint256 level) external view override returns (uint256) {
    return upgradeCostsBNB[rarity][level];
  }

  function getUpgradeCostsBNB() external view returns (uint256[][] memory) {
    return upgradeCostsBNB;
  }

  function getAbilityRate() external view returns (uint256[] memory) {
    return abilityRate;
  }

  function createRandomToken( 
    uint256 seed,
    uint256 id,
    uint256 rarity
  ) external view override returns (uint256 nextSeed, uint256 encodedDetails) {
    ItpDetails.Details memory details;
    details.id = id;

    if (rarity == ItpDetails.ALL_RARITY) {
      // Random rarity.
      (seed, details.rarity) = Utils.weightedRandom(seed, dropRate); 
    } else {
      // Specified rarity.
      details.rarity = rarity - 1;
    }
    details.level = 1;

    Stats storage stats = rarityStats[details.rarity]; 
    details.bombCount = stats.bombCount; 
    details.bombRange = stats.bombRange; 

    (seed, details.color) = Utils.randomRangeInclusive(seed, 1, COLOR_COUNT);
    (seed, details.skin) = Utils.randomRangeInclusive(seed, 1, SKIN_COUNT); 
    (seed, details.stamina) = Utils.randomRangeInclusive(seed, stats.stamina.min, stats.stamina.max);
    (seed, details.speed) = Utils.randomRangeInclusive(seed, stats.speed.min, stats.speed.max); 
    (seed, details.bombSkin) = Utils.randomRangeInclusive(seed, 1, BOMB_SKIN_COUNT); 
    (seed, details.bombPower) = Utils.randomRangeInclusive(seed, stats.bombPower.min, stats.bombPower.max); 

    uint256[] memory rate = abilityRate;
    if (details.rarity == 0) {
      // Common, ignore piercing block skill.
      rate[2] = 0;
    }
    (seed, details.abilities) = Utils.weightedRandomSampling(seed, abilityIds, rate, stats.ability);
    details.blockNumber = block.number;

    nextSeed = seed;
    encodedDetails = details.encode();
  } 
}