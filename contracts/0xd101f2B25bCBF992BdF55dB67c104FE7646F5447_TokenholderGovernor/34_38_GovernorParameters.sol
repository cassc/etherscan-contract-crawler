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

import "@openzeppelin/contracts/governance/Governor.sol";

/// @title GovernorParameters
/// @notice Abstract contract to handle governance parameters
/// @dev Based on `GovernorVotesQuorumFraction`, but without being opinionated
///      on what's the source of voting power, and extended to handle proposal
///      thresholds too. See OpenZeppelin's GovernorVotesQuorumFraction,
///      GovernorVotes and GovernorSettings for reference.
abstract contract GovernorParameters is Governor {
    uint256 public constant FRACTION_DENOMINATOR = 10000;
    uint64 internal constant AVERAGE_BLOCK_TIME_IN_SECONDS = 13;

    uint256 public quorumNumerator;
    uint256 public proposalThresholdNumerator;

    uint256 private _votingDelay;
    uint256 private _votingPeriod;

    event QuorumNumeratorUpdated(
        uint256 oldQuorumNumerator,
        uint256 newQuorumNumerator
    );

    event ProposalThresholdNumeratorUpdated(
        uint256 oldThresholdNumerator,
        uint256 newThresholdNumerator
    );

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    constructor(
        uint256 quorumNumeratorValue,
        uint256 proposalNumeratorValue,
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod
    ) {
        _updateQuorumNumerator(quorumNumeratorValue);
        _updateProposalThresholdNumerator(proposalNumeratorValue);
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
    }

    function updateQuorumNumerator(uint256 newQuorumNumerator)
        external
        virtual
        onlyGovernance
    {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    function updateProposalThresholdNumerator(uint256 newNumerator)
        external
        virtual
        onlyGovernance
    {
        _updateProposalThresholdNumerator(newNumerator);
    }

    /// @notice Update the voting delay. This operation can only be performed
    ///         through a governance proposal. Emits a `VotingDelaySet` event.
    function setVotingDelay(uint256 newVotingDelay)
        external
        virtual
        onlyGovernance
    {
        _setVotingDelay(newVotingDelay);
    }

    /// @notice Update the voting period. This operation can only be performed
    ///         through a governance proposal. Emits a `VotingPeriodSet` event.
    function setVotingPeriod(uint256 newVotingPeriod)
        external
        virtual
        onlyGovernance
    {
        _setVotingPeriod(newVotingPeriod);
    }

    /// @notice Compute the required amount of voting power to reach quorum
    /// @param blockNumber The block number to get the quorum at
    function quorum(uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return
            (_getPastTotalSupply(blockNumber) * quorumNumerator) /
            FRACTION_DENOMINATOR;
    }

    /// @notice Compute the required amount of voting power to create a proposal
    ///         at the last block height
    /// @dev This function is implemented to comply with Governor API but we
    ///      we will actually use `proposalThreshold(uint256 blockNumber)`,
    ///      as in our DAOs the threshold amount changes according to supply.
    function proposalThreshold()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return proposalThreshold(block.number - 1);
    }

    /// @notice Compute the required amount of voting power to create a proposal
    /// @param blockNumber The block number to get the proposal threshold at
    function proposalThreshold(uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        return
            (_getPastTotalSupply(blockNumber) * proposalThresholdNumerator) /
            FRACTION_DENOMINATOR;
    }

    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    function _updateQuorumNumerator(uint256 newQuorumNumerator)
        internal
        virtual
    {
        require(
            newQuorumNumerator <= FRACTION_DENOMINATOR,
            "quorumNumerator > Denominator"
        );

        uint256 oldQuorumNumerator = quorumNumerator;
        quorumNumerator = newQuorumNumerator;

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }

    function _updateProposalThresholdNumerator(uint256 proposalNumerator)
        internal
        virtual
    {
        require(
            proposalNumerator <= FRACTION_DENOMINATOR,
            "proposalNumerator > Denominator"
        );

        uint256 oldNumerator = proposalThresholdNumerator;
        proposalThresholdNumerator = proposalNumerator;

        emit ProposalThresholdNumeratorUpdated(oldNumerator, proposalNumerator);
    }

    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "Voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /// @notice Compute the past total voting power at a particular block
    /// @param blockNumber The block number to get the vote power at
    // slither-disable-next-line dead-code
    function _getPastTotalSupply(uint256 blockNumber)
        internal
        view
        virtual
        returns (uint256);
}