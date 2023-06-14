//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../tokens/IERC20.sol";

interface IXYBridge {
    struct SwapDescription {
        IERC20 fromToken;
        IERC20 toToken;
        address receiver;
        uint256 amount;
        uint256 minReturnAmount;
    }

    // Info of an expecting swap on target chain of a swap request
    struct ToChainDescription {
        uint32 toChainId;
        IERC20 toChainToken;
        uint256 expectedToChainTokenAmount;
        uint32 slippage;
    }

    function swap(
        address aggregatorAdaptor,
        SwapDescription memory swapDesc,
        bytes memory aggregatorData,
        ToChainDescription calldata toChainDesc
    ) external payable;
}