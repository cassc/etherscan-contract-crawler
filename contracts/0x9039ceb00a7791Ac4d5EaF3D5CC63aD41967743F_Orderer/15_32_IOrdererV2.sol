// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Orderer interface
/// @notice Describes methods for reweigh execution, order creation and execution
interface IOrdererV2 {
    struct InternalSwapV2 {
        address sellAccount;
        address buyAccount;
        address sellAsset;
        address buyAsset;
        uint maxSellShares;
    }

    struct ExternalSwapV2 {
        address account;
        address sellAsset;
        address buyAsset;
        uint sellShares;
        address swapTarget;
        bytes swapData;
    }

    /// @notice Initializes orderer with the given params (overrides IOrderer's initialize)
    /// @param _registry Index registry address
    /// @param _orderLifetime Order lifetime in which it stays valid
    /// @param _maxSlippageInBP Max slippage in BP
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external;

    /// @notice Sets max allowed slippage
    /// @param _maxSlippageInBP Max allowed slippage
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external;

    /// @notice Swap shares between given indexes
    /// @param _info Swap info objects with exchange details
    function internalSwap(InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _info Swap info objects with exchange details
    function externalSwap(ExternalSwapV2 calldata _info) external;

    /// @notice Max allowed exchange price impact
    /// @return Returns max allowed exchange price impact
    function maxSlippageInBP() external view returns (uint16);
}