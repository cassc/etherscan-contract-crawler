// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/** @title Library functions used by contracts within this ecosystem.*/
library GluwaInvestmentModel {
    /**
     * @dev Enum of the different states a Pool can be in.
     */
    enum PoolState {
        /*0*/
        Pending,
        /*1*/
        Scheduled,
        /*2*/
        Open,
        /*3*/
        Closed,
        /*4*/
        Mature,
        /*5*/
        Rejected,
        /*6*/
        Canceled,
        /*7*/
        Locked
    }

    /**
     * @dev Enum of the different states an Account can be in.
     */
    enum AccountState {
        /*0*/
        Pending,
        /*1*/
        Active,
        /*2*/
        Locked,
        /*3*/
        Closed
    }

    /**
     * @dev Enum of the different states a Balance can be in.
     */
    enum BalanceState {
        /*0*/
        Pending,
        /*1*/
        Active,
        /*2*/
        Mature,
        /*3*/
        Closed /* The balance is matured and winthdrawn */
    }

    struct Pool {
        uint32 interestRate;
        uint32 tenor;
        // Index of this Pool
        uint64 idx;
        uint64 openingDate;
        uint64 closingDate;
        uint64 startingDate;
        uint128 minimumRaise;
        uint256 maximumRaise;
        uint256 totalDeposit;
        uint256 totalRepayment;
    }

    struct Account {
        // Different states an account can be in
        AccountState state;
        // Index of this Account
        uint64 idx;
        uint64 startingDate;
        uint256 totalDeposit;
        bytes32 securityReferenceHash;
    }

    struct Balance {
        // Index of this balance
        uint64 idx;
        // address of the owner
        address owner;
        uint256 principal;
        uint256 totalWithdrawal;
        bytes32 accountHash;
        bytes32 poolHash;
    }
}