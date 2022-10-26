// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct MilestoneApprover {
    //off-chain: oracle, judge..
    address externalApprover;

    //on-chain
    uint32 targetNumPledgers;
    uint fundingPTokTarget;
}