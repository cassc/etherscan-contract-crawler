// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGovernor, Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {TimelockController, GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {IRegistry} from "./interfaces/IRegistry.sol";

/// @custom:security-contact [email protected]
contract MAHAXGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorTimelockControl
{
    IRegistry public immutable registry;
    uint256 private _quorum;

    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);

    constructor(
        IRegistry _registry,
        TimelockController _timelock,
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold,
        uint256 quorum
    )
        Governor("MAHAXGovernor")
        GovernorSettings(
            initialVotingDelay,
            initialVotingPeriod,
            initialProposalThreshold
        )
        GovernorTimelockControl(_timelock)
    {
        registry = _registry;
        _updateQuorum(quorum);
    }

    // The following functions are overrides required by Solidity.

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

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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