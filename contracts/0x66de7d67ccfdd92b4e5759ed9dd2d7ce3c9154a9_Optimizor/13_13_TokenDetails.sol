// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IChallenge} from "src/IChallenge.sol";

struct TokenDetails {
    /// The ID of the challenge.
    uint256 challengeId;
    /// The address of the challenge contract.
    IChallenge challenge;
    /// Details of the leader (aka rank 1).
    uint32 leaderGas;
    uint32 leaderSolutionId;
    address leaderSolver;
    address leaderOwner;
    address leaderSubmission;
    /// Details of the current token (can be the same as the leader).
    uint32 gas;
    uint32 solutionId;
    uint32 rank;
    /// Improvement percentage compared to the previous rank.
    uint32 improvementPercentage;
    address solver;
    address owner;
    address submission;
}