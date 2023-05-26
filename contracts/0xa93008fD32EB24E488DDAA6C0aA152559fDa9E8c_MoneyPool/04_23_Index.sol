// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';
import '../libraries/Math.sol';

library Index {
  using WadRayMath for uint256;
  using Index for DataStruct.ReserveData;

  event LTokenIndexUpdated(address indexed asset, uint256 lTokenIndex, uint256 lastUpdateTimestamp);

  /**
   * @dev Returns the ongoing normalized income for the reserve
   * A value of 1e27 means there is no income. As time passes, the income is accrued
   * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return the normalized income. expressed in ray
   **/
  function getLTokenInterestIndex(DataStruct.ReserveData storage reserve)
    public
    view
    returns (uint256)
  {
    uint256 lastUpdateTimestamp = reserve.lastUpdateTimestamp;

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (lastUpdateTimestamp == block.timestamp) {
      return reserve.lTokenInterestIndex;
    }

    uint256 newIndex = Math
    .calculateLinearInterest(reserve.depositAPY, lastUpdateTimestamp, block.timestamp)
    .rayMul(reserve.lTokenInterestIndex);

    return newIndex;
  }

  /**
   * @dev Updates the reserve indexes and the timestamp
   * @param reserve The reserve to be updated
   **/
  function updateState(DataStruct.ReserveData storage reserve, address asset) internal {
    if (reserve.depositAPY == 0) {
      reserve.lastUpdateTimestamp = block.timestamp;
      return;
    }

    reserve.lTokenInterestIndex = getLTokenInterestIndex(reserve);
    reserve.lastUpdateTimestamp = block.timestamp;

    emit LTokenIndexUpdated(asset, reserve.lTokenInterestIndex, reserve.lastUpdateTimestamp);
  }
}