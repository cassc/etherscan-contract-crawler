// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.19;

struct Withdrawal {
    address user;
    uint256 amount;
}

struct Allocation {
    uint256 maticAmount;
    uint256 sharePriceNum;
    uint256 sharePriceDenom;
}

/// @notice struct to hold information on a user's withdrawal request for fair claiming
/// @param user the user which made the withdrawal request
/// @param amount the amount of MATIC which the user requested to withdraw
/// @dev not storing epoch of withdrawal as that is the key in the `unbondingWithdrawals`
///   mapping