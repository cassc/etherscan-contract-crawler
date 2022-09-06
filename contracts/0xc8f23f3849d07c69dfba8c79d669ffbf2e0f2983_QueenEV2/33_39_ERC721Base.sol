// SPDX-License-Identifier: MIT

/// @title A base contract with implementation control

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

//import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC165Storage} from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import {RoyalLibrary} from "../lib/RoyalLibrary.sol";
import {IRoyalContractBase} from "../../interfaces/IRoyalContractBase.sol";
import {IQueenPalace} from "../../interfaces/IQueenPalace.sol";

contract ERC721Base is
  ERC165Storage,
  IRoyalContractBase,
  Pausable,
  ReentrancyGuard,
  Ownable
{
  IQueenPalace internal queenPalace;

  /************************** vCONTROLLER REGION *************************************************** */

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function pause() external virtual onlyOwner whenNotPaused {
    _pause();
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function unpause() external virtual onlyOwner whenPaused {
    _unpause();
  }

  /**
   *IN
   *_queenPalace: address of queen palace contract
   *OUT
   */
  function setQueenPalace(IQueenPalace _queenPalace)
    external
    nonReentrant
    whenPaused
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    _setQueenPalace(_queenPalace);
  }

  /**
   *IN
   *_queenPalace: address of queen palace contract
   *OUT
   */
  function _setQueenPalace(IQueenPalace _queenPalace) internal {
    queenPalace = _queenPalace;
  }

  /************************** ^vCONTROLLER REGION *************************************************** */

  /************************** vMODIFIERS REGION ***************************************************** */
  modifier onlyOwnerOrDeveloperOrDAO() {
    isOwnerOrDeveloperOrDAO();
    _;
  }
  modifier onlyOwnerOrChiefDeveloperOrDAO() {
    isOwnerOrChiefDeveloperOrDAO();
    _;
  }
  modifier onlyOwnerOrArtistOrDAO() {
    isOwnerOrArtistOrDAO();
    _;
  }
  modifier onlyOwnerOrChiefArtistOrDAO() {
    isOwnerOrChiefArtistOrDAO();
    _;
  }
  modifier onlyOnImplementationOrDAO() {
    isOnImplementationOrDAO();
    _;
  }
  modifier onlyOwnerOrDAO() {
    isOwnerOrDAO();
    _;
  }
  modifier onlyOnImplementationOrPaused() {
    isOnImplementationOrPaused();
    _;
  }
  modifier onlyMinter() {
    isMinter();
    _;
  }
  modifier onlyOwnerOrChiefDeveloper() {
    isOwnerOrChiefDeveloper();
    _;
  }

  /************************** ^MODIFIERS REGION ***************************************************** */

  /**
   *IN
   *OUT
   *if given address is owner
   */
  function isOwner(address _address) external view override returns (bool) {
    return owner() == _address;
  }

  function isOwnerOrChiefArtistOrDAO() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == queenPalace.artist() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Artist, DAO"
    );
  }

  function isOwnerOrChiefDeveloperOrDAO() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == queenPalace.developer() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Chief Developer, DAO"
    );
  }

  function isOwnerOrArtistOrDAO() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isArtist(msg.sender) ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Artist, DAO"
    );
  }

  function isOnImplementationOrDAO() internal view {
    require(
      queenPalace.isOnImplementation() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Implementation sender not DAO"
    );
  }

  function isOnImplementationOrPaused() internal view {
    require(
      queenPalace.isOnImplementation() || paused(),
      "Not Implementation,Paused"
    );
  }

  function isOwnerOrDAO() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.daoExecutor(),
      "Not Owner, DAO"
    );
  }

  function isOwnerOrDeveloperOrDAO() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isDeveloper(msg.sender) ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Developer, DAO"
    );
  }

  function isMinter() internal view {
    require(msg.sender == queenPalace.minter(), "Not Minter");
  }

  function isOwnerOrChiefDeveloper() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.developer(),
      "Not Owner, Chief Developer"
    );
  }
}