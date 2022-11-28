// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "./BridgeBase.sol";
import "./interfaces/IExecuteRollup.sol";
import "./interfaces/IGetRollupInfo.sol";
import "./interfaces/ISettle.sol";

/// @notice This contract facilitates the rollup executions and state settlements.

contract Bridge is BridgeBase, IExecuteRollup {
    event ExecuteRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 stateChangeHash
    );
    event ExecuteSettlement(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchIndex,
        uint64 totalBatches
    );

    constructor(
        uint8 domainID,
        address[] memory initialRelayers,
        uint256 initialRelayerThreshold,
        uint256 expiry
    ) BridgeBase(domainID, initialRelayers, initialRelayerThreshold, expiry) {}

    /// @notice Executes rollup.
    ///
    /// @notice Requirements:
    /// - Bridge must not be paused.
    /// - {resourceID} must be registered.
    /// - {_msgSender()} must be registered token address.
    ///
    /// @notice Emits {ExecuteRollup} event which is handled by relayer.
    function executeRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 stateChangeHash
    ) external override whenNotPaused {
        address rollupHandlerAddress = _resourceIDToHandlerAddress[resourceID];
        require(rollupHandlerAddress != address(0), "invalid resource ID");

        address tokenAddress = IERCHandler(rollupHandlerAddress)
            ._resourceIDToTokenContractAddress(resourceID);
        require(tokenAddress == _msgSender(), "invalid token address");

        uint64 nonce = ++_depositCounts[destDomainID];

        emit ExecuteRollup(
            destDomainID,
            resourceID,
            nonce,
            batchSize,
            startBlock,
            stateChangeHash
        );
    }

    /// @notice Executes settlement.
    ///
    /// @notice Requirements:
    /// - Handler must be registered with {resourceID}.
    ///
    /// @dev It can be called by anyone.
    function executeSettlement(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes calldata data,
        bytes32[] calldata proof
    ) external whenNotPaused {
        address rollupHandlerAddress = _resourceIDToHandlerAddress[resourceID];
        require(
            rollupHandlerAddress != address(0),
            "no handler for resourceID"
        );

        (
            address settleableAddress,
            bytes32 rootHash,
            uint64 totalBatches
        ) = IGetRollupInfo(rollupHandlerAddress).getRollupInfo(
                originDomainID,
                resourceID,
                nonce
            );

        ISettle(settleableAddress).settle(
            originDomainID,
            resourceID,
            nonce,
            proof,
            rootHash,
            data
        );

        uint64 batchIndex = abi.decode(data, (uint64));

        // slither-disable-next-line reentrancy-events
        emit ExecuteSettlement(
            originDomainID,
            resourceID,
            nonce,
            batchIndex,
            totalBatches
        );
    }
}