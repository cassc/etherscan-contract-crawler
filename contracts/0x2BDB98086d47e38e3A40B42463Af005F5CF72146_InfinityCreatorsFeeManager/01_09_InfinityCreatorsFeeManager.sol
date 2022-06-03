// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IERC165, IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';
import {IFeeManager} from '../interfaces/IFeeManager.sol';
import {IOwnable} from '../interfaces/IOwnable.sol';
import {IFeeRegistry} from '../interfaces/IFeeRegistry.sol';

/**
 * @title InfinityCreatorsFeeManager
 * @notice handles creator fees aka royalties
 */
contract InfinityCreatorsFeeManager is IFeeManager, Ownable {
  uint16 public MAX_CREATOR_FEE_BPS = 250;
  address public immutable CREATORS_FEE_REGISTRY;

  event NewMaxBPS(uint16 newBps);

  /**
   * @notice Constructor
   */
  constructor(address _creatorsFeeRegistry) {
    CREATORS_FEE_REGISTRY = _creatorsFeeRegistry;
  }

  /**
   * @notice Calculate creator fees and get recipients
   * @param collection address of the NFT contract
   * @param amount sale amount
   */
  function calcFeesAndGetRecipient(
    address,
    address collection,
    uint256 amount
  ) external view override returns (address, uint256) {
    // check if the creators fee is registered
    (, address recipient, , uint256 fee) = _getCreatorsFeeInfo(collection, amount);
    return (recipient, fee);
  }

  /**
   * @notice supports creator fee (royalty) sharing for a collection via self service of
   * owner/admin of collection or by owner of this contract
   * @param collection collection address
   * @param feeDestination fee destination
   * @param bps fee bps
   */
  function setupCollectionForCreatorFeeShare(
    address collection,
    address feeDestination,
    uint16 bps
  ) external {
    bytes4 INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 INTERFACE_ID_ERC1155 = 0xd9b67a26;
    require(
      (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
        IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
      'Collection is not ERC721/ERC1155'
    );

    // see if collection has admin
    address collAdmin;
    try IOwnable(collection).owner() returns (address _owner) {
      collAdmin = _owner;
    } catch {
      try IOwnable(collection).admin() returns (address _admin) {
        collAdmin = _admin;
      } catch {
        collAdmin = address(0);
      }
    }

    require(msg.sender == owner() || msg.sender == collAdmin, 'unauthorized');
    require(bps <= MAX_CREATOR_FEE_BPS, 'bps too high');

    // setup
    IFeeRegistry(CREATORS_FEE_REGISTRY).registerFeeDestination(collection, msg.sender, feeDestination, bps);
  }

  // ============================================== INTERNAL FUNCTIONS ==============================================

  function _getCreatorsFeeInfo(address collection, uint256 amount)
    internal
    view
    returns (
      address,
      address,
      uint16,
      uint256
    )
  {
    (address setter, address destination, uint16 bps) = IFeeRegistry(CREATORS_FEE_REGISTRY).getFeeInfo(collection);
    return (setter, destination, bps, (bps * amount) / 10000);
  }

  // ============================================== VIEW FUNCTIONS ==============================================

  function getCreatorsFeeInfo(address collection, uint256 amount)
    external
    view
    returns (
      address,
      address,
      uint16,
      uint256
    )
  {
    return _getCreatorsFeeInfo(collection, amount);
  }

  // ===================================================== ADMIN FUNCTIONS =====================================================

  function setMaxCreatorFeeBps(uint16 _maxBps) external onlyOwner {
    MAX_CREATOR_FEE_BPS = _maxBps;
    emit NewMaxBPS(_maxBps);
  }
}