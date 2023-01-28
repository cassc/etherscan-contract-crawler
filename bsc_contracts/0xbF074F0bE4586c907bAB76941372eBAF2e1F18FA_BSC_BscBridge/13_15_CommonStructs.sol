// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library CommonStructs {
    struct Transfer {
        address tokenAddress;
        address toAddress;
        uint amount;
    }

    struct TransferProof {
        bytes[] receiptProof;
        uint eventId;
        Transfer[] transfers;
    }

    struct LockedTransfers {
        Transfer[] transfers;
        uint endTimestamp;
    }

    struct ConstructorArgs {
        address sideBridgeAddress; address relayAddress;
        address[] watchdogsAddresses; address feeProviderAddress;
        address wrappingTokenAddress;
        address[] tokenThisAddresses; address[] tokenSideAddresses;
        address payable transferFeeRecipient; address payable bridgeFeeRecipient;
        uint timeframeSeconds; uint lockTime; uint minSafetyBlocks;
    }
}