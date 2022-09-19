// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernor, Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";

/// @custom:security-contact [email protected]
contract MAHAXVetoGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple
{
    IRegistry public immutable registry;
    uint256 private _quorum;

    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);

    constructor(
        IRegistry _registry,
        uint256 _initialVotingDelay,
        uint256 _initialVotingPeriod,
        uint256 _initialProposalThreshold,
        uint256 __quorum
    )
        Governor("MAHAXVetoGovernor")
        GovernorSettings(
            _initialVotingDelay,
            _initialVotingPeriod,
            _initialProposalThreshold
        )
    {
        registry = _registry;
        _updateQuorum(__quorum);
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return IVotes(registry.staker()).getPastVotes(account, blockNumber);
    }

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    /**
     * @dev Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        return _quorum;
    }

    /**
     * @dev Changes the quorum.
     *
     * Emits a {QuorumUpdated} event.
     *
     * Requirements:
     *
     * - Must be called through a governance proposal.
     */
    function updateQuorum(uint256 newQuorum) external virtual onlyGovernance {
        _updateQuorum(newQuorum);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumUpdated} event.
     */
    function _updateQuorum(uint256 newQuorum) internal virtual {
        uint256 oldQuorum = _quorum;
        _quorum = newQuorum;
        emit QuorumUpdated(oldQuorum, newQuorum);
    }
}