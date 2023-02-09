// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {IGenericV3ListingEngine} from './IGenericV3ListingEngine.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 listing.
 * - Assumes this contract has the right permissions
 * - Connected to a IGenericV3ListingEngine, handling the internals of the listing
 *   and exposing a simple interface
 * @author BGD Labs
 */
abstract contract AaveV3ListingBase {
  using Address for address;

  IGenericV3ListingEngine public immutable LISTING_ENGINE;

  constructor(IGenericV3ListingEngine listingEngine) {
    LISTING_ENGINE = listingEngine;
  }

  /// @dev to be overriden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overriden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    address(LISTING_ENGINE).functionDelegateCall(
      abi.encodeWithSelector(LISTING_ENGINE.listAssets.selector, getPoolContext(), getAllConfigs())
    );

    _postExecute();
  }

  /// @dev to be defined in the child with the specific listing config
  function getAllConfigs() public virtual returns (IGenericV3ListingEngine.Listing[] memory);

  /// @dev the lack of support for immutable strings kinds of forces for this
  /// Besides that, it can actually be useful being able to change the naming, but remote
  function getPoolContext() public virtual returns (IGenericV3ListingEngine.PoolContext memory);
}