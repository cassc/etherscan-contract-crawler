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

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ERC165StorageUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

import {RoyalLibrary} from "../lib/RoyalLibrary.sol";
import {IBaseContractControllerUpgradeable} from "../../interfaces/IBaseContractControllerUpgradeable.sol";
import {IQueenPalace} from "../../interfaces/IQueenPalace.sol";

contract BaseContractControllerUpgradeable is
  ERC165StorageUpgradeable,
  IBaseContractControllerUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable
{
  IQueenPalace internal queenPalace;
  bool internal initialized;

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

  function isInitialized() public view returns (bool) {
    return initialized;
  }

  function QueenPalace() public view returns (IQueenPalace) {
    return queenPalace;
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

  modifier onlyChiefArtist() {
    isChiefArtist();
    _;
  }
  modifier onlyArtist() {
    isArtist();
    _;
  }

  modifier onlyChiefDeveloper() {
    isChiefDeveloper();
    _;
  }

  modifier onlyDeveloper() {
    isDeveloper();
    _;
  }

  modifier onlyMinter() {
    isMinter();
    _;
  }

  modifier onlyActor() {
    isActor();
    _;
  }

  modifier onlyActorOrDAO() {
    isActorOrDAO();
    _;
  }

  modifier onlyOwnerOrChiefArtist() {
    isOwnerOrChiefArtist();
    _;
  }

  modifier onlyOwnerOrArtist() {
    isOwnerOrArtist();
    _;
  }

  modifier onlyOwnerOrChiefDeveloper() {
    isOwnerOrChiefDeveloper();
    _;
  }

  modifier onlyOwnerOrDeveloper() {
    isOwnerOrDeveloper();
    _;
  }
  modifier onlyOwnerOrChiefDeveloperOrDAO() {
    isOwnerOrChiefDeveloperOrDAO();
    _;
  }

  modifier onlyOwnerOrDeveloperOrDAO() {
    isOwnerOrDeveloperOrDAO();
    _;
  }

  modifier onlyOwnerOrChiefArtistOrDAO() {
    isOwnerOrChiefArtistOrDAO();
    _;
  }

  modifier onlyOwnerOrArtistOrDAO() {
    isOwnerOrArtistOrDAO();
    _;
  }
  modifier onlyOwnerOrDAO() {
    isOwnerOrDAO();
    _;
  }

  modifier onlyOwnerOrMinter() {
    isOwnerOrMinter();
    _;
  }

  modifier onlyOwnerOrAuctionHouse() {
    isOwnerOrAuctionHouse();
    _;
  }

  modifier onlyOwnerOrAuctionHouseProxy() {
    isOwnerOrAuctionHouseProxy();
    _;
  }

  modifier onlyOwnerOrQueenPalace() {
    isOwnerOrQueenPalace();
    _;
  }

  modifier onlyOnImplementationOrDAO() {
    isOnImplementationOrDAO();
    _;
  }

  modifier onlyOnImplementationOrPaused() {
    isOnImplementationOrPaused();
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

  function isChiefArtist() internal view {
    require(msg.sender == queenPalace.artist(), "Not Chief Artist");
  }

  function isArtist() internal view {
    require(queenPalace.isArtist(msg.sender), "Not Artist");
  }

  function isChiefDeveloper() internal view {
    require(msg.sender == queenPalace.developer(), "Not Chief Dev");
  }

  function isDeveloper() internal view {
    require(queenPalace.isDeveloper(msg.sender), "Not Dev");
  }

  function isMinter() internal view {
    require(msg.sender == queenPalace.minter(), "Not Minter");
  }

  function isActor() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isArtist(msg.sender) ||
        queenPalace.isDeveloper(msg.sender),
      "Invalid Actor"
    );
  }

  function isActorOrDAO() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isArtist(msg.sender) ||
        queenPalace.isDeveloper(msg.sender) ||
        msg.sender == queenPalace.daoExecutor(),
      "Invalid Actor, DAO"
    );
  }

  function isOwnerOrChiefArtist() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.artist(),
      "Not Owner, Chief Artist"
    );
  }

  function isOwnerOrArtist() internal view {
    require(
      msg.sender == owner() || queenPalace.isArtist(msg.sender),
      "Not Owner, Artist"
    );
  }

  function isOwnerOrChiefDeveloper() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.developer(),
      "Not Owner, Chief Developer"
    );
  }

  function isOwnerOrDeveloper() internal view {
    require(
      msg.sender == owner() || queenPalace.isDeveloper(msg.sender),
      "Not Owner, Developer"
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

  function isOwnerOrDeveloperOrDAO() internal view {
    require(
      msg.sender == owner() ||
        queenPalace.isDeveloper(msg.sender) ||
        msg.sender == queenPalace.daoExecutor(),
      "Not Owner, Developer, DAO"
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

  function isOwnerOrDAO() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.daoExecutor(),
      "Not Owner, DAO"
    );
  }

  function isOwnerOrMinter() internal view {
    require(
      msg.sender == owner() || msg.sender == queenPalace.minter(),
      "Not Owner, Minter"
    );
  }

  function isOwnerOrAuctionHouse() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == address(queenPalace.QueenAuctionHouse()),
      "Not Owner, Auction House"
    );
  }

  function isOwnerOrAuctionHouseProxy() internal view {
    require(
      msg.sender == owner() ||
        msg.sender == address(queenPalace.QueenAuctionHouseProxyAddr()),
      "Not Owner, Auction House"
    );
  }

  function isOwnerOrQueenPalace() internal view {
    require(
      msg.sender == owner() || msg.sender == address(queenPalace),
      "Not Owner,Queen Palace"
    );
  }

  function isOnImplementationOrDAO() internal view {
    require(
      queenPalace.isOnImplementation() ||
        msg.sender == queenPalace.daoExecutor(),
      "Not On Implementation sender not DAO"
    );
  }

  function isOnImplementationOrPaused() internal view {
    require(
      queenPalace.isOnImplementation() || paused(),
      "Not On Implementation,Paused"
    );
  }
}