// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Action {
    DEPOSIT,
    WITHDRAW,
    EPOCH_UPDATE,
    WITHDRAW_QUEUE
}

struct VaultParameters {
    uint256 transactionFee; // 5 bps
    // uint256 transactionFeeWeekdayRate; // 5 bps
    // uint256 transactionFeeWeekendRate; // 10 bps
    uint256 firstDeposit; // first deposit amount
    uint256 minDeposit; // 100000 USDC
    uint256 maxDeposit; // max deposit on a day
    uint256 maxWithdraw; // max withdraw on a day
    uint256 targetReservesLevel; // 10%
    uint256 onchainServiceFeeRate; // 40 bps
    uint256 offchainServiceFeeRate; // 40 bps
}