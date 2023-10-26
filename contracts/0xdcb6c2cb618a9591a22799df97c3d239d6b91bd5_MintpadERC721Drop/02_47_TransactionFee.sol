// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author Mintpad

abstract contract TransactionFee {
    
    /// @dev Platform wallet address
    address public platformAddress = 0xa1e957b9020A5b0EB968a9f3B857D4064dcaE6bA;

    /// @dev Transaction cost
    uint256 public transactionFee;

    /// @dev At any given moment, returns the transaction fee.
    function getTransactionFee() public view returns (uint256) {
        return transactionFee;
    }

    /**
     *  @notice         Sets a new transaction fee in case of need.
     *  @dev            This function is only used in rare situations where
     *                  the transaction fee is not set correctly. This value can
     *                  only be lower than the current transaction fee to prevent
     *                  fraud. Only Mintpad can set this transaction fee.
     *
     *  @param _transactionFee The transaction fee to be set.
     */
    function setTransactionFee(uint256 _transactionFee) external {
        require(msg.sender == platformAddress, "!Authorized");
        require(_transactionFee < transactionFee, "!TransactionFee1");
        require(_transactionFee > 0, "!TransactionFee2");

        transactionFee = _transactionFee;
    }
}