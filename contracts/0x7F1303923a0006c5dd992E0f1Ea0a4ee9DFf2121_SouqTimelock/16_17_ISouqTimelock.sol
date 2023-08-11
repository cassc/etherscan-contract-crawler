// SPDX-License-Identifier: BUSL
pragma solidity 0.8.10;

/**
 * @title ISouqTimelock
 * @author Souq.Finance
 * @notice Defines the interface of timelock contract
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
 */

interface ISouqTimelock {
    enum TransactionState {
        Unset,
        Waiting,
        Ready,
        Done
    }

    function initialize(uint _delay, address _registry) external;

    /**
     * @dev Returns whether an id correspond to a registered transaction. This
     * includes both Pending, Ready and Done transactions.
     */
    function isTransaction(bytes32 id) external view returns (bool);

    /**
     * @dev Returns whether an transaction is pending or not. Note that a "pending" transaction may also be "ready".
     */
    function isTransactionPending(bytes32 id) external view returns (bool);

    /**
     * @dev Returns whether an transaction is ready for execution. Note that a "ready" transaction is also "pending".
     */
    function isTransactionReady(bytes32 id) external view returns (bool);

    /**
     * @dev Returns whether an transaction is done or not.
     */
    function isTransactionDone(bytes32 id) external view returns (bool);

    /**
     * @dev Returns the timestamp at which an transaction becomes ready (0 for
     * unset transactions, 1 for done transactions).
     */
    function getTimestamp(bytes32 id) external view returns (uint256);

    /**
     * @dev Returns the minimum delay in seconds for an transaction to become valid.
     *
     * This value can be changed by executing an transaction that calls `updateDelay`.
     */
    function getMinDelay() external view returns (uint256);

    /**
     * @dev Returns transaction state.
     */
    function getTransactionState(bytes32 id) external view returns (TransactionState);

    /**
     * @dev Returns current block timestamp
     */
    function getBlockTimeStamp() external view returns (uint256);

    /**
     * @dev Changes the minimum timelock duration for future transactions.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an transaction where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external;

    /**
     * @dev Queues a transaction to be executed after a specified delay period
     * @param target The address of the contract where the transaction will be executed
     * @param value The amount of Ether to send with the transaction
     * @param signature The function signature of the method to be called on the target contract
     * @param data The data payload for the function call
     * @param eta The estimated time (in seconds since the Unix epoch) when the transaction can be executed
     * @return bytes32 The hash of the queued transaction
     */
    function queueTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external returns (bytes32);

    /**
     * @dev Cancels a previously queued transaction
     * @param target The address of the contract where the transaction was queued
     * @param value The amount of Ether sent with the transaction
     * @param signature The function signature of the method to be called on the target contract
     * @param data The data payload for the function call
     * @param eta The estimated time (in seconds since the Unix epoch) when the transaction was scheduled
     */
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;

    /**
     * @dev Executes a queued transaction after the delay period has passed
     * @param target The address of the contract where the transaction was queued.
     * @param value The amount of Ether sent with the transaction.
     * @param signature The function signature of the method to be called on the target contract.
     * @param data The data payload for the function call.
     * @param eta The estimated time (in seconds since the Unix epoch) when the transaction was scheduled.
     * @return bytes32 The return data from the executed transaction
     */
    function executeTransaction(
        address target,
        uint value,
        string calldata signature,
        bytes calldata data,
        uint eta
    ) external payable returns (bytes memory);
}