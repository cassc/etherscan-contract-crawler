// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IPancakeV3Pool} from "@pancake/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseConcentratedLiquidityStrategy} from
    "contracts/strategies/concentrated-liquidity/BaseConcentratedLiquidityStrategy.sol";
import {IMasterChefV3} from "contracts/interfaces/ext/pancake/IMasterChefV3.sol";

/// @author YLDR <[email protected]>
library PancakeV3Library {
    using SafeERC20 for IERC20;

    struct Data {
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
        INonfungiblePositionManager positionManager;
        IMasterChefV3 farm;
        IPancakeV3Pool pool;
        uint256 positionTokenId;
    }

    function getPoolData(Data storage self) public view returns (int24 currentTick, uint160 sqrtPriceX96) {
        (sqrtPriceX96, currentTick,,,,,) = self.pool.slot0();
    }

    function getPositionData(Data storage self)
        public
        view
        returns (BaseConcentratedLiquidityStrategy.PositionData memory)
    {
        (,,,,, int24 tickLower, int24 tickUpper, uint128 liquidity,,,,) =
            self.positionManager.positions(self.positionTokenId);
        return BaseConcentratedLiquidityStrategy.PositionData({
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity
        });
    }

    function mint(Data storage self, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) public {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: self.token0,
            token1: self.token1,
            fee: self.fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });
        (self.positionTokenId,,,) = self.positionManager.mint(params);
    }

    function increaseLiquidity(Data storage self, uint256 amount0, uint256 amount1) public {
        IMasterChefV3.IncreaseLiquidityParams memory params = IMasterChefV3.IncreaseLiquidityParams({
            tokenId: self.positionTokenId,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });
        self.farm.increaseLiquidity(params);
    }

    function decreaseLiquidity(Data storage self, uint128 liquidity)
        public
        returns (uint256 amount0, uint256 amount1)
    {
        IMasterChefV3.DecreaseLiquidityParams memory params = IMasterChefV3.DecreaseLiquidityParams({
            tokenId: self.positionTokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });
        (amount0, amount1) = self.farm.decreaseLiquidity(params);
    }

    function collect(Data storage self, uint256 amount0Max, uint256 amount1Max) public {
        IMasterChefV3.CollectParams memory params = IMasterChefV3.CollectParams({
            tokenId: self.positionTokenId,
            recipient: address(this),
            amount0Max: uint128(amount0Max),
            amount1Max: uint128(amount1Max)
        });
        self.farm.collect(params);
    }

    function burn(Data storage self) public {
        self.farm.burn(self.positionTokenId);
        self.positionTokenId = 0;
    }

    function enterFarming(Data storage self) public {
        if (self.positionTokenId == 0 || getPositionData(self).liquidity == 0) {
            return;
        }

        self.positionManager.safeTransferFrom(address(this), address(self.farm), self.positionTokenId);
    }

    function exitFarming(Data storage self) public {
        if (self.positionManager.ownerOf(self.positionTokenId) != address(self.farm)) {
            return;
        }

        self.farm.withdraw(self.positionTokenId, address(this));
    }

    function claimFarmRewards(Data storage self) public returns (uint256 rewards) {
        return self.farm.harvest(self.positionTokenId, address(this));
    }
}