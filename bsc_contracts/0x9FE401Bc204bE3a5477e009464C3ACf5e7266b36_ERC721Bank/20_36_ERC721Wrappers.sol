// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../interfaces/UniswapV3/INonfungiblePositionManager.sol";
import "../interfaces/UniswapV3/IUniswapV3Pool.sol";
import "../interfaces/UniswapV3/IUniswapV3Factory.sol";
import "./BankBase.sol";
import "../libraries/TickMath.sol";
import "../libraries/LiquidityAmounts.sol";
import "hardhat/console.sol";

abstract contract IERC721Wrapper is Ownable {
    function isSupported(address manager, address pool) external view virtual returns (bool);

    function getPoolAddress(address manager, uint256 id) external view virtual returns (address);

    function deposit(
        address manager,
        uint256 id,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) external virtual returns (uint256);

    function withdraw(
        address manager,
        uint256 id,
        uint256 amount,
        address receiver
    ) external virtual returns (address[] memory outTokens, uint256[] memory tokenAmounts);

    function harvest(
        address manager,
        uint256 id,
        address receiver
    ) external virtual returns (address[] memory outTokens, uint256[] memory tokenAmounts);

    function getRatio(
        address manager,
        uint256 id
    ) external view virtual returns (address[] memory tokens, uint256[] memory ratios);

    function getRewardsForPosition(
        address manager,
        uint256 tokenId
    ) external view virtual returns (address[] memory rewards, uint256[] memory amounts);

    function getERC20Base(address pool) external view virtual returns (address[] memory underlyingTokens);

    function getPositionUnderlying(
        address manager,
        uint256 tokenId
    ) external view virtual returns (address[] memory tokens, uint256[] memory amounts);
}

