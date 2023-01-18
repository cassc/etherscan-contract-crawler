// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IViaRouter {
    // STRUCTS

    struct ViaData {
        address assetIn;
        uint256 amountIn;
        uint256 fee;
        uint256 deadline;
        bytes32 id;
    }

    struct SwapData {
        address target;
        address assetOut;
        bytes callData;
    }

    enum SwapType {
        None,
        ExactIn,
        ExactOut
    }

    struct NewSwapData {
        SwapType swapType;
        address target;
        address assetOut;
        bytes callData;
        address quoter;
        bytes quoteData;
    }

    struct BridgeData {
        address target;
        bytes callData;
    }

    // FUNCTIONS

    function execute(
        ViaData calldata viaData,
        SwapData calldata swapData,
        BridgeData calldata bridgeData,
        bytes calldata validatorSig
    ) external payable;

    function executeNew(
        ViaData calldata viaData,
        NewSwapData memory swapData,
        BridgeData calldata bridgeData,
        bytes calldata validatorSig
    ) external payable;

    function executeBatch(
        ViaData[] calldata viaDatas,
        NewSwapData[] calldata swapDatas,
        BridgeData[] calldata bridgeDatas,
        uint256[] calldata extraNativeValues,
        bytes calldata validatorSig
    ) external payable;
}