// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

struct WithdrawInfo {
    uint64 operatorId;
    // The income that should be issued by this operatorId in this settlement
    uint96 clReward;
    // For this settlement, whether operatorId has exit node, if no exit node is 0;
    // The value of one node exiting is 32 eth(or 32.9 ETH), and the value of two nodes exiting is 64eth (or 63 ETH).
    // If the value is less than 32, the corresponding amount will be punished
    // clCapital is the principal of nft exit held by the protocol
    uint96 clCapital;
}

struct ExitValidatorInfo {
    // Example Exit the token Id of the validator. No exit is an empty array.
    uint64 exitTokenId;
    // Height of exit block
    uint96 exitBlockNumber;
    // Amount of slash
    uint96 slashAmount;
}