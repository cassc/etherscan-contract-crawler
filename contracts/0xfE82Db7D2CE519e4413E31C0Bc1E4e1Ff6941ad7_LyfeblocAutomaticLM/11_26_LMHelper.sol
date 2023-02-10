// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './IBasePositionManager.sol';
import './IPoolStorage.sol';
import {MathConstants as C} from './MathConstants.sol';
import {FullMath} from './FullMath.sol';
import {ReinvestmentMath} from './ReinvestmentMath.sol';

abstract contract LMHelper {
  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) public view returns (bool) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IBasePositionManager(nftContract).addressToPoolId(pAddress) == pData.poolId;
  }

  /**
   * @dev Get fee
   * use virtual to be overrided to mock data for fuzz tests
   */
  function getFee(address nftContract, uint256 nftId) public view virtual returns (uint256) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return pData.feeGrowthInsideLast;
  }

  /**
   * @dev Get fee
   * use virtual to be overrided to mock data for fuzz tests
   *
   */
  function getFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) public view virtual returns (uint256 feeGrowthInside) {
    IBasePositionManager.Position memory position = _getPositionFromNFT(nftContract, nftId);
    (, , uint256 lowerValue, ) = IPoolStorage(poolAddress).ticks(position.tickLower);
    (, , uint256 upperValue, ) = IPoolStorage(poolAddress).ticks(position.tickUpper);
    (, int24 currentTick, , ) = IPoolStorage(poolAddress).getPoolState();
    uint256 feeGrowthGlobal = IPoolStorage(poolAddress).getFeeGrowthGlobal();

    {
      (uint128 baseL, uint128 reinvestL, uint128 reinvestLLast) = IPoolStorage(poolAddress)
        .getLiquidityState();
      uint256 rTotalSupply = IERC20(poolAddress).totalSupply();
      // logic ported from Pool._syncFeeGrowth()
      uint256 rMintQty = ReinvestmentMath.calcrMintQty(
        uint256(reinvestL),
        uint256(reinvestLLast),
        baseL,
        rTotalSupply
      );

      if (rMintQty != 0) {
        // fetch governmentFeeUnits
        (, uint24 governmentFeeUnits) = IPoolStorage(poolAddress).factory().feeConfiguration();
        unchecked {
          if (governmentFeeUnits != 0) {
            uint256 rGovtQty = (rMintQty * governmentFeeUnits) / C.FEE_UNITS;
            rMintQty -= rGovtQty;
          }
          feeGrowthGlobal += FullMath.mulDivFloor(rMintQty, C.TWO_POW_96, baseL);
        }
      }
    }
    unchecked {
      if (currentTick < position.tickLower) {
        feeGrowthInside = lowerValue - upperValue;
      } else if (currentTick >= position.tickUpper) {
        feeGrowthInside = upperValue - lowerValue;
      } else {
        feeGrowthInside = feeGrowthGlobal - (lowerValue + upperValue);
      }
    }
  }

  /// @dev use virtual to be overrided to mock data for fuzz tests
  function getActiveTime(
    address pAddr,
    address nftContract,
    uint256 nftId
  ) public view virtual returns (uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IPoolStorage(pAddr).getSecondsPerLiquidityInside(pData.tickLower, pData.tickUpper);
  }

  function getSignedFee(address nftContract, uint256 nftId) public view returns (int256) {
    uint256 feeGrowthInsideLast = getFee(nftContract, nftId);
    return int256(feeGrowthInsideLast);
  }

  function getSignedFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) public view returns (int256) {
    uint256 feeGrowthInside = getFeePool(poolAddress, nftContract, nftId);
    return int256(feeGrowthInside);
  }

  function getLiq(address nftContract, uint256 nftId) public view returns (uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return pData.liquidity;
  }

  function _getPositionFromNFT(address nftContract, uint256 nftId)
    internal
    view
    returns (IBasePositionManager.Position memory)
  {
    (IBasePositionManager.Position memory pData, ) = IBasePositionManager(nftContract).positions(
      nftId
    );
    return pData;
  }
}