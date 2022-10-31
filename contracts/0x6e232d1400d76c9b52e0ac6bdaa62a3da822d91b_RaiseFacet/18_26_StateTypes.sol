// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

library StateTypes {

    // structs: state tracking
    struct Voting {
        uint256 proposalId;
        bool unlocked;
    }
    struct ProjectInvestInfo {
        uint256 raised;
        mapping (address => uint256) invested;
    }
    struct InvestorVoteInfo {
        mapping (uint256 => bool) voted;
        mapping (uint256 => bool) claimed;
    }

}