// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

struct DexSwapData {
    address fromAsset;
    uint256 fromAssetAmount;
    address toAsset;
    uint256 minToAssetAmount;
    bytes data; // Data required for a specific swap implementation. eg 1Inch
}

/**
 * @title   Dex Swap interface
 * @author  mStable
 * @notice  Generic on-chain ABI to Swap tokens on a DEX.
 * @dev     VERSION: 1.0
 *          DATE:    2022-03-07
 */
interface IDexSwap {
    function swap(DexSwapData memory _swap) external returns (uint256 toAssetAmount);
}

/**
 * @title   Dex Asynchronous Swap interface
 * @author  mStable
 * @notice  Generic on-chain ABI to Swap asynchronous tokens on a DEX.
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-07
 */
interface IDexAsyncSwap {
    function initiateSwap(DexSwapData memory _swap) external;

    function settleSwap(DexSwapData memory _swap) external;

    function cancelSwap(bytes calldata orderUid) external;
}