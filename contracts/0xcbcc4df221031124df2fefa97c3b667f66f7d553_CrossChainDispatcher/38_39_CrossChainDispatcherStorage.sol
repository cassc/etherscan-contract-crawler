// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/ICrossChainDispatcher.sol";
import "../interfaces/IPoolRegistry.sol";

abstract contract CrossChainDispatcherStorageV1 is ICrossChainDispatcher {
    /**
     * @notice The pool registry contract
     */
    IPoolRegistry public poolRegistry;

    /**
     * @notice Overwritten swap slippage params
     * @dev Used by retry functions in case of swap failure due to slippage (See: `_swap()`)
     */
    mapping(uint256 => uint256) public swapAmountOutMin;

    /**
     * @notice Maps other chains `CrossChainDispatcher` contracts
     */
    mapping(uint16 => address) public crossChainDispatcherOf;

    /**
     * @notice The base gas to pay for cross-chain calls
     * @dev This limit covers basic token transfer LZ cost
     */
    uint256 public lzBaseGasLimit;

    /**
     * @notice The slippage we're willing to accept for SG like:like transfers
     */
    uint256 public stargateSlippage;

    /**
     * @notice The gas limit to cover `_crossChainFlashRepayCallback()` call
     */
    uint64 public flashRepayCallbackTxGasLimit;

    /**
     * @notice The gas limit to cover `_swapAndTriggerFlashRepayCallback()` call
     */
    uint64 public flashRepaySwapTxGasLimit;

    /**
     * @notice The gas limit to cover `_crossChainLeverageCallback()` call
     */
    uint64 public leverageCallbackTxGasLimit;

    /**
     * @notice The gas limit to cover `_swapAndTriggerLeverageCallback()` call
     */
    uint64 public leverageSwapTxGasLimit;

    /**
     * @notice Flag that pause/unpause all cross-chain activities
     */
    bool public isBridgingActive;

    /**
     * @notice The Stargate Router contract
     */
    IStargateComposer public stargateComposer;

    /**
     * @notice Maps Stargate's token pools
     */
    mapping(address => uint256) public stargatePoolIdOf;

    /**
     * @notice Maps supported cross-chain routes (i.e. which chains are allowed to be used as source of liquidity)
     */
    mapping(uint16 => bool) public isDestinationChainSupported;

    /**
     * @notice WETH contract
     */
    address public weth;

    /**
     * @notice SGETH contract
     */
    address public sgeth;
}