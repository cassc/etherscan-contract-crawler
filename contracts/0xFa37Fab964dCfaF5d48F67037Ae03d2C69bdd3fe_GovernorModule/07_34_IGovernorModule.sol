//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "../Governor/GovTimelockUpgradeable.sol";

/// @dev Governor Module used to implement 1 token 1 vote.
/// This acts as an extension of the MVD and permissions are controlled by access control.
/// @dev Gov Module is extended by the timelock contract which creates a lockup period before execution.
interface IGovernorModule {
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
    ) external;

    // The following functions are overrides required by Solidity.

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice module:user-config
    /// @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
    /// leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
    function votingDelay() external view returns (uint256);

    /// @notice module:user-config
    /// @dev Delay, in number of blocks, between the vote start and vote ends.
    /// NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
    /// duration compared to the voting delay.
    function votingPeriod() external view returns (uint256);

    /// @notice module:user-config
    /// @dev Minimum number of cast voted required for a proposal to be successful.
    /// Note: The `blockNumber` parameter corresponds to the snaphot used for counting vote. This allows to scale the
    /// quroum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
    /// @param blockNumber Checkpoint at this blockNumber
    function quorum(uint256 blockNumber) external view returns (uint256);

    /// @notice module:reputation
    /// @dev Voting power of an `account` at a specific `blockNumber`.
    /// Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
    /// multiple), {ERC20Votes} tokens.
    /// @param account Voting weight of this Address
    /// @param blockNumber Checkpoint at this blockNumber
    function getVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);

    /// @dev Overriden version of the {Governor-state} function with added support for the `Queued` status.
    /// @param proposalId keccak256 hash of proposal params
    function state(uint256 proposalId) external view returns (ProposalState);

    /// @notice module:core
    /// @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
    /// during this block.
    /// @param proposalId keccak256 hash of proposal params
    function proposalDeadline(uint256 proposalId)
        external
        view
        returns (uint256);

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
    ) external returns (uint256);

    /// @dev Total vote weight required to create a proposal
    function proposalThreshold() external view returns (uint256);
}