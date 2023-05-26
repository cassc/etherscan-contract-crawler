// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { GovernanceDefs } from "../libs/defs/GovernanceDefs.sol";

library LibDiamondStorageGovernance {
    struct DiamondStorageGovernance {
        // Proposal struct by ID
        mapping(uint256 => GovernanceDefs.Proposal) proposals;
        // Latest proposal IDs by proposer address
        mapping(address => uint128) latestProposalIds;
        // Whether transaction hash is currently queued
        mapping(bytes32 => bool) queuedTransactions;
        // Fast path for governance
        mapping(string => bool) fastPathFunctionSignatures;
        // Max number of operations/actions a proposal can have
        uint32 proposalMaxOperations;
        // Number of blocks after a proposal is made that voting begins
        // (e.g. 1 block)
        uint32 votingDelay;
        // Number of blocks voting will be held
        // (e.g. 17280 blocks ~ 3 days of blocks)
        uint32 votingPeriod;
        // Time window (s) a successful proposal must be executed,
        // otherwise will be expired, measured in seconds
        // (e.g. 1209600 seconds)
        uint32 gracePeriod;
        // Minimum time (s) in which a successful proposal must be
        // in the queue before it can be executed
        // (e.g. 0 seconds)
        uint32 minimumDelay;
        // Maximum time (s) in which a successful proposal must be
        // in the queue before it can be executed
        // (e.g. 2592000 seconds ~ 30 days)
        uint32 maximumDelay;
        // Minimum number of for votes required, even if there's a
        // majority in favor
        // (e.g. 2000000e18 ~ 4% of pre-mine DDX supply)
        uint32 quorumVotes;
        // Minimum DDX token holdings required to create a proposal
        // (e.g. 500000e18 ~ 1% of pre-mine DDX supply)
        uint32 proposalThreshold;
        // Number of for or against votes that are necessary to skip
        // the remainder of the voting period
        // (e.g. 25000000e18 tokens/votes)
        uint32 skipRemainingVotingThreshold;
        // Time (s) proposals must be queued before executing
        uint32 timelockDelay;
        // Total number of proposals
        uint128 proposalCount;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION_GOVERNANCE =
        keccak256("diamond.standard.diamond.storage.DerivaDEX.Governance");

    function diamondStorageGovernance() internal pure returns (DiamondStorageGovernance storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION_GOVERNANCE;
        assembly {
            ds_slot := position
        }
    }
}