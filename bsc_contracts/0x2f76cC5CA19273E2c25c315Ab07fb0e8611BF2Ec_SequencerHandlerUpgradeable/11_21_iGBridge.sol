// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface iGBridge {
    function genericDeposit(uint8 _destChainID, bytes32 _resourceID) external returns (uint64);

    function fetch_chainID() external view returns (uint8);

    /// @notice Used to re-emit deposit event for generic deposit
    /// @notice Can only be called by Generic handler
    function replayGenericDeposit(
        uint8 _destChainID,
        bytes32 _resourceID,
        uint64 _depositNonce
    ) external;

    function fetch_resourceIDToHandlerAddress(bytes32 _id) external view returns (address);
}