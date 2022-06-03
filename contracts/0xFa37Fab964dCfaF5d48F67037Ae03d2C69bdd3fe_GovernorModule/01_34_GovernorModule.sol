//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorPreventLateQuorumUpgradeable.sol";
import "@fractal-framework/core-contracts/contracts/ModuleBase.sol";
import "../interfaces/IGovernorModule.sol";

/// @dev Governor Module used to implement 1 token 1 vote.
/// This acts as an extension of the MVD and permissions are controlled by access control.
/// @dev Gov Module is extended by the timelock contract which creates a lockup period before execution.
contract GovernorModule is
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    GovTimelockUpgradeable,
    ModuleBase,
    GovernorPreventLateQuorumUpgradeable
{
    /// @dev Configures Gov Module implementation
    /// @dev Called once during deployment atomically
    /// @param _token Voting token uses snapshot feature
    /// @param _timelock Timelock vest proposals to allow detractors to exit system
    /// @param _initialVoteExtension Allow users to vote if quorum attack is preformed
    /// @param _initialVotingDelay Allow users to research proposals before voting period
    /// @param _initialVotingPeriod Length of voting period (blocks)
    /// @param _initialProposalThreshold Total tokens required to submit a proposal
    /// @param _initialQuorumNumeratorValue Total votes needed to reach quorum
    /// @param _accessControl Address of Access Control
    function initialize(
        IVotesUpgradeable _token,
        ITimelockUpgradeable _timelock,
        uint64 _initialVoteExtension,
        uint256 _initialVotingDelay,
        uint256 _initialVotingPeriod,
        uint256 _initialProposalThreshold,
        uint256 _initialQuorumNumeratorValue,
        address _accessControl
    ) external initializer {
        __Governor_init("Governor Module");
        __GovernorSettings_init(
            _initialVotingDelay,
            _initialVotingPeriod,
            _initialProposalThreshold
        );
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(_initialQuorumNumeratorValue);
        __GovTimelock_init(_timelock);
        __initBase(_accessControl, msg.sender, "Governor Module");
        __GovernorPreventLateQuorum_init(_initialVoteExtension);
    }

    // The following functions are overrides required by Solidity.

    /// @notice module:user-config
    /// @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
    /// leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
    function votingDelay()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingDelay();
    }

    /// @notice module:user-config
    /// @dev Delay, in number of blocks, between the vote start and vote ends.
    /// NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
    /// duration compared to the voting delay.
    function votingPeriod()
        public
        view
        override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    /// @notice module:user-config
    /// @dev Minimum number of cast voted required for a proposal to be successful.
    /// Note: The `blockNumber` parameter corresponds to the snaphot used for counting vote. This allows to scale the
    /// quroum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
    /// @param blockNumber Checkpoint at this blockNumber
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /// @notice module:reputation
    /// @dev Voting power of an `account` at a specific `blockNumber`.
    /// Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
    /// multiple), {ERC20Votes} tokens.
    /// @param account Voting weight of this Address
    /// @param blockNumber Checkpoint at this blockNumber
    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesUpgradeable)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    /// @dev Overriden version of the {Governor-state} function with added support for the `Queued` status.
    /// @param proposalId keccak256 hash of proposal params
    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovTimelockUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /// @notice module:core
    /// @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
    /// during this block.
    /// @param proposalId keccak256 hash of proposal params
    function proposalDeadline(uint256 proposalId)
        public
        view
        virtual
        override(
            GovernorPreventLateQuorumUpgradeable,
            GovernorUpgradeable,
            IGovernorUpgradeable
        )
        returns (uint256)
    {
        return super.proposalDeadline(proposalId);
    }

    /// @dev Function to cast vote for a proposal
    /// @param proposalId keccak256 hash of proposal params
    /// @param account Voting weight of this Address
    /// @param support For, Against, Abstain
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    )
        internal
        virtual
        override(GovernorUpgradeable, GovernorPreventLateQuorumUpgradeable)
        returns (uint256)
    {
        return super._castVote(proposalId, account, support, reason);
    }

    /// @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
    /// {IGovernor-votingPeriod} blocks after the voting starts.
    /// Emits a {ProposalCreated} event.
    /// @param targets Contract addresses the DAO will call
    /// @param values Ether values to be sent to the target address
    /// @param calldatas Function Sigs w/ Params
    /// @param description Description of proposal
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    )
        public
        override(GovernorUpgradeable, IGovernorUpgradeable)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    /// @dev Total vote weight required to create a proposal
    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    /// @dev Overriden execute function that run the already queued proposal through the timelock.
    /// @param proposalId keccak256 hash of proposal params
    /// @param targets Contract addresses the DAO will call
    /// @param values Ether values to be sent to the target address
    /// @param calldatas Function Sigs w/ Params 
    /// @param descriptionHash Description of proposal
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovTimelockUpgradeable) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /// @dev Overriden version of the {Governor-_cancel} function to cancel the timelocked proposal if it as already
    /// been queued.
    /// @param targets Contract addresses the DAO will call
    /// @param values Ether values to be sent to the target address
    /// @param calldatas Function Sigs w/ Params 
    /// @param descriptionHash Description of proposal
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        override(GovernorUpgradeable, GovTimelockUpgradeable)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /// @dev Address through which the governor executes action. In this case, the timelock.
    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovTimelockUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    /// @notice Returns the module name
    /// @return The module name
    function name() public view override(ModuleBase, GovernorUpgradeable, IGovernorUpgradeable) returns (string memory) {
      return _name;
    }

    /// @dev See {IERC165-supportsInterface}.
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, GovTimelockUpgradeable, ModuleBase)
        returns (bool)
    {
        return interfaceId == type(IGovernorModule).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}