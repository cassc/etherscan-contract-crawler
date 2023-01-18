// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../interfaces/IViaRouter.sol";

abstract contract ViaRouterEvents is IViaRouter {
    // EVENTS

    /// @notice Event emitted when new validator is set
    event ValidatorSet(address indexed validator_);

    /// @notice Event emitted when address is set as adapter
    event AdapterSet(address indexed adapter, bool indexed value);

    /// @notice Event emitted when address is set as whitelisted target
    event WhitelistedSet(address indexed target, bool indexed whitelisted);

    /// @notice Event emitted when collected fee is withdrawn from contract
    event FeeWithdrawn(
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when swap and/or bridge request is executed
    event RequestExecuted(
        ViaData viaData,
        SwapData swapData,
        BridgeData bridgeData
    );

    /// @notice Event emitted when swap and/or bridge request is executed
    event NewRequestExecuted(
        ViaData viaData,
        NewSwapData swapData,
        BridgeData bridgeData
    );

    /// @notice Event emitted when batch request is executed
    event BatchRequestExecuted(
        ViaData[] viaDatas,
        SwapData[] swapDatas,
        BridgeData[] bridgeDatas,
        uint256[] extraNativeValues
    );
}