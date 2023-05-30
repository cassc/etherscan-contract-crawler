// SPDX-License-Identifier: MIT

/// @title ERC721 Voters Extension

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";

import {RoyalLibrary} from "../lib/RoyalLibrary.sol";
import {IQueenLab} from "../../interfaces/IQueenLab.sol";
import {ERC721Enumerable} from "../base/ERC721Enumerable.sol";
import {ERC721} from "../base/ERC721.sol";
import {IERC721} from "../../interfaces/IERC721.sol";

//extends openzeppelin draft-ERC721Votes.sol
//
/**
 * @dev This implements an extension to the QueenE {ERC721} contract to manage Common and Lord Houses
 * and the voters historic.
 */
abstract contract QueenParliamentV2 is ERC721Enumerable, Votes {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  event NominatedForHouseOfLord(address indexed lord, uint256 queeneId);
  event NominatedForHouseOfCommons(address indexed common, uint256 queeneId);
  event BannedFromHouses(address indexed subject);

  event ParliamentEndOfMandate(
    address indexed subject,
    uint256 queeneId,
    string house
  );

  event SirNominated(address indexed subject);

  event ParliamentPromoted(address indexed subject);

  address public royalMuseum;

  EnumerableSet.AddressSet internal houseOfLords;
  EnumerableSet.AddressSet internal houseOfCommons;
  EnumerableSet.AddressSet internal houseOfBanned;
  RoyalLibrary.sSIR[] internal sirs;
  // QueenEs
  mapping(uint256 => RoyalLibrary.sQUEEN) internal queenes;
  mapping(uint256 => bool) internal dnaMapping;
  mapping(uint256 => RoyalLibrary.queeneRarity) internal queeneRarityMap;
  mapping(address => EnumerableSet.UintSet) internal ownerOfQueenEs;

  /// @notice Defines decimals as per ERC-20 convention to make integrations with 3rd party governance platforms easier
  uint8 public constant decimals = 0;

  bool internal houseOfLordsFull;

  /**
   * @dev return if exists sir with pending reward.
   *
   */
  function _haveSirWithPendingReward() internal view returns (bool) {
    for (uint256 idx; idx < sirs.length; idx++) {
      if (
        sirs[idx].queene == 0 && !houseOfBanned.contains(sirs[idx].sirAddress)
      ) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev return sir with pending reward.
   *
   */
  function _getSirWithPendingAward(uint256 _queeneId)
    internal
    view
    returns (address)
  {
    uint256 sirsPending;
    uint256 nextIdx;
    for (uint256 idx = 0; idx < sirs.length; idx++) {
      if (
        sirs[idx].queene == 0 && !houseOfBanned.contains(sirs[idx].sirAddress)
      ) {
        sirsPending++;
      }
    }

    address[] memory sirsToBeWarded = new address[](sirsPending);

    for (uint256 idx = 0; idx < sirs.length; idx++) {
      if (
        sirs[idx].queene == 0 && !houseOfBanned.contains(sirs[idx].sirAddress)
      ) {
        sirsToBeWarded[nextIdx++] = sirs[idx].sirAddress;
      }
    }

    if (sirsToBeWarded.length == 1) {
      return sirsToBeWarded[0];
    } else if (sirsToBeWarded.length > 1) {
      return
        sirsToBeWarded[
          uint256(
            keccak256(
              abi.encodePacked(
                blockhash(block.number - 1),
                _queeneId,
                blockhash(block.difficulty),
                blockhash(block.timestamp)
              )
            )
          ) % sirsToBeWarded.length
        ];
    }

    return address(0);
  }

  /**
   * @dev give new QueenE owner a seat in one house.
   *
   * Emits a {NominatedForHouseOfLord} or {NominatedForHouseOfCommons} event.
   * Emits a {BannedFromHousesRejection} event if subject was banned.
   */
  function _giveParliamentSeat(address to, uint256 queeneId)
    internal
    returns (bool)
  {
    if (to == address(0)) return true; //burn address dont get seats

    if (to == royalMuseum || to == queenPalace.minter()) return true; //museum and minter dont get seats

    if (IsSir(to) && queenes[queeneId].sirAward == 1) return true; //sir dont get vote from sir award

    if (houseOfBanned.contains(to)) {
      return true; //seat must be vacant anyways
    }

    if (
      queeneRarityMap[queeneId] > RoyalLibrary.queeneRarity.COMMON ||
      queenes[queeneId].queenesGallery == 1 ||
      !houseOfLordsFull
    ) {
      //give lord seat
      if (houseOfLords.contains(to)) return true; //already have seat

      if (!houseOfCommons.contains(to)) houseOfCommons.remove(to);

      houseOfLords.add(to);
      emit NominatedForHouseOfLord(to, queeneId);
      //update if house  of lords is full
      if (!houseOfLordsFull) houseOfLordsFull = houseOfLords.length() >= 15;
    } else {
      if (houseOfLords.contains(to) || houseOfCommons.contains(to)) return true; //already have a seat

      houseOfCommons.add(to);

      emit NominatedForHouseOfCommons(to, queeneId);
    }

    return true;
  }

  /**
   * @dev take seat from QueenE previous owner.
   *
   * Emits a {ParliamentEndOfMandate} event if ends with no seats.
   */
  function _takeParliamentSeat(address from, uint256 tokenId)
    internal
    returns (bool seatTaken)
  {
    if (!houseOfLords.contains(from) && !houseOfCommons.contains(from))
      return true; //have no seat to take

    if (balanceOf(from) <= 0) {
      if (houseOfLords.contains(from)) houseOfLords.remove(from);
      if (houseOfCommons.contains(from)) houseOfCommons.remove(from);

      emit ParliamentEndOfMandate(from, tokenId, "ALL");

      return true;
    }
    //if have no rare queenE, cant stay in House of Lords
    bool haveRareQueene;
    for (uint256 idx = 0; idx < ownerOfQueenEs[from].length(); idx++) {
      if (
        queeneRarityMap[ownerOfQueenEs[from].at(idx)] >
        RoyalLibrary.queeneRarity.COMMON ||
        queenes[ownerOfQueenEs[from].at(idx)].queenesGallery == 1
      ) {
        haveRareQueene = true;
      }
    }

    if (!haveRareQueene && houseOfLords.contains(from)) {
      houseOfLords.remove(from);
      houseOfCommons.add(from);
    }
    return true;
  }

  /**
   * @dev ban subject from houses.
   *
   */
  function banFromHouses(address _subject)
    external
    whenNotPaused
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    if (!houseOfBanned.contains(_subject)) houseOfBanned.add(_subject);
    if (houseOfLords.contains(_subject)) houseOfLords.remove(_subject);
    if (houseOfCommons.contains(_subject)) houseOfCommons.remove(_subject);

    if (getVotes(_subject) > 0)
      _transferVotingUnits(_subject, address(0), getVotes(_subject));

    emit BannedFromHouses(_subject);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Adjusts votes when tokens are transferred.
   *
   * Emits a {Votes-DelegateVotesChanged} event.
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    //get queenE voting power
    uint8 queenVotingPower = ((queeneRarityMap[tokenId] >
      RoyalLibrary.queeneRarity.COMMON) || queenes[tokenId].queenesGallery == 1)
      ? 2
      : 1;
    //move Queen Weight from to
    uint256 fromVotesToTake = queenVotingPower;
    uint256 toVotesToGive = queenVotingPower;
    //if to special address or banned, give no votes
    if (
      to == royalMuseum ||
      to == queenPalace.minter() ||
      (queenes[tokenId].sirAward == 1 && IsSir(to)) ||
      houseOfBanned.contains(to)
    ) {
      toVotesToGive = 0;
    }
    //if from special address or banned, no votes to take
    if (
      from == royalMuseum ||
      from == queenPalace.minter() ||
      (queenes[tokenId].sirAward == 1 && IsSir(from)) ||
      houseOfBanned.contains(from)
    ) {
      fromVotesToTake = 0;
    }

    if (fromVotesToTake > 0)
      _transferVotingUnits(from, address(0), fromVotesToTake);

    if (toVotesToGive > 0) _transferVotingUnits(address(0), to, toVotesToGive);

    //change owner
    if (ownerOfQueenEs[from].contains(tokenId))
      ownerOfQueenEs[from].remove(tokenId);

    if (!ownerOfQueenEs[to].contains(tokenId)) ownerOfQueenEs[to].add(tokenId);

    //now we make the throne dance
    //first lets take the seat from the old owner, if necessary
    if (!_takeParliamentSeat(from, tokenId)) {
      revert("tkseat");
    }

    //now lets give a seat to the new owner, if he deserves it
    if (!_giveParliamentSeat(to, tokenId)) {
      revert("gvseat");
    }
    super._afterTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Returns the balance of `account`.
   */
  function _getVotingUnits(address account)
    internal
    view
    virtual
    override
    returns (uint256)
  {
    return getVotes(account);
  }

  /**
   * @dev override from ERC721.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721) {
    if (to != address(0) && delegates(to) == address(0)) _delegate(to, to);
    super.transferFrom(from, to, tokenId);
  }

  /**
   *  Return if given address have Sir Title
   *
   */
  function IsSir(address _address) public view virtual returns (bool) {
    for (uint256 idx; idx < sirs.length; idx++) {
      if (
        sirs[idx].sirAddress == _address &&
        !houseOfBanned.contains(sirs[idx].sirAddress)
      ) {
        return true;
      }
    }
    return false;
  }

  /**
   *  Return sir object index for given address
   *
   */
  function getSirIdx(address _address) internal view returns (uint256) {
    for (uint256 idx; idx < sirs.length; idx++) {
      if (sirs[idx].sirAddress == _address) {
        return idx;
      }
    }
    return 0;
  }
}