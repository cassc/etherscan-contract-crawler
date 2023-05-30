// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ILootEngine.sol";
import "../editions/IFurballEdition.sol";
import "../Furballs.sol";
import "../utils/FurLib.sol";
import "../utils/FurProxy.sol";
import "../utils/ProxyRegistry.sol";
import "../utils/Dice.sol";
import "../utils/Governance.sol";
import "../utils/MetaData.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title LootEngine
/// @author LFG Gaming LLC
/// @notice Base implementation of the loot engine
abstract contract LootEngine is ERC165, ILootEngine, Dice, FurProxy {
  ProxyRegistry private _proxies;

  // An address which may act on behalf of the owner (company)
  address public companyWalletProxy;

  // snackId to "definition" of the snack
  mapping(uint32 => FurLib.Snack) private _snacks;

  uint32 maxExperience = 2010000;

  constructor(
    address furballsAddress, address tradeProxy, address companyProxy
  ) FurProxy(furballsAddress) {
    _proxies = ProxyRegistry(tradeProxy);
    companyWalletProxy = companyProxy;

    _defineSnack(0x100, 24    ,  250, 15, 0);
    _defineSnack(0x200, 24 * 3,  750, 20, 0);
    _defineSnack(0x300, 24 * 7, 1500, 25, 0);
  }

  /// @notice Allows admins to configure the snack store.
  function setSnack(
    uint32 snackId, uint32 duration, uint16 furCost, uint16 hap, uint16 en
  ) external gameAdmin {
    _defineSnack(snackId, duration, furCost, hap, en);
  }

  /// @notice Loot can have different weight to help prevent over-powering a furball
  /// @dev Each point of weight can be offset by a point of energy; the result reduces luck
  function weightOf(uint128 lootId) external virtual override pure returns (uint16) {
    return 2;
  }

  /// @notice Gets called for Metadata
  function furballDescription(uint256 tokenId) external virtual override view returns (string memory) {
    return "";
  }

  /// @notice Gets called at the beginning of token render; could add underlaid artwork
  function render(uint256 tokenId) external virtual override view returns(string memory) {
    return "";
  }

  /// @notice Checking the zone may use _require to detect preconditions.
  function enterZone(
    uint256 tokenId, uint32 zone, uint256[] memory team
  ) external virtual override returns(uint256) {
    // Nothing to see here.
    return uint256(zone);
  }

  /// @notice Proxy logic is presently delegated to OpenSea-like contract
  function canProxyTrades(
    address owner, address operator
  ) external virtual override view onlyFurballs returns(bool) {
    if (address(_proxies) == address(0)) return false;
    return address(_proxies.proxies(owner)) == operator;
  }

  /// @notice Allow a player to play? Throws on error if not.
  /// @dev This is core gameplay security logic
  function approveSender(address sender) external virtual override view onlyFurballs returns(uint) {
    if (sender == companyWalletProxy && sender != address(0)) return FurLib.PERMISSION_OWNER;
    return _permissions(sender);
  }

  /// @notice Calculates new level for experience
  function onExperience(
    FurLib.Furball memory furball, address owner, uint32 experience
  ) external virtual override onlyFurballs returns(uint32 totalExp, uint16 levels) {
    if (experience == 0) return (0, 0);

    uint32 has = furball.experience;
    uint32 max = maxExperience;
    totalExp = (experience < max && has < (max - experience)) ? (has + experience) : max;

    // Calculate new level & check for level-up
    uint16 oldLevel = furball.level;
    uint16 level = uint16(FurLib.expToLevel(totalExp, max));
    levels = level > oldLevel ? (level - oldLevel) : 0;

    if (levels > 0) {
      // Update community standing
      furballs.governance().updateMaxLevel(owner, level);
    }

    return (totalExp, levels);
  }

  /// @notice The trade hook can update balances or assign rewards
  function onTrade(
    FurLib.Furball memory furball, address from, address to
  ) external virtual override onlyFurballs {
    Governance gov = furballs.governance();
    if (from != address(0)) gov.updateAccount(from, furballs.balanceOf(from) - 1);
    if (to != address(0)) gov.updateAccount(to, furballs.balanceOf(to) + 1);
  }

  /// @notice Attempt to upgrade a given piece of loot (item ID)
  function upgradeLoot(
    FurLib.RewardModifiers memory modifiers,
    address owner,
    uint128 lootId,
    uint8 chances
  ) external virtual override returns(uint128) {
    (uint8 rarity, uint8 stat) = _itemRarityStat(lootId);

    require(rarity > 0 && rarity < 3, "RARITY");
    uint32 chance = (rarity == 1 ? 75 : 25) * uint32(chances) + uint32(modifiers.luckPercent * 10);

    // Remove the 100% from loot, with 5% minimum chance
    chance = chance > 1050 ? (chance - 1000) : 50;

    // Even with many chances, odds are capped:
    if (chance > 750) chance = 750;

    uint32 threshold = (FurLib.Max32 / 1000) * (1000 - chance);
    uint256 rolled = (uint256(roll(modifiers.expPercent)));

    return rolled < threshold ? 0 : _packLoot(rarity + 1, stat);
  }

  /// @notice Main loot-drop functionm
  function dropLoot(
    uint32 intervals,
    FurLib.RewardModifiers memory modifiers
  ) external virtual override onlyFurballs returns(uint128) {
    // Only battles drop loot.
    if (modifiers.zone >= 0x10000) return 0;

    (uint8 rarity, uint8 stat) = rollRarityStat(
      uint32((intervals * uint256(modifiers.luckPercent)) /100), 0);
    return _packLoot(rarity, stat);
  }

  function _packLoot(uint16 rarity, uint16 stat) internal pure returns(uint128) {
    return rarity == 0 ? 0 : (uint16(rarity) * 0x10000) + (stat * 0x100);
  }

  /// @notice Core loot drop rarity randomization
  /// @dev exposes an interface helpful for the unit tests, but is not otherwise called publicly
  function rollRarityStat(uint32 chance, uint32 seed) public returns(uint8, uint8) {
    if (chance == 0) return (0, 0);
    uint32 threshold = 4320;
    uint32 rolled = roll(seed) % threshold;
    uint8 stat = uint8(rolled % 2);

    if (chance > threshold || rolled >= (threshold - chance)) return (3, stat);
    threshold -= chance;
    if (chance * 3 > threshold || rolled >= (threshold - chance * 3)) return (2, stat);
    threshold -= chance * 3;
    if (chance * 6 > threshold || rolled >= (threshold - chance * 6)) return (1, stat);
    return (0, stat);
  }

  /// @notice The snack shop has IDs for each snack definition
  function getSnack(uint32 snackId) external view virtual override returns(FurLib.Snack memory) {
    return _snacks[snackId];
  }

  /// @notice Layers on LootEngine modifiers to rewards
  function modifyReward(
    FurLib.Furball memory furball,
    FurLib.RewardModifiers memory modifiers,
    FurLib.Account memory account,
    bool contextual
  ) external virtual override view returns(FurLib.RewardModifiers memory) {
    // Use temporary variables instead of re-assignment
    uint16 energy = modifiers.energyPoints;
    uint16 weight = furball.weight;
    uint16 expPercent = modifiers.expPercent + modifiers.happinessPoints;
    uint16 luckPercent = modifiers.luckPercent + modifiers.happinessPoints;
    uint16 furPercent = modifiers.furPercent + _furBoost(furball.level) + energy;

    // First add in the inventory
    for (uint256 i=0; i<furball.inventory.length; i++) {
      uint128 lootId = uint128(furball.inventory[i] / 0x100);
      uint32 stackSize = uint32(furball.inventory[i] % 0x100);
      (uint8 rarity, uint8 stat) = _itemRarityStat(lootId);
      uint16 boost = uint16(_lootRarityBoost(rarity) * stackSize);
      if (stat == 0) {
        expPercent += boost;
      } else {
        furPercent += boost;
      }
    }

    // Team size boosts!
    uint256 teamSize = account.permissions < 2 ? account.numFurballs : 0;
    if (teamSize < 10 && teamSize > 1) {
      uint16 amt = uint16(2 * (teamSize - 1));
      expPercent += amt;
      furPercent += amt;
    }

    // ---------------------------------------------------------------------------------------------
    // Negative impacts come last, so subtraction does not underflow.
    // ---------------------------------------------------------------------------------------------

    // Penalties for whales.
    if (teamSize > 10) {
      uint16 amt = uint16(5 * (teamSize > 20 ? 10 : (teamSize - 10)));
      expPercent -= amt;
      furPercent -= amt;
    }

    // Calculate weight & reduce luck
    if (weight > 0) {
      if (energy > 0) {
        weight = (energy >= weight) ? 0 : (weight - energy);
      }
      if (weight > 0) {
        luckPercent = weight >= luckPercent ? 0 : (luckPercent - weight);
      }
    }

    modifiers.expPercent = expPercent;
    modifiers.furPercent = furPercent;
    modifiers.luckPercent = luckPercent;

    return modifiers;
  }

  /// @notice OpenSea metadata
  function attributesMetadata(
    uint256 tokenId
  ) external virtual override view returns(bytes memory) {
    FurLib.FurballStats memory stats = furballs.stats(tokenId, false);
    return abi.encodePacked(
      MetaData.traitValue("Level", stats.definition.level),
      MetaData.traitValue("Rare Genes Boost", stats.definition.rarity),
      MetaData.traitNumber("Edition", (tokenId % 0x100) + 1),
      MetaData.traitNumber("Unique Loot Collected", stats.definition.inventory.length),
      MetaData.traitBoost("EXP Boost", stats.modifiers.expPercent),
      MetaData.traitBoost("FUR Boost", stats.modifiers.furPercent),
      MetaData.traitDate("Acquired", stats.definition.trade),
      MetaData.traitDate("Birthday", stats.definition.birth)
    );
  }

  /// @notice Store a new snack definition
  function _defineSnack(
    uint32 snackId, uint32 duration, uint16 furCost, uint16 hap, uint16 en
  ) internal {
    _snacks[snackId].snackId = snackId;
    _snacks[snackId].duration = duration;
    _snacks[snackId].furCost = furCost;
    _snacks[snackId].happiness = hap;
    _snacks[snackId].energy = en;
    _snacks[snackId].count = 1;
    _snacks[snackId].fed = 0;
  }

  function _lootRarityBoost(uint16 rarity) internal pure returns (uint16) {
    if (rarity == 1) return 5;
    else if (rarity == 2) return 15;
    else if (rarity == 3) return 30;
    return 0;
  }

  /// @notice Gets the FUR boost for a given level
  function _furBoost(uint16 level) internal pure returns (uint16) {
    if (level >= 200) return 581;
    if (level < 25) return (2 * level);
    if (level < 50) return (5000 + (level - 25) * 225) / 100;
    if (level < 75) return (10625 + (level - 50) * 250) / 100;
    if (level < 100) return (16875 + (level - 75) * 275) / 100;
    if (level < 125) return (23750 + (level - 100) * 300) / 100;
    if (level < 150) return (31250 + (level - 125) * 325) / 100;
    if (level < 175) return (39375 + (level - 150) * 350) / 100;
    return (48125 + (level - 175) * 375) / 100;
  }

  /// @notice Unpacks an item, giving its rarity + stat
  function _itemRarityStat(uint128 lootId) internal pure returns (uint8, uint8) {
    return (
      uint8(FurLib.extractBytes(lootId, FurLib.LOOT_BYTE_RARITY, 1)),
      uint8(FurLib.extractBytes(lootId, FurLib.LOOT_BYTE_STAT, 1)));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(ILootEngine).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}