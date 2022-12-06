// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IViaRouter {
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

    struct BridgeData {
        address target;
        bytes callData;
    }

    struct PartData {
        uint256 amountIn;
        uint256 extraNativeValue;
    }

    function execute(
        ViaData calldata viaData,
        SwapData calldata swapData,
        BridgeData calldata bridgeData,
        bytes calldata validatorSig
    ) external payable;

    function executeSplit(
        ViaData calldata viaData,
        PartData[] calldata parts,
        SwapData[] calldata swapDatas,
        BridgeData[] calldata bridgeDatas,
        bytes calldata validatorSig
    ) external payable;
}