// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "./BaseTokenholderGovernor.sol";

contract TokenholderGovernor is BaseTokenholderGovernor {
    uint256 private constant INITIAL_QUORUM_NUMERATOR = 150; // Defined in basis points, i.e., 1.5%
    uint256 private constant INITIAL_PROPOSAL_THRESHOLD_NUMERATOR = 25; // Defined in basis points, i.e., 0.25%
    uint256 private constant INITIAL_VOTING_DELAY =
        2 days / AVERAGE_BLOCK_TIME_IN_SECONDS;
    uint256 private constant INITIAL_VOTING_PERIOD =
        10 days / AVERAGE_BLOCK_TIME_IN_SECONDS;
    uint64 private constant INITIAL_VOTING_EXTENSION =
        uint64(2 days) / AVERAGE_BLOCK_TIME_IN_SECONDS;

    constructor(
        T _token,
        IVotesHistory _staking,
        TimelockController _timelock,
        address vetoer
    )
        BaseTokenholderGovernor(
            _token,
            _staking,
            _timelock,
            vetoer,
            INITIAL_QUORUM_NUMERATOR,
            INITIAL_PROPOSAL_THRESHOLD_NUMERATOR,
            INITIAL_VOTING_DELAY,
            INITIAL_VOTING_PERIOD,
            INITIAL_VOTING_EXTENSION
        )
    {}
}