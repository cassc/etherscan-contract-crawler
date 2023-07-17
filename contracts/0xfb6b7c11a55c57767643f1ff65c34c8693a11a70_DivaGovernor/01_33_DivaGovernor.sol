// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GovernorTimelockControlConfigurable.sol";
import "./GovernorCountingThresholds.sol";
import "./DivaTimelockController.sol";

/**
 * @dev A cancellation proposal cannot have a value
 */
error CancellationProposalCannotHaveValue();

/**
 * @dev Updating quorum to a value lower than the minimum quorum
 */
error QuorumTooLow(uint256 quorum, uint256 minQuorum);

/**
 * @title DivaGovernor Contract
 * @author ShamirLabs
 * @notice DivaGovernor is an Open Zeppelin governor contract with customizations for the
 * success thresholds and timelock controller aiming to securize the governance process while
 * avoiding the need of roles and permissions.
 * The main features are:
 * - proposal threshold, anyone with a minimum amount of voting power can create a proposal.
 * - voting delay, after the proposal is submitted on-chain, there is a waiting period where token
 * holders can delegate their voting power.
 * - voting period, after the voting delay, the proposal can be voted on-chain.
 * - absolute quorum
 * - a successful proposal is queued in the timelock controller.
 * - a successful proposal can be executed after the timelock delay.
 *
 * A successful proposal can be enqueued by anyone.
 * A successful proposal can be executed by anyone.
 *
 * Any potentially malicious proposal can be cancelled by governance with another proposal with reduced
 * timelock waiting period.
 */
contract DivaGovernor is
    Governor,
    GovernorSettings,
    GovernorVotes,
    GovernorTimelockControlConfigurable,
    GovernorCountingThresholds
{
    uint256 public constant MIN_QUORUM = 5_000_000_000_000_000_000_000_000; // 5 M DIVA tokens is the minimum quorum.

    struct GovernanceParameters {
        string governorName;
        uint16 votingDelay;
        uint32 votingPeriod;
        uint256 quorumAbsolute;
        uint256 proposalThreshold;
        uint256 defaultDelay;
        uint256 shortDelay;
        uint256 longDelay;
        bytes4[] functionSignatures;
        DelayType[] functionDelays;
        ThresholdType[] functionThresholds;
    }

    uint256 private _quorum;

    /**
     * @dev Emitted when the quorum is updated.
     */
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);

    /**
     * @dev DivaGovernor Constructor
     * @param _token ERC20 token with ERC20Votes extension
     * @param _timelock DivaTimelockControlller instance
     * @param _settings governor settings
     */
    constructor(
        IVotes _token,
        DivaTimelockController _timelock,
        GovernanceParameters memory _settings
    )
        Governor(_settings.governorName)
        GovernorSettings(
            _settings.votingDelay,
            _settings.votingPeriod,
            _settings.proposalThreshold
        )
        GovernorVotes(_token)
        GovernorTimelockControlConfigurable(
            _timelock,
            _settings.functionSignatures,
            _settings.functionDelays,
            _settings.defaultDelay,
            _settings.shortDelay,
            _settings.longDelay
        )
        GovernorCountingThresholds(
            _settings.functionSignatures,
            _settings.functionThresholds
        )
    {
        _quorum = _settings.quorumAbsolute;
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
    function updateQuorum(uint256 newQuorum) external onlyGovernance {
        if (newQuorum < MIN_QUORUM) revert QuorumTooLow(newQuorum, MIN_QUORUM);
        uint256 oldQuorum = _quorum;
        _quorum = newQuorum;
        emit QuorumUpdated(oldQuorum, newQuorum);
    }

    /**
     * @dev Returns the quorum.
     */
    function quorum(uint256) public view override returns (uint256) {
        return _quorum;
    }

    // The following functions are overrides required by Solidity.

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

    /**
     * @dev Get the state of a proposal
     * @param proposalId id of the proposal
     */
    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControlConfigurable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @dev Submit a proposal on-chain
     * @param targets list of contracts to call
     * @param values list of values to pass in the call
     * @param calldatas list of calldatas for the call
     * @param description description of the proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, IGovernor) returns (uint256) {
        // @dev a cancellation proposal cannot have value.
        for (uint256 i = 0; i < calldatas.length; i++) {
            bytes4 sig = bytes4(calldatas[i]);
            if (sig == CANCEL_PROPOSAL_TYPEHASH && values[i] > 0)
                revert CancellationProposalCannotHaveValue();
        }

        _setSuccessThreshold(targets, values, calldatas, description);
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @dev Voting power need to be able to create a proposal
     */
    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    /**
     * @dev Execute a successful proposal
     * @param proposalId id of the proposal
     */
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControlConfigurable) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Cancel a proposal from governor. (Not publicly available in diva governor)
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Get the address of the executor
     */
    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControlConfigurable)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(Governor, GovernorTimelockControlConfigurable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}