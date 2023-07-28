// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";
import {IPosition} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPosition.sol";
import {Math as MavMath} from "./Math.sol";

import {IPoolPositionSlim} from "../interfaces/IPoolPositionSlim.sol";

/// @title view functions on PoolPosition
library PoolPositionUtilities {
    uint256 constant ONE = 1e18;

    /// @notice Get pool.addLiquidity parameters that specify the number of A
    //and B tokens a user needs to contributed to the pool in order to mint
    //a given amount of PoolPosition LP tokens
    /// @param lpTokenAmount target number of PoolPosition LP tokens to be
    //minted
    //  @return addParams array of add liquidity parameters,
    function getAddLiquidityParams(IPool pool, IPoolPositionSlim poolPosition, uint256 lpTokenAmount) internal view returns (IPool.AddLiquidityParams[] memory addParams, uint256 binLpTokenAmount0) {
        uint128[] memory binIds = poolPosition.allBinIds();
        IPool.BinState memory bin = pool.getBin(binIds[0]);
        uint256 tokenAScale = pool.tokenAScale();
        uint256 tokenBScale = pool.tokenBScale();
        if (!poolPosition.isStatic() && bin.mergeId != 0) revert("Bin is merged; migrate first");

        addParams = new IPool.AddLiquidityParams[](binIds.length);

        binLpTokenAmount0 = Math.mulDiv(lpTokenAmount, pool.balanceOf(poolPosition.tokenId(), binIds[0]), poolPosition.totalSupply(), Math.Rounding(1)) + 1;
        uint256 binLpTokenAmount = binLpTokenAmount0;
        for (uint256 i; i < binIds.length; i++) {
            if (i != 0) {
                bin = pool.getBin(binIds[i]);
                binLpTokenAmount = Math.mulDiv(poolPosition.ratios(i), binLpTokenAmount0, ONE, Math.Rounding(1));
            }

            uint256 amountA;
            uint256 amountB;
            uint256 reserveA = bin.reserveA;
            uint256 reserveB = bin.reserveB;
            if (reserveA == 0) {
                amountB = Math.mulDiv(reserveB, binLpTokenAmount, bin.totalSupply, Math.Rounding(1));
            } else if (reserveB == 0) {
                amountA = Math.mulDiv(reserveA, binLpTokenAmount, bin.totalSupply, Math.Rounding(1));
            } else {
                // Rounding effects may lead to too little active bin being
                // minted.  Pad amount by 0.1bps.
                binLpTokenAmount = Math.mulDiv(binLpTokenAmount, 1.00001e18, 1e18, Math.Rounding(1)) + 1;
                amountA = Math.mulDiv(reserveA, binLpTokenAmount, bin.totalSupply, Math.Rounding(1));
                amountB = Math.max(Math.mulDiv(reserveB, amountA, reserveA, Math.Rounding(1)), Math.mulDiv(reserveB, binLpTokenAmount, bin.totalSupply, Math.Rounding(1)));
                amountA = Math.mulDiv(reserveA, amountB, reserveB, Math.Rounding(1));
            }

            addParams[i] = IPool.AddLiquidityParams({
                kind: bin.kind,
                pos: bin.lowerTick,
                isDelta: false,
                deltaA: reserveA == 0 ? 0 : SafeCast.toUint128(MavMath.toScale(amountA, tokenAScale, true)),
                deltaB: reserveB == 0 ? 0 : SafeCast.toUint128(MavMath.toScale(amountB, tokenBScale, true))
            });
        }
    }
}