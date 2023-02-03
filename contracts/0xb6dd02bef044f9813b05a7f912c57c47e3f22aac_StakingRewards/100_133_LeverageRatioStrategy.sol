// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";

abstract contract LeverageRatioStrategy is BaseUpgradeablePausable, ISeniorPoolStrategy {
  uint256 internal constant LEVERAGE_RATIO_DECIMALS = 1e18;

  /// @inheritdoc ISeniorPoolStrategy
  function invest(ISeniorPool, ITranchedPool pool) public view override returns (uint256) {
    uint256 nSlices = pool.numSlices();
    // If the pool has no slices, we cant invest
    if (nSlices == 0) {
      return 0;
    }
    uint256 sliceIndex = nSlices.sub(1);
    (
      ITranchedPool.TrancheInfo memory juniorTranche,
      ITranchedPool.TrancheInfo memory seniorTranche
    ) = _getTranchesInSlice(pool, sliceIndex);
    // If junior capital is not yet invested, or pool already locked, then don't invest anything.
    if (juniorTranche.lockedUntil == 0 || seniorTranche.lockedUntil > 0) {
      return 0;
    }

    return _invest(pool, juniorTranche, seniorTranche);
  }

  /// @inheritdoc ISeniorPoolStrategy
  function estimateInvestment(
    ISeniorPool,
    ITranchedPool pool
  ) public view override returns (uint256) {
    uint256 nSlices = pool.numSlices();
    // If the pool has no slices, we cant invest
    if (nSlices == 0) {
      return 0;
    }
    uint256 sliceIndex = nSlices.sub(1);
    (
      ITranchedPool.TrancheInfo memory juniorTranche,
      ITranchedPool.TrancheInfo memory seniorTranche
    ) = _getTranchesInSlice(pool, sliceIndex);

    return _invest(pool, juniorTranche, seniorTranche);
  }

  function _invest(
    ITranchedPool pool,
    ITranchedPool.TrancheInfo memory juniorTranche,
    ITranchedPool.TrancheInfo memory seniorTranche
  ) internal view returns (uint256) {
    uint256 juniorCapital = juniorTranche.principalDeposited;
    uint256 existingSeniorCapital = seniorTranche.principalDeposited;
    uint256 seniorTarget = juniorCapital.mul(getLeverageRatio(pool)).div(LEVERAGE_RATIO_DECIMALS);
    if (existingSeniorCapital >= seniorTarget) {
      return 0;
    }

    return seniorTarget.sub(existingSeniorCapital);
  }

  /// @notice Return the junior and senior tranches from a given pool in a specified slice
  /// @param pool pool to fetch tranches from
  /// @param sliceIndex slice index to fetch tranches from
  /// @return (juniorTranche, seniorTranche)
  function _getTranchesInSlice(
    ITranchedPool pool,
    uint256 sliceIndex
  )
    internal
    view
    returns (
      ITranchedPool.TrancheInfo memory, // junior tranche
      ITranchedPool.TrancheInfo memory // senior tranche
    )
  {
    uint256 juniorTrancheId = _sliceIndexToJuniorTrancheId(sliceIndex);
    uint256 seniorTrancheId = _sliceIndexToSeniorTrancheId(sliceIndex);

    ITranchedPool.TrancheInfo memory juniorTranche = pool.getTranche(juniorTrancheId);
    ITranchedPool.TrancheInfo memory seniorTranche = pool.getTranche(seniorTrancheId);
    return (juniorTranche, seniorTranche);
  }

  /// @notice Returns the junior tranche id for the given slice index
  /// @param index slice index
  /// @return junior tranche id of given slice index
  function _sliceIndexToJuniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.mul(2).add(2);
  }

  /// @notice Returns the senion tranche id for the given slice index
  /// @param index slice index
  /// @return senior tranche id of given slice index
  function _sliceIndexToSeniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.mul(2).add(1);
  }
}