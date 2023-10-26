// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {WadRayMath} from 'aave-v3-core/contracts/protocol/libraries/math/WadRayMath.sol';
import {IAaveV3ConfigEngine as IEngine} from './IAaveV3ConfigEngine.sol';
import {IV3RateStrategyFactory as Rates} from './IV3RateStrategyFactory.sol';
import {EngineFlags} from './EngineFlags.sol';

/**
 * @dev Base smart contract for an Aave v3.0.1 configs update.
 * - Assumes this contract has the right permissions
 * - Connected to a IAaveV3ConfigEngine engine contact, which abstract the complexities of
 *   interaction with the Aave protocol.
 * - At the moment covering:
 *   - Listings of new assets on the pool.
 *   - Updates of caps (supply cap, borrow cap).
 *   - Updates of price feeds
 *   - Updates of interest rate strategies.
 *   - Updates of borrow parameters (flashloanable, stableRateModeEnabled, borrowableInIsolation, withSiloedBorrowing, reserveFactor)
 *   - Updates of collateral parameters (ltv, liq threshold, liq bonus, liq protocol fee, debt ceiling)
 * @author BGD Labs
 */
abstract contract AaveV3PayloadBase {
  using Address for address;

  IEngine public immutable LISTING_ENGINE;

  constructor(IEngine engine) {
    LISTING_ENGINE = engine;
  }

  /// @dev to be overriden on the child if any extra logic is needed pre-listing
  function _preExecute() internal virtual {}

  /// @dev to be overriden on the child if any extra logic is needed post-listing
  function _postExecute() internal virtual {}

  function execute() external {
    _preExecute();

    IEngine.Listing[] memory listings = newListings();
    IEngine.ListingWithCustomImpl[] memory listingsCustom = newListingsCustom();
    IEngine.CapsUpdate[] memory caps = capsUpdates();
    IEngine.CollateralUpdate[] memory collaterals = collateralsUpdates();
    IEngine.BorrowUpdate[] memory borrows = borrowsUpdates();
    IEngine.PriceFeedUpdate[] memory priceFeeds = priceFeedsUpdates();
    IEngine.RateStrategyUpdate[] memory rates = rateStrategiesUpdates();

    if (listings.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.listAssets.selector, getPoolContext(), listings)
      );
    }

    if (listingsCustom.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(
          LISTING_ENGINE.listAssetsCustom.selector,
          getPoolContext(),
          listingsCustom
        )
      );
    }

    if (borrows.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.updateBorrowSide.selector, borrows)
      );
    }

    if (collaterals.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.updateCollateralSide.selector, collaterals)
      );
    }

    if (rates.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.updateRateStrategies.selector, rates)
      );
    }

    if (priceFeeds.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.updatePriceFeeds.selector, priceFeeds)
      );
    }

    if (caps.length != 0) {
      address(LISTING_ENGINE).functionDelegateCall(
        abi.encodeWithSelector(LISTING_ENGINE.updateCaps.selector, caps)
      );
    }

    _postExecute();
  }

  /** @dev Converts basis points to RAY units
   * e.g. 10_00 (10.00%) will return 100000000000000000000000000
   */
  function _bpsToRay(uint256 amount) internal pure returns (uint256) {
    return (amount * WadRayMath.RAY) / 10_000;
  }

  /// @dev to be defined in the child with a list of new assets to list
  function newListings() public view virtual returns (IEngine.Listing[] memory) {}

  /// @dev to be defined in the child with a list of new assets to list (with custom a/v/s tokens implementations)
  function newListingsCustom()
    public
    view
    virtual
    returns (IEngine.ListingWithCustomImpl[] memory)
  {}

  /// @dev to be defined in the child with a list of caps to update
  function capsUpdates() public view virtual returns (IEngine.CapsUpdate[] memory) {}

  /// @dev to be defined in the child with a list of collaterals' params to update
  function collateralsUpdates() public view virtual returns (IEngine.CollateralUpdate[] memory) {}

  /// @dev to be defined in the child with a list of borrows' params to update
  function borrowsUpdates() public view virtual returns (IEngine.BorrowUpdate[] memory) {}

  /// @dev to be defined in the child with a list of priceFeeds to update
  function priceFeedsUpdates() public view virtual returns (IEngine.PriceFeedUpdate[] memory) {}

  /// @dev to be defined in the child with a list of set of parameters of rate strategies
  function rateStrategiesUpdates()
    public
    view
    virtual
    returns (IEngine.RateStrategyUpdate[] memory)
  {}

  /// @dev the lack of support for immutable strings kinds of forces for this
  /// Besides that, it can actually be useful being able to change the naming, but remote
  function getPoolContext() public view virtual returns (IEngine.PoolContext memory);
}