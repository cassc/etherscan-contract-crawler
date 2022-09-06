// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IFeeRegistry} from '../interfaces/IFeeRegistry.sol';

/**
 * @title InfinityCreatorsFeeRegistry
 */
contract InfinityCreatorsFeeRegistry is IFeeRegistry, Ownable {
  address CREATORS_FEE_MANAGER;
  struct FeeInfo {
    address setter;
    address destination;
    uint16 bps;
  }

  mapping(address => FeeInfo) private _creatorsFeeInfo;

  event CreatorsFeeUpdate(address indexed collection, address indexed setter, address destination, uint16 bps);

  event CreatorsFeeManagerUpdated(address indexed manager);

  /**
   * @notice Update creators fee for collection
   * @param collection address of the NFT contract
   * @param setter address that sets destinations
   * @param destination receiver for the fee
   * @param bps fee (500 = 5%, 1,000 = 10%)
   */
  function registerFeeDestination(
    address collection,
    address setter,
    address destination,
    uint16 bps
  ) external override {
    require(msg.sender == CREATORS_FEE_MANAGER, 'Creators Fee Registry: Only creators fee manager');
    _creatorsFeeInfo[collection] = FeeInfo({setter: setter, destination: destination, bps: bps});
    emit CreatorsFeeUpdate(collection, setter, destination, bps);
  }

  /**
   * @notice View creator fee info for a collection address
   * @param collection collection address
   */
  function getFeeInfo(address collection)
    external
    view
    override
    returns (
      address,
      address,
      uint16
    )
  {
    return (
      _creatorsFeeInfo[collection].setter,
      _creatorsFeeInfo[collection].destination,
      _creatorsFeeInfo[collection].bps
    );
  }

  // ===================================================== ADMIN FUNCTIONS =====================================================

  function updateCreatorsFeeManager(address manager) external onlyOwner {
    CREATORS_FEE_MANAGER = manager;
    emit CreatorsFeeManagerUpdated(manager);
  }
}