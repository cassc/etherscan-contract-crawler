// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface for handler contracts that support deposits and deposit executions.
/// @author Router Protocol.
interface IDepositExecute {
    struct SwapInfo {
        address feeTokenAddress;
        uint64 depositNonce;
        uint256 index;
        uint256 returnAmount;
        address recipient;
        address stableTokenAddress;
        address handler;
        uint256 srcTokenAmount;
        uint256 srcStableTokenAmount;
        uint256 destStableTokenAmount;
        uint256 destTokenAmount;
        uint256 lenRecipientAddress;
        uint256 lenSrcTokenAddress;
        uint256 lenDestTokenAddress;
        bytes20 srcTokenAddress;
        address srcStableTokenAddress;
        bytes20 destTokenAddress;
        address destStableTokenAddress;
        bytes[] dataTx;
        uint256[] flags;
        address[] path;
        address depositer;
        bool isDestNative;
        uint256 widgetID;
    }

    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param destinationChainID Chain ID deposit is expected to be bridged to.
    /// @param depositNonce This value is generated as an ID by the Bridge contract.
    /// @param swapDetails Swap details
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        SwapInfo calldata swapDetails
    ) external;

    /// @notice It is intended that proposals are executed by the Bridge contract.
    function executeProposal(SwapInfo calldata swapDetails, bytes32 resourceID) external returns (address, uint256);
}