// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../policy/Policed.sol";
import "../policy/Policy.sol";
import "./IGenerationIncrease.sol";
import "../currency/ECO.sol";

/** @title Notifier
 * Contract for managing notifying external systems each generation cycle
 * Only should be used for function calls needing to happen atomically with incrementGeneration
 */
contract Notifier is Policed, IGenerationIncrease {
    struct Transaction {
        address destination;
        bytes data;
    }

    event TransactionFailed(
        uint256 index,
        address indexed destination,
        bytes data
    );

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    constructor(Policy _policy) Policed(_policy) {
        // calling the super constructor
    }

    // This function has to allow transactions to gracefully fail
    // it cannot revert as it is a part of generationIncrement()
    function notifyGenerationIncrease() external override {
        for (uint256 i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            bool result = externalCall(t.destination, t.data);
            if (!result) {
                emit TransactionFailed(i, t.destination, t.data);
            }
        }
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes memory data)
        internal
        returns (bool)
    {
        bool result;
        assembly {
            // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas(), 34710),
                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data), // Size of the input, in bytes. Stored in the first word of the bytes structure.
                outputAddress,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

    /**
     * @notice Adds a transaction that gets called for a downstream receiver
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes memory data)
        external
        onlyPolicy
    {
        transactions.push(Transaction({destination: destination, data: data}));
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint256 index) external onlyPolicy {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }

        transactions.pop();
    }

    /**
     * @return Number of transactions in the transactions list.
     */
    function transactionsSize() external view returns (uint256) {
        return transactions.length;
    }
}