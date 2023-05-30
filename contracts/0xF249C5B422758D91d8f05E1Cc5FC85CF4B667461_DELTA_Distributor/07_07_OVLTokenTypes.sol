// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY

pragma solidity ^0.7.6;

struct VestingTransaction {
    uint256 amount;
    uint256 fullVestingTimestamp;
}

struct WalletTotals {
    uint256 mature;
    uint256 immature;
    uint256 total;
}

struct UserInformation {
    // This is going to be read from only [0]
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
    uint256 maturedBalance;
    uint256 maxBalance;
    bool fullSenderWhitelisted;
    // Note that recieving immature balances doesnt mean they recieve them fully vested just that senders can do it
    bool immatureReceiverWhitelisted;
    bool noVestingWhitelisted;
}

struct UserInformationLite {
    uint256 maturedBalance;
    uint256 maxBalance;
    uint256 mostMatureTxIndex;
    uint256 lastInTxIndex;
}

struct VestingTransactionDetailed {
    uint256 amount;
    uint256 fullVestingTimestamp;
    // uint256 percentVestedE4;
    uint256 mature;
    uint256 immature;
}


uint256 constant QTY_EPOCHS = 7;

uint256 constant SECONDS_PER_EPOCH = 172800; // About 2days

uint256 constant FULL_EPOCH_TIME = SECONDS_PER_EPOCH * QTY_EPOCHS;

// Precision Multiplier -- this many zeros (23) seems to get all the precision needed for all 18 decimals to be only off by a max of 1 unit
uint256 constant PM = 1e23;