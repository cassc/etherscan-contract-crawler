// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ServiceTransactions {
    /// @notice Struct used for single atomic transaction
    struct Operation {
        address to;
        uint256 value;
        bytes data;
    }

    /// @notice Struct used for transactions (single or batch) that could be needed, only created by protocol owner and executed by token owner/allowed
    struct Transaction {
        Operation operation;
        uint8 executed;
        uint8 confirmed;
        uint8 valid;
        uint16 prev;
        uint16 next;
        string description;
    }

    /// @notice List of transactions that might be proposed
    Transaction[] public transactions;

    event ExecuteTransaction(uint256 indexed index);
    event SubmitTransaction(uint256 indexed index, string indexed description);
    event CancelTransaction(uint256 indexed index);
    event ConfirmTransaction(uint256 indexed index);

    error PreviousValidTransactionNotExecuted(uint16 index);
    error TransactionAlreadyExecuted();
    error TransactionAlreadyConfirmed();
    error TransactionIndexInvalid();
    error TransactionCallFailed();
    error TransactionNotValid();
    error TransactionNotConfirmed();

    /// @notice For determining if specified index for transactions list is valid
    /// @param index_: Transaction index to verify
    modifier txExists(uint256 index_) {
        if (index_ >= transactions.length) {
            revert TransactionIndexInvalid();
        }
        _;
    }

    /// @notice For determining if specified transaction index was not executed
    /// @param index_: Transaction index to verify
    modifier txNotExecuted(uint256 index_) {
        if (transactions[index_].executed == 1) {
            revert TransactionAlreadyExecuted();
        }
        _;
    }

    /// @notice For determining if specified transaction index was not confirmed by owner/allowed user
    /// @param index_: Transaction index to verify
    modifier txNotConfirmed(uint256 index_) {
        if (transactions[index_].confirmed == 1) {
            revert TransactionAlreadyConfirmed();
        }
        _;
    }

    /// @notice For determining if specified transaction index is valid (not canceled by protocol owner)
    /// @param index_: Transaction index to verify
    modifier txValid(uint256 index_) {
        if (transactions[index_].valid == 0) {
            revert TransactionNotValid();
        }
        _;
    }

    /// @notice Get current transaction count
    /// @return count of transactions
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /// @notice For canceling a submited transaction if needed
    /// @dev Only protocol owner can do so
    /// @param index_: transaction index
    function _cancelTransaction(uint256 index_) internal {
        if (transactions[index_].prev == transactions[index_].next) {
            // if it is the only element in the list
            delete transactions[index_];
            transactions.pop();
        } else {
            // if it is not the only element in the list
            if (transactions[index_].prev == type(uint16).max) {
                // if it is the first
                Transaction storage transactionNext = transactions[
                    transactions[index_].next
                ];
                transactionNext.prev = type(uint16).max;
            } else if (transactions[index_].next == type(uint16).max) {
                // if it is the last
                Transaction storage transactionPrev = transactions[
                    transactions[index_].prev
                ];
                transactionPrev.next = type(uint16).max;
            } else {
                // if it is in the middle
                Transaction storage transactionPrev = transactions[
                    transactions[index_].prev
                ];
                Transaction storage transactionNext = transactions[
                    transactions[index_].next
                ];
                transactionPrev.next = transactions[index_].next;
                transactionNext.prev = transactions[index_].prev;
            }
            delete transactions[index_];
        }
        emit CancelTransaction(index_);
    }

    /// @notice Token owner or allowed confirmation to execute transaction by protocol owner
    /// @param index_: transaction index to confirm
    function _confirmTransaction(uint256 index_) internal {
        Transaction storage transaction = transactions[index_];
        transaction.confirmed = 1;
        emit ConfirmTransaction(index_);
    }

    /// @notice Executes transaction index_ that is valid, confirmed and not executed
    /// @dev Requires previous transaction valid to be executed
    /// @param index_: transaction at index to be executed
    function _executeTransaction(uint256 index_) internal {
        Transaction storage transaction = transactions[index_];

        if (transaction.confirmed == 0) {
            revert TransactionNotConfirmed();
        }
        if (transaction.prev != type(uint16).max) {
            if (transactions[transaction.prev].executed == 0) {
                revert PreviousValidTransactionNotExecuted(transaction.prev);
            }
        }

        transaction.executed = 1;

        (bool success, ) = transaction.operation.to.call{
            value: transaction.operation.value
        }(transaction.operation.data);
        if (!success) {
            revert TransactionCallFailed();
        }

        emit ExecuteTransaction(index_);
    }

    /// @notice Only protocol owner can submit a new transaction
    /// @param operation_: mapping of operations to be executed (could be just one or batch)
    /// @param description_: transaction description for easy read
    function _submitTransaction(
        Operation calldata operation_,
        string calldata description_
    ) internal {
        uint16 txLen = uint16(transactions.length);
        uint16 prev = type(uint16).max;
        uint16 next = type(uint16).max;

        if (txLen > 0) {
            prev = txLen - 1;
            Transaction storage transactionPrev = transactions[txLen - 1];
            transactionPrev.next = txLen;
        }

        transactions.push(
            Transaction({
                operation: operation_,
                executed: 0,
                confirmed: 0,
                valid: 1,
                prev: prev,
                next: next,
                description: description_
            })
        );

        emit SubmitTransaction(transactions.length, description_);
    }
}