contract UniswapV3Wrapper is IERC721Wrapper {
    using SaferERC20 for IERC20;

    function isSupported(address managerAddress, address poolAddress) external view override returns (bool) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        uint24 fee = pool.fee();
        INonfungiblePositionManager manager = INonfungiblePositionManager(managerAddress);
        IUniswapV3Factory factory = IUniswapV3Factory(manager.factory());
        address expectedPoolAddress = factory.getPool(token0, token1, fee);
        if (expectedPoolAddress == poolAddress) {
            return true;
        }
        return false;
    }

    function getPoolAddress(address manager, uint256 id) external view override returns (address) {
        (, , address token0, address token1, uint24 fee, , , , , , , ) = INonfungiblePositionManager(manager).positions(
            id
        );
        address factory = INonfungiblePositionManager(manager).factory();
        address poolAddress = IUniswapV3Factory(factory).getPool(token0, token1, fee);
        return poolAddress;
    }

    function deposit(
        address manager,
        uint256 id,
        address[] memory suppliedTokens,
        uint256[] memory suppliedAmounts
    ) external override returns (uint256) {
        for (uint256 i = 0; i < suppliedTokens.length; i++) {
            IERC20(suppliedTokens[i]).safeIncreaseAllowance(manager, suppliedAmounts[i]);
        }
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(manager).positions(id);
        uint256 amount0;
        uint256 amount1;
        if (token0 == suppliedTokens[0] && token1 == suppliedTokens[1]) {
            amount0 = suppliedAmounts[0];
            amount1 = suppliedAmounts[1];
        } else {
            amount1 = suppliedAmounts[0];
            amount0 = suppliedAmounts[1];
        }
        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams(id, amount0, amount1, 0, 0, block.timestamp);
        (uint256 minted, uint256 a0, uint256 a1) = INonfungiblePositionManager(manager).increaseLiquidity(params);
        address owner = INonfungiblePositionManager(manager).ownerOf(id);
        // Refund left overs
        if (token0 == suppliedTokens[0] && token1 == suppliedTokens[1]) {
            IERC20(token0).safeTransfer(owner, suppliedAmounts[0] - a0);
            IERC20(token1).safeTransfer(owner, suppliedAmounts[1] - a1);
        } else {
            IERC20(token0).safeTransfer(owner, suppliedAmounts[1] - a0);
            IERC20(token1).safeTransfer(owner, suppliedAmounts[0] - a1);
        }
        return minted;
    }

    function withdraw(
        address manager,
        uint256 id,
        uint256 amount,
        address receiver
    ) external override returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(manager).positions(id);
        INonfungiblePositionManager.DecreaseLiquidityParams memory withdrawParams = INonfungiblePositionManager
            .DecreaseLiquidityParams(id, uint128(amount), 0, 0, block.timestamp);
        (uint256 token0Amount, uint256 token1Amount) = INonfungiblePositionManager(manager).decreaseLiquidity(
            withdrawParams
        );
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams(
            id,
            address(this),
            2 ** 128 - 1,
            2 ** 128 - 1
        );
        INonfungiblePositionManager(manager).collect(params);
        IERC20(token0).safeTransfer(receiver, token0Amount);
        IERC20(token1).safeTransfer(receiver, token1Amount);
        outTokens = new address[](2);
        outTokens[0] = token0;
        outTokens[1] = token1;
        tokenAmounts = new uint256[](2);
        tokenAmounts[0] = token0Amount;
        tokenAmounts[1] = token1Amount;
    }

    function harvest(
        address manager,
        uint256 id,
        address receiver
    ) external override returns (address[] memory outTokens, uint256[] memory tokenAmounts) {
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(manager).positions(id);
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams(
            id,
            receiver,
            2 ** 128 - 1,
            2 ** 128 - 1
        );
        (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(manager).collect(params);
        outTokens = new address[](2);
        outTokens[0] = token0;
        outTokens[1] = token1;
        tokenAmounts = new uint256[](2);
        tokenAmounts[0] = amount0;
        tokenAmounts[1] = amount1;
    }

    function getRatio(
        address manager,
        uint256 tokenId
    ) external view override returns (address[] memory tokens, uint256[] memory ratios) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tick0,
            int24 tick1,
            ,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(manager).positions(tokenId);
        IUniswapV3Factory factory = IUniswapV3Factory(INonfungiblePositionManager(manager).factory());
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(token0, token1, fee));
        int24 currentTick;
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        {
            currentTick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
            uint absTick = currentTick < 0 ? uint(-int(currentTick)) : uint(int(currentTick));
            uint24 tickSpacing = uint24(pool.tickSpacing());
            absTick -= absTick % tickSpacing;
            currentTick = currentTick < 0 ? -int24(int(absTick)) : int24(int(absTick));
            tokens = new address[](2);
            tokens[0] = token0;
            tokens[1] = token1;
        }
        ratios = new uint256[](2);
        {
            (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
                TickMath.getSqrtRatioAtTick(currentTick),
                TickMath.getSqrtRatioAtTick(tick0),
                TickMath.getSqrtRatioAtTick(tick1),
                pool.liquidity()
            );
            uint256 price;
            uint256 MAX = 2 ** 256 - 1;
            if (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) > MAX / 1e18) {
                price = ((uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> (96 * 2)) * 1e18;
            } else {
                price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18) >> (96 * 2);
            }
            ratios[0] = amount0;
            ratios[1] = (amount1 * 1e18) / price;
        }
    }

    function getRewardsForPosition(
        address manager,
        uint256 tokenId
    ) external view override returns (address[] memory rewards, uint256[] memory amounts) {
        (uint256 fee0, uint256 fee1) = getPendingFees(manager, tokenId);
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(manager).positions(tokenId);
        rewards = new address[](2);
        rewards[0] = token0;
        rewards[1] = token1;
        amounts = new uint256[](2);
        amounts[0] = fee0;
        amounts[1] = fee1;
    }

    function getPositionUnderlying(
        address manager,
        uint256 tokenId
    ) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = INonfungiblePositionManager(manager).positions(tokenId);
        IUniswapV3Pool pool = IUniswapV3Pool(
            IUniswapV3Factory(INonfungiblePositionManager(manager).factory()).getPool(token0, token1, fee)
        );
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );
        tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;
        amounts = new uint256[](2);
        amounts[0] = amount0;
        amounts[1] = amount1;
    }

    function getERC20Base(address poolAddress) external view override returns (address[] memory underlyingTokens) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        underlyingTokens = new address[](2);
        underlyingTokens[0] = token0;
        underlyingTokens[1] = token1;
    }

    function getPendingFees(
        address manager,
        uint256 _positionId
    ) internal view returns (uint256 feeAmt0, uint256 feeAmt1) {
        int24 tickLower;
        int24 tickUpper;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        IUniswapV3Pool pool;
        {
            address token0;
            address token1;
            uint24 fee;
            (
                ,
                ,
                token0,
                token1,
                fee,
                tickLower,
                tickUpper,
                ,
                feeGrowthInside0LastX128,
                feeGrowthInside1LastX128,
                ,

            ) = INonfungiblePositionManager(manager).positions(_positionId);
            pool = IUniswapV3Pool(
                IUniswapV3Factory(INonfungiblePositionManager(manager).factory()).getPool(token0, token1, fee)
            );
        }
        (, int24 curTick, , , , , ) = pool.slot0();

        (uint128 liquidity, , , uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(
            _getPositionID(manager, tickLower, tickUpper)
        );

        feeAmt0 =
            _computeFeesEarned(pool, true, feeGrowthInside0LastX128, curTick, tickLower, tickUpper, liquidity) +
            tokensOwed0;
        feeAmt1 =
            _computeFeesEarned(pool, false, feeGrowthInside1LastX128, curTick, tickLower, tickUpper, liquidity) +
            tokensOwed1;
    }

    function _getPositionID(
        address _owner,
        int24 _lowerTick,
        int24 _upperTick
    ) internal pure returns (bytes32 positionId) {
        return keccak256(abi.encodePacked(_owner, _lowerTick, _upperTick));
    }

    // ref: from arrakis finance: https://github.com/ArrakisFinance/vault-v1-core/blob/main/contracts/ArrakisVaultV1.sol
    function _computeFeesEarned(
        IUniswapV3Pool _pool,
        bool _isZero,
        uint256 _feeGrowthInsideLast,
        int24 _tick,
        int24 _lowerTick,
        int24 _upperTick,
        uint128 _liquidity
    ) internal view returns (uint256 fee) {
        uint256 feeGrowthOutsideLower;
        uint256 feeGrowthOutsideUpper;
        uint256 feeGrowthGlobal;
        if (_isZero) {
            feeGrowthGlobal = _pool.feeGrowthGlobal0X128();
            (, , feeGrowthOutsideLower, , , , , ) = _pool.ticks(_lowerTick);
            (, , feeGrowthOutsideUpper, , , , , ) = _pool.ticks(_upperTick);
        } else {
            feeGrowthGlobal = _pool.feeGrowthGlobal1X128();
            (, , , feeGrowthOutsideLower, , , , ) = _pool.ticks(_lowerTick);
            (, , , feeGrowthOutsideUpper, , , , ) = _pool.ticks(_upperTick);
        }

        unchecked {
            // calculate fee growth below
            uint256 feeGrowthBelow;
            if (_tick >= _lowerTick) {
                feeGrowthBelow = feeGrowthOutsideLower;
            } else {
                feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove;
            if (_tick < _upperTick) {
                feeGrowthAbove = feeGrowthOutsideUpper;
            } else {
                feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
            }

            uint256 feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove;
            fee = (_liquidity * (feeGrowthInside - _feeGrowthInsideLast)) / 2 ** 128;
        }
    }
}