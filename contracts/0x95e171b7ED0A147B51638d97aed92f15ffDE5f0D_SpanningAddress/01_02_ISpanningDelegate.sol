// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (C) 2022 Spanning Labs Inc.

pragma solidity ^0.8.0;

/**
 * @dev Interface of a Delegate in the Spanning Protocol.
 */
interface ISpanningDelegate {
    /**
     * @return bytes4 - Domain of the delegate.
     */
    function getDomain() external view returns (bytes4);

    /**
     * @dev Sets the deployable status to true.
     */
    function makeDeployable() external;

    /**
     * @dev Sets the deployable status to false.
     */
    function revokeDeployable() external;

    /**
     * @return bool - Deployable status of the delegate.
     */
    function isDeployable() external view returns (bool);

    /**
     * @return bool - If the current stack has set Spanning Info correctly
     */
    function isValidData() external view returns (bool);

    /**
     * @return bytes32 - Address of the entity that contacted the delegate.
     */
    function currentSenderAddress() external view returns (bytes32);

    /**
     * @return bytes32 - Address of the originator of the transaction.
     */
    function currentTxnSenderAddress() external view returns (bytes32);

    /**
     * @dev Used by authorized middleware to run a transaction on this domain.
     *
     * Note: We currently we assume the contract owner == authorized address
     *
     * @param programAddress - Address to be called
     * @param msgSenderAddress - Address of the entity that contacted the delegate
     * @param txnSenderAddress - Address of the originator of the transaction
     * @param payload - ABI-encoding of the desired function call
     */
    function spanningCall(
        bytes32 programAddress,
        bytes32 msgSenderAddress,
        bytes32 txnSenderAddress,
        bytes calldata payload
    ) external;

    /**
     * @dev Allows a user to request a call over authorized middleware nodes.
     *
     * Note: This can result in either a local or cross-domain transaction.
     * Note: Dispatch uses EVM Events as a signal to our middleware.
     *
     * @param programAddress - Address to be called
     * @param payload - ABI-encoding of the desired function call
     */
    function makeRequest(bytes32 programAddress, bytes calldata payload)
        external;

    /**
     * @dev Emitted when payment is received in local gas coin.
     *
     * @param addr - Legacy (local) address that sent payment
     * @param value - Value (in wei) that was sent
     */
    event Received(address addr, uint256 value);

    /**
     * @dev Emitted when a Spanning transaction stays on the current domain.
     *
     * @param programAddress - Address to be called
     * @param msgSenderAddress - Address of the entity that contacted the delegate
     * @param txnSenderAddress - Address of the originator of the transaction
     * @param payload - ABI-encoding of the desired function call
     * @param returnData - Information from the result of the function call
     */
    event LocalRequest(
        bytes32 indexed programAddress,
        bytes32 indexed msgSenderAddress,
        bytes32 indexed txnSenderAddress,
        bytes payload,
        bytes returnData
    );

    /**
     * @dev Emitted when a Spanning transaction must leave the current domain.
     *
     * Note: Spanning's middleware nodes are subscribed to this event.
     *
     * @param programAddress - Address to be called
     * @param msgSenderAddress - Address of the entity that contacted the delegate
     * @param txnSenderAddress - Address of the originator of the transaction
     * @param payload - ABI-encoding of the desired function call
     */
    event SpanningRequest(
        bytes32 indexed programAddress,
        bytes32 indexed msgSenderAddress,
        bytes32 indexed txnSenderAddress,
        bytes payload
    );

    /**
     * @dev Emitted when deployable status is set
     *
     * @param deployable - whether the delegate is deployable or not
     */
    event Deployable(
        bool indexed deployable
    );

    /**
     * @dev Emitted when SPAN contract is set
     *
     * @param spanAddr - the address of the set SPAN contract
     */
    event SetSPAN(
        address indexed spanAddr
    );
}
