// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./MntVotes.sol";
import "./MntErrorCodes.sol";

contract MntGovernor is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    GovernorTimelockControlUpgradeable
{
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    constructor() initializer {} /* solhint-disable-line no-empty-blocks */

    function initialize(ERC20VotesUpgradeable _token, TimelockControllerUpgradeable _timelock) external initializer {
        __Governor_init("MntGovernor");
        __GovernorSettings_init(
            720, // Set voting delay between the proposal and voting period to 3 hours (in blocks, 15 second per block)
            40320, // Set voting period to 1 week of (in blocks, 15 second per block)
            100e18 // Set minimal voting power required to create the proposal to 100 MNT
        );
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);

        // Set % of quorum required for a proposal to pass. Usually it is about 4% of total token supply
        // available. We use Buyback weights as voting power, it is available only for accounts that
        // committed to perform voting actions by participating in Buyback, so quorum is going to be
        // much higher. We set 30% votes of the participants that vote For or Abstain for proposal to be applied
        __GovernorVotesQuorumFraction_init(30);
        __GovernorTimelockControl_init(_timelock);
    }

    /**
     * @dev Modifier to make a function callable only by a proposer role defined in timelock contract.
     */
    modifier onlyProposer() {
        AccessControlUpgradeable ac = AccessControlUpgradeable(timelock());
        require(ac.hasRole(PROPOSER_ROLE, msg.sender), MntErrorCodes.UNAUTHORIZED);
        _;
    }

    /**
     * @dev Modifier to make a function callable only by a proposer role defined in timelock contract. In
     * addition to checking the sender's role, `address(0)` 's role is also considered. Granting a role
     * to `address(0)` is equivalent to enabling this role for everyone.
     */
    modifier onlyProposerOrOpenRole() {
        AccessControlUpgradeable ac = AccessControlUpgradeable(timelock());
        require(
            ac.hasRole(PROPOSER_ROLE, msg.sender) || ac.hasRole(PROPOSER_ROLE, address(0)),
            MntErrorCodes.UNAUTHORIZED
        );
        _;
    }

    // The following functions are overrides required by Solidity.

    /// @notice Delay (in number of blocks) since the proposal is submitted until voting power is fixed and voting
    /// starts. This can be used to enforce a delay after a proposal is published for users to buy tokens,
    /// or delegate their votes.
    function votingDelay() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    /// @notice Delay (in number of blocks) since the proposal starts until voting ends.
    function votingPeriod() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    /// @notice Quorum required for a proposal to be successful. This function includes a blockNumber argument so
    /// the quorum can adapt through time
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /// @notice Voting power of an account at a specific blockNumber.
    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernorUpgradeable, GovernorVotesUpgradeable)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    /// @notice Current state of a proposal, see the { ProposalState } for details.
    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /// @notice Create a new proposal. Vote start votingDelay blocks after the proposal is created and ends
    /// votingPeriod blocks after the voting starts. Emits a ProposalCreated event.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(GovernorUpgradeable, IGovernorUpgradeable) onlyProposerOrOpenRole returns (uint256) {
        MntVotes(address(token)).updateTotalVotes();
        return super.propose(targets, values, calldatas, description);
    }

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    // slither-disable-next-line dead-code
    function _execute(
        uint256,
        address[] memory,
        uint256[] memory,
        bytes[] memory,
        bytes32
    ) internal pure override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        revert();
    }

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external onlyProposer returns (uint256) {
        return _cancel(targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal override returns (uint256) {
        // We write the timestamp of the last vote of the account
        MntVotes mntVotes = MntVotes(address(token));
        mntVotes.setLastVotingTimestamp(account, block.timestamp);
        return super._castVote(proposalId, account, support, reason);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}