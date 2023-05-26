// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title GovernanceDefs
 * @author DerivaDEX
 *
 * This library contains the common structs and enums pertaining to
 * the governance.
 */
library GovernanceDefs {
    struct Proposal {
        bool canceled;
        bool executed;
        address proposer;
        uint32 delay;
        uint96 forVotes;
        uint96 againstVotes;
        uint128 id;
        uint256 eta;
        address[] targets;
        string[] signatures;
        bytes[] calldatas;
        uint256[] values;
        uint256 startBlock;
        uint256 endBlock;
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
}