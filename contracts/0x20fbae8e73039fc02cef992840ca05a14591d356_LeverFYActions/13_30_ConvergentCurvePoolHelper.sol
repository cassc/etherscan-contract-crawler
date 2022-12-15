// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {sub, wmul, wdiv} from "../../core/utils/Math.sol";

interface IConvergentCurvePool {
    function solveTradeInvariant(
        uint256 amountX,
        uint256 reserveX,
        uint256 reserveY,
        bool out
    ) external view returns (uint256);

    function percentFee() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory deltas);

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory deltas);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
}

/// @notice Helper methods for Element Finance's CurveConvergentPool
/// Link: https://github.com/element-fi/elf-contracts/blob/main/contracts/ConvergentCurvePool.sol
library ConvergentCurvePoolHelper {
    error ConvergentCurvePoolHelper__swapPreview_tokenMismatch();

    /// @notice Preview method for `onSwap()`
    /// @param balancerVault Address of the Balancer Vault contract
    /// @param poolId Id of the Balancer pool
    /// @param amountIn_ Input amount of swap [wad]
    function swapPreview(
        address balancerVault,
        bytes32 poolId,
        uint256 amountIn_,
        bool fromUnderlying,
        address bond,
        address underlying,
        uint256 bondScale,
        uint256 underlyingScale
    ) internal view returns (uint256) {
        // amountIn needs to be converted to wad
        uint256 amountIn = (fromUnderlying) ? wdiv(amountIn_, underlyingScale) : wdiv(amountIn_, bondScale);

        // determine the current pool balances and convert them to wad
        uint256 currentBalanceTokenIn;
        uint256 currentBalanceTokenOut;
        {
            (address[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(
                poolId
            );

            if (tokens[0] == underlying && tokens[1] == bond) {
                currentBalanceTokenIn = (fromUnderlying)
                    ? wdiv(balances[0], underlyingScale)
                    : wdiv(balances[1], bondScale);
                currentBalanceTokenOut = (fromUnderlying)
                    ? wdiv(balances[1], bondScale)
                    : wdiv(balances[0], underlyingScale);
            } else if (tokens[0] == bond && tokens[1] == underlying) {
                currentBalanceTokenIn = (fromUnderlying)
                    ? wdiv(balances[1], underlyingScale)
                    : wdiv(balances[0], bondScale);
                currentBalanceTokenOut = (fromUnderlying)
                    ? wdiv(balances[0], bondScale)
                    : wdiv(balances[1], underlyingScale);
            } else {
                revert ConvergentCurvePoolHelper__swapPreview_tokenMismatch();
            }
        }

        (address pool, ) = IBalancerVault(balancerVault).getPool(poolId);
        IConvergentCurvePool ccp = IConvergentCurvePool(pool);

        // adapted from `_adjustedReserve()`
        // adjust the bond reserve and leaves the underlying reserve as is
        if (fromUnderlying) {
            unchecked {
                currentBalanceTokenOut += ccp.totalSupply();
            }
        } else {
            unchecked {
                currentBalanceTokenIn += ccp.totalSupply();
            }
        }

        // perform the actual trade calculation
        uint256 amountOut = ccp.solveTradeInvariant(amountIn, currentBalanceTokenIn, currentBalanceTokenOut, true);

        // adapted from `_assignTradeFee()`
        // only the `isInputTrade` == false logic applies since this method only takes `amountIn`
        // If the output is the bond the implied yield is out - in
        // If the output is underlying the implied yield is in - out
        uint256 impliedYieldFee = wmul(
            ccp.percentFee(),
            fromUnderlying ? sub(amountOut, amountIn) : sub(amountIn, amountOut)
        );
        // subtract the impliedYieldFee from amountOut and convert it from wad to either bondScale or underlyingScale
        return wmul(sub(amountOut, impliedYieldFee), (fromUnderlying) ? bondScale : underlyingScale);
    }
}