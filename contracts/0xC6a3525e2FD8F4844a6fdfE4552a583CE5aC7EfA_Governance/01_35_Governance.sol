// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20Votes.sol";
import "GovernorSettings.sol";
import "GovernorVotesQuorumFraction.sol";
import "GovernorTimelockControl.sol";
import "GovernorPreventLateQuorum.sol";
import "GovernorCompatibilityBravo.sol";

contract Governance is
    GovernorSettings,
    GovernorCompatibilityBravo,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    GovernorPreventLateQuorum
{
    constructor(ERC20Votes _token, TimelockController _timelock)
        Governor("OUSD Governance")
        GovernorSettings(
            1, /* 1 block */
            32727, /* 5 days */
            5000000 * 1e18
        )
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4) // Default quorum denominator is 100, so 4/100 or 4%
        GovernorTimelockControl(_timelock)
        GovernorPreventLateQuorum(86400 / 15) // ~1 day
    {}

    // The following functions are overrides required by Solidity.

    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(Governor, GovernorCompatibilityBravo, IGovernor)
        returns (uint256)
    {
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
        override(Governor, IERC165, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function proposalDeadline(uint256 proposalId)
        public
        view
        virtual
        override(Governor, IGovernor, GovernorPreventLateQuorum)
        returns (uint256)
    {
        return super.proposalDeadline(proposalId);
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    )
        internal
        virtual
        override(Governor, GovernorPreventLateQuorum)
        returns (uint256)
    {
        return super._castVote(proposalId, account, support, reason, params);
    }
}