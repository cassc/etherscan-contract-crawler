// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IGovernor, Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {IVotes, GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {TimelockController, GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct GovernorParams {
    uint256 votingDelay;
    uint256 votingPeriod;
    uint256 proposalThreshold;
    uint256 quorumFraction;
}

/// @title UXDGoverner
/// @notice Provides governance for the UXD protocol.
/// @dev UXDGovernor is an implementation of the OpenZeppelin Governor system.
/// The following modules in the OpenZeppelin governor system are used:
/// - Governor: The governance executor that manages and executes governance proposals.
/// - GovernorVotes: For extracting votes out of on ERC20Votes token (UXP).
/// - GovernorVotesQuorumFraction: Sets the quorum as a fraction of total token supply.
/// - GovernorTimelockControl: Controls the delay between a proposal passing and being executed.
/// - GovernorCountingSimple: Provides simple rules for counting votes.
/// - GovernorSettings: Allows for changing the voting delay, voting period, and proposal threshold.
/// The order of specifying the base contracts matters as overridden methods are called
/// based on C3 linearization:
/// https://docs.soliditylang.org/en/v0.8.13/contracts.html#multiple-inheritance-and-linearization
contract UXDGovernor is
    ReentrancyGuard,
    Governor,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    GovernorCountingSimple,
    GovernorSettings
{
    ///         Errors
    error GovERC20ApprovalFailed(address token, address to, uint256 amount);

    using SafeERC20 for IERC20;

    constructor(IVotes _token, TimelockController _timelock, GovernorParams memory _params)
        Governor("UXDGovernor")
        GovernorVotes(_token)
        GovernorSettings(_params.votingDelay, _params.votingPeriod, _params.proposalThreshold)
        GovernorVotesQuorumFraction(_params.quorumFraction)
        GovernorTimelockControl(_timelock)
    {}

    ///////////////////////////////////////////////////////////////////
    ///                 GovernorSettings
    ///////////////////////////////////////////////////////////////////
    /// @notice The delay between proposal creation and when voting starts.
    /// @dev Delay, in number of block, between the proposal is created and the vote starts.
    /// This can be increased to leave time for users to buy voting power, or delegate it,
    /// before the voting of a proposal starts.
    /// @return votingDelay in number of blocks between proposal creation and voting start.
    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    // /// @notice The length of time users can vote on a proposal.
    // /// @dev The number of blocks betwen vote start and vote end.
    // /// @return votingPeriod The number of blocks between vote start and end.
    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    /// @notice The number of votes required to become a proposer.
    /// @return threshold The number of votes required.
    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    // The functions below are overrides required by Solidity.

    /// @notice Returns the current state of a proposal
    /// @dev  State possiblities are:
    /// See {IGovernor-ProposalState} for the list of states
    /// @param proposalId the ID of proposal to check.
    /// @return state the current state of the proposal
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
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
        virtual
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    //////////////////////////////////////////////////////////////////////
    ///                 GovernorCountingSimple
    //////////////////////////////////////////////////////////////////////

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE()
        public
        pure
        virtual
        override(IGovernor, GovernorCountingSimple)
        returns (string memory)
    {
        return super.COUNTING_MODE();
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account)
        public
        view
        virtual
        override(IGovernor, GovernorCountingSimple)
        returns (bool)
    {
        return super.hasVoted(proposalId, account);
    }

    /// @notice Explain to an end user what this does
    /// @dev EIP-165 support https://github.com/ethereum/EIPs/issues/165
    /// this lets callers check if a given interface is supported
    /// @param interfaceId The id to check for
    /// @return true if the interfaceId is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /////////////////////////////////////////////////////////////
    ///                 Value transfers
    /////////////////////////////////////////////////////////////

    /// @notice Approve the transfer of an ERC20 token out of this contract.
    /// @dev Can only be called by governance.
    /// @param token The ERC20 token address.
    /// @param spender The address allowed to spend.
    /// @param amount The amount to transfer.
    function approveERC20(
        address token,
        address spender,
        uint256 amount
    ) external onlyGovernance {
        if (!(IERC20(token).approve(spender, amount))) {
            revert GovERC20ApprovalFailed(token, spender, amount);
        }
    }

    /// @notice Transfer ERC20 tokens out of this contract
    /// @dev Can only be called by governance.
    /// @param token The ERC20 token address.
    /// @param to The address to transfer token to
    /// @param amount The amount to transfer
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyGovernance nonReentrant {
        IERC20(token).safeTransfer(to, amount);
    }
}