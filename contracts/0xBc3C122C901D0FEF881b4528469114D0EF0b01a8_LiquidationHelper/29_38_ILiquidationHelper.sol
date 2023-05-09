// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice LiquidationHelper IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
interface ILiquidationHelper {
    /// @dev Liquidation scenarios that are supported by helper:
    /// - Internal: fully on-chain, using internal swappers, magicians etc
    ///   When 0x API can not handle the swap, we will use internal.
    /// - Full0x: 0x will handle swap for collateral -> repay asset, then contract needs to do repay.
    ///   Change that left after repay will be swapped to WETH using internal methods.
    ///   This scenario is for A -> B or A, B -> C cases.
    /// - Full0xWithChange: similar to Full0x, but all repay tokens that left, will be send to liquidator.
    ///   BE bot needs to do another tx to swap change to ETH
    ///   This scenario is for A -> B or A, B -> C cases
    ///   Exception: WETH -> A, it should be full or internal
    ///   Helper is supporting all the tokens internally, so only case, when we would need Full0xWithChange is when
    ///   we didn't develop swapper/magician for some new asset yet. Call `liquidationSupported` to check it.
    /// - Collateral0x: 0x will swap collateral to native token, then from native -> repay asset contract handle it
    ///   This is for A -> XAI, WETH, other cases of multiple repay tokens are not supported by 0x
    /// - *Force: force option allows to liquidate even when liquidation is not profitable
    enum LiquidationScenario {
        Internal, Collateral0x, Full0x, Full0xWithChange,
        InternalForce, Collateral0xForce, Full0xForce, Full0xWithChangeForce
    }
}