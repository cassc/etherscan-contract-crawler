// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Furballs.sol";
import "./editions/IFurballEdition.sol";
import "./utils/FurProxy.sol";

/// @title Fur
/// @author LFG Gaming LLC
/// @notice Utility token for in-game rewards in Furballs
contract Fur is ERC20, FurProxy {
  // n.b., this contract has some unusual tight-coupling between FUR and Furballs
  // Simple reason: this contract had more space, and is the only other allowed to know about ownership
  // Thus it serves as a sort of shop meta-store for Furballs

  // tokenId => mapping of fed _snacks
  mapping(uint256 => FurLib.Snack[]) public _snacks;

  // Internal cache for speed.
  uint256 private _intervalDuration;

  constructor(address furballsAddress) FurProxy(furballsAddress) ERC20("Fur", "FUR") {
    _intervalDuration = furballs.intervalDuration();
  }

  // -----------------------------------------------------------------------------------------------
  // Public
  // -----------------------------------------------------------------------------------------------

  /// @notice Returns the snacks currently applied to a Furball
  function snacks(uint256 tokenId) external view returns(FurLib.Snack[] memory) {
    return _snacks[tokenId];
  }

  /// @notice Write-function to cleanup the snacks for a token (remove expired)
  function cleanSnacks(uint256 tokenId) public returns (uint256) {
    if (_snacks[tokenId].length == 0) return 0;
    return _cleanSnack(tokenId, 0);
  }

  /// @notice The public accessor calculates the snack boosts
  function snackEffects(uint256 tokenId) external view returns(uint256) {
    uint16 hap = 0;
    uint16 en = 0;

    for (uint32 i=0; i<_snacks[tokenId].length && i <= FurLib.Max32; i++) {
      uint256 remaining = _snackTimeRemaning(_snacks[tokenId][i]);
      if (remaining > 0) {
        hap += _snacks[tokenId][i].happiness;
        en += _snacks[tokenId][i].energy;
      }
    }

    return (hap * 0x10000) + (en);
  }

  // -----------------------------------------------------------------------------------------------
  // GameAdmin
  // -----------------------------------------------------------------------------------------------

  /// @notice FUR can only be minted by furballs doing battle.
  function earn(address addr, uint256 amount) external gameAdmin {
    if (amount == 0) return;
    _mint(addr, amount);
  }

  /// @notice FUR can be spent by Furballs, or by the LootEngine (shopping, in the future)
  function spend(address addr, uint256 amount) external gameAdmin {
    _burn(addr, amount);
  }

  /// @notice Pay any necessary fees to mint a furball
  /// @dev Delegated logic from Furballs;
  function purchaseMint(
    address from, uint8 permissions, address to, IFurballEdition edition
  ) external gameAdmin returns (bool) {
    require(edition.maxMintable(to) > 0, "LIVE");
    uint32 cnt = edition.count();

    uint32 adoptable = edition.maxAdoptable();
    bool requiresPurchase = cnt >= adoptable;

    if (requiresPurchase) {
      // _gift will throw if cannot gift or cannot afford cost
      _gift(from, permissions, to, edition.purchaseFur());
    }
    return requiresPurchase;
  }

  /// @notice Attempts to purchase an upgrade for a loot item
  /// @dev Delegated logic from Furballs
  function purchaseUpgrade(
    FurLib.RewardModifiers memory modifiers,
    address from, uint8 permissions, uint256 tokenId, uint128 lootId, uint8 chances
  ) external gameAdmin returns(uint128) {
    address owner = furballs.ownerOf(tokenId);

    // _gift will throw if cannot gift or cannot afford cost
    _gift(from, permissions, owner, 500 * uint256(chances));

    return furballs.engine().upgradeLoot(modifiers, owner, lootId, chances);
  }

  /// @notice Attempts to purchase a snack using templates found in the engine
  /// @dev Delegated logic from Furballs
  function purchaseSnack(
    address from, uint8 permissions, uint256 tokenId, uint32 snackId, uint16 count
  ) external gameAdmin {
    FurLib.Snack memory snack = furballs.engine().getSnack(snackId);
    require(snack.count > 0, "COUNT");
    require(snack.fed == 0, "FED");

    // _gift will throw if cannot gift or cannot afford costQ
    _gift(from, permissions, furballs.ownerOf(tokenId), snack.furCost * count);

    uint256 snackData = _cleanSnack(tokenId, snack.snackId);
    uint32 existingSnackNumber = uint32(snackData / 0x100000000);
    snack.count *= count;
    if (existingSnackNumber > 0) {
      // Adding count effectively adds duration to the active snack
      _snacks[tokenId][existingSnackNumber - 1].count += snack.count;
    } else {
      // A new snack just gets pushed onto the array
      snack.fed = uint64(block.timestamp);
      _snacks[tokenId].push(snack);
    }
  }

  // -----------------------------------------------------------------------------------------------
  // Internal
  // -----------------------------------------------------------------------------------------------

  /// @notice Both removes inactive _snacks from a token and searches for a specific snack Id index
  /// @dev Both at once saves some size & ensures that the _snacks are frequently cleaned.
  /// @return The index+1 of the existing snack
  function _cleanSnack(uint256 tokenId, uint32 snackId) internal returns(uint256) {
    uint32 ret = 0;
    uint16 hap = 0;
    uint16 en = 0;
    for (uint32 i=1; i<=_snacks[tokenId].length && i <= FurLib.Max32; i++) {
      FurLib.Snack memory snack = _snacks[tokenId][i-1];
      // Has the snack transitioned from active to inactive?
      if (_snackTimeRemaning(snack) == 0) {
        if (_snacks[tokenId].length > 1) {
          _snacks[tokenId][i-1] = _snacks[tokenId][_snacks[tokenId].length - 1];
        }
        _snacks[tokenId].pop();
        i--; // Repeat this idx
        continue;
      }
      hap += snack.happiness;
      en += snack.energy;
      if (snackId != 0 && snack.snackId == snackId) {
        ret = i;
      }
    }
    return (ret * 0x100000000) + (hap * 0x10000) + (en);
  }

  /// @notice Check if the snack is active; returns 0 if inactive, otherwise the duration
  function _snackTimeRemaning(FurLib.Snack memory snack) internal view returns(uint256) {
    if (snack.fed == 0) return 0;
    uint256 expiresAt = uint256(snack.fed + (snack.count * snack.duration * _intervalDuration));
    return expiresAt <= block.timestamp ? 0 : (expiresAt - block.timestamp);
  }

  /// @notice Enforces (requires) only admins/game may give gifts
  /// @param to Whom is this being sent to?
  /// @return If this is a gift or not.
  function _gift(address from, uint8 permissions, address to, uint256 furCost) internal returns(bool) {
    bool isGift = to != from;

    // Only admins or game engine can send gifts (to != self), which are always free.
    require(!isGift || permissions >= FurLib.PERMISSION_ADMIN, "GIFT");

    if (!isGift && furCost > 0) {
      _burn(from, furCost);
    }

    return isGift;
  }
}