// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Governor, IGovernor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCompatibilityBravo} from "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import {GovernorVotes, IVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl, TimelockController} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

/// @title Governor OLAS - Smart contract for Autonolas governance
/// @author Aleksandr Kuperman - <[email protected]>
/// @dev The OpenZeppelin functions are used as is, version 4.8.3.
contract GovernorOLAS is Governor, GovernorSettings, GovernorCompatibilityBravo, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(
        IVotes governanceToken,
        TimelockController timelock,
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold,
        uint256 quorumFraction
    )
        Governor("Governor OLAS")
        GovernorSettings(initialVotingDelay, initialVotingPeriod, initialProposalThreshold)
        GovernorVotes(governanceToken)
        GovernorVotesQuorumFraction(quorumFraction)
        GovernorTimelockControl(timelock)
    {}

    /// @dev Current state of a proposal, following Compound’s convention.
    /// @param proposalId Proposal Id.
    function state(uint256 proposalId) public view override(IGovernor, Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /// @dev Create a new proposal to change the protocol / contract parameters.
    /// @param targets The ordered list of target addresses for calls to be made during proposal execution.
    /// @param values The ordered list of values to be passed to the calls made during proposal execution.
    /// @param calldatas The ordered list of data to be passed to each individual function call during proposal execution.
    /// @param description A human readable description of the proposal and the changes it will enact.
    /// @return The Id of the newly created proposal.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(IGovernor, Governor, GovernorCompatibilityBravo) returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    /// @dev Gets the voting power for the proposal threshold.
    /// @return The voting power required in order for a voter to become a proposer.
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256)
    {
        return super.proposalThreshold();
    }

    /// @dev Executes a proposal.
    /// @param proposalId Proposal Id.
    /// @param targets The ordered list of target addresses.
    /// @param values The ordered list of values.
    /// @param calldatas The ordered list of data to be passed to each individual function call.
    /// @param descriptionHash Hashed description of the proposal.
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /// @dev Cancels a proposal.
    /// @param targets The ordered list of target addresses.
    /// @param values The ordered list of values.
    /// @param calldatas The ordered list of data to be passed to each individual function call.
    /// @param descriptionHash Hashed description of the proposal.
    /// @return The Id of the newly created proposal.
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /// @dev Gets the executor address.
    /// @return Executor address.
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address)
    {
        return super._executor();
    }

    /// @dev Gets information about the interface support.
    /// @param interfaceId A specified interface Id.
    /// @return True if this contract implements the interface defined by interfaceId.
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}