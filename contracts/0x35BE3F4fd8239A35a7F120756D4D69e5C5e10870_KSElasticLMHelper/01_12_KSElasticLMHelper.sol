// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import {MathConstants as C} from '../libraries/MathConstants.sol';
import {FullMath} from '../libraries/FullMath.sol';
import {ReinvestmentMath} from '../libraries/ReinvestmentMath.sol';

import {IKSElasticLMHelper} from '../interfaces/liquidityMining/IKSElasticLMHelper.sol';
import {IBasePositionManager} from '../interfaces/liquidityMining/IBasePositionManager.sol';
import {IPoolStorage} from '../interfaces/liquidityMining/IPoolStorage.sol';

import {KSAdmin} from './base/KSAdmin.sol';

contract KSElasticLMHelper is IKSElasticLMHelper, KSAdmin {
  using SafeERC20 for IERC20;

  event RescueFund(address token, uint256 amount);

  function rescueFund(IERC20 token, uint256 amount) external isAdmin {
    if (address(token) == address(0)) {
      (bool success, ) = payable(msg.sender).call{value: amount}('');
      require(success, 'rescueFund: failed to collect native');
    } else {
      token.safeTransfer(msg.sender, amount);
    }
    emit RescueFund(address(token), amount);
  }

  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) external view override returns (bool) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IBasePositionManager(nftContract).addressToPoolId(pAddress) == pData.poolId;
  }

  /// @dev use virtual to be overrided to mock data for fuzz tests
  function getActiveTime(
    address pAddr,
    address nftContract,
    uint256 nftId
  ) external view override returns (uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return IPoolStorage(pAddr).getSecondsPerLiquidityInside(pData.tickLower, pData.tickUpper);
  }

  function getSignedFee(
    address nftContract,
    uint256 nftId
  ) external view override returns (int256) {
    uint256 feeGrowthInsideLast = _getFee(nftContract, nftId);
    return int256(feeGrowthInsideLast);
  }

  function getSignedFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) external view override returns (int256) {
    uint256 feeGrowthInside = _getFeePool(poolAddress, nftContract, nftId);
    return int256(feeGrowthInside);
  }

  function getLiq(address nftContract, uint256 nftId) external view override returns (uint128) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return pData.liquidity;
  }

  function getPair(
    address nftContract,
    uint256 nftId
  ) external view override returns (address, address) {
    (, IBasePositionManager.PoolInfo memory poolInfo) = IBasePositionManager(nftContract)
      .positions(nftId);

    return (poolInfo.token0, poolInfo.token1);
  }

  function _getPositionFromNFT(
    address nftContract,
    uint256 nftId
  ) internal view returns (IBasePositionManager.Position memory) {
    (IBasePositionManager.Position memory pData, ) = IBasePositionManager(nftContract).positions(
      nftId
    );
    return pData;
  }

  function _getFee(address nftContract, uint256 nftId) internal view virtual returns (uint256) {
    IBasePositionManager.Position memory pData = _getPositionFromNFT(nftContract, nftId);
    return pData.feeGrowthInsideLast;
  }

  function _getFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) internal view virtual returns (uint256 feeGrowthInside) {
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
}