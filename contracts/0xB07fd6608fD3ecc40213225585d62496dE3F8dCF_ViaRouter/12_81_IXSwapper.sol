// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IXSwapper {
    struct SwapDescription {
        address fromToken;
        address toToken;
        address receiver;
        uint256 amount;
        uint256 minReturnAmount;
    }

    // Info of an expecting swap on target chain of a swap request
    struct ToChainDescription {
        uint32 toChainId;
        address toChainToken;
        uint256 expectedToChainTokenAmount;
        uint32 slippage;
    }

    /// @notice This functions is called by user to initiate a swap. User swaps his/her token for YPool token on this chain and provide info for the swap on target chain. A swap request will be created for each swap.
    /// @dev swapDesc is the swap info for swapping on DEX on this chain, not the swap request
    /// @param swapDesc Description of the swap on DEX, see IAggregator.SwapDescription
    /// @param aggregatorData Raw data consists of instructions to swap user's token for YPool token
    /// @param toChainDesc Description of the swap on target chain, see ToChainDescription
    function swap(
        SwapDescription memory swapDesc,
        bytes memory aggregatorData,
        ToChainDescription calldata toChainDesc
    ) external payable;
}