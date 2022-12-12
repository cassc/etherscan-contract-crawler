// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IChallenge {
    enum ChallengeStatus {
        UDEFINED,
        CREATED,
        IN_AIRDROP,
        WITHDRAWN
    }
}