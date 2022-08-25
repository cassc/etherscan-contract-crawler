pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

error ArrayLengthError();
error ZeroAddress();
error PastBootstrapPhase();
error NotAuthorized();
error NoProposals();
error NoExecution();

contract BSNGovernor is Initializable,
                        GovernorUpgradeable, // Base governor
                        GovernorSettingsUpgradeable, // Updateable params through proposal
                        GovernorCountingSimpleUpgradeable, // Allow voting for, against, abstain
                        GovernorVotesUpgradeable, // Allow token based voting
                        GovernorVotesQuorumFractionUpgradeable, // Proposal voting threshold parameter
                        UUPSUpgradeable // Upgrading governor
{
    /// @notice Emitted when a new bootstrap proposer has been whitelisted
    event BoostrapProposerAdded(address indexed proposer);

    /// @notice Emitted when the bootstrap period end block has been updated
    event BootstrapEndBlockUpdated();

    /// @notice Block number when restricted proposals end
    uint256 public bootstrapEndBlock;

    /// @notice Given an address, will return true or false depending on whether it is allowed to make proposals during bootstrap period
    mapping(address => bool) public isBootstrapProposer;

    modifier onlyBootstrapProposerInBootstrapPeriod() {
        if (!isInBootstrapMode()) revert PastBootstrapPhase();
        if (!isBootstrapProposer[msg.sender]) revert NotAuthorized();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializer method called by the proxy
    /// @param _token Address of the token that will have voting power
    /// @param _quorumNumerator As a whole number, the percentage of voting power that must either vote 'for' or 'abstain' for each proposal
    /// @param _initialVotingDelayInBlocks How many blocks after a proposal is created should voting power be fixed
    /// @param _initialVotingPeriodInBlocks How many blocks does a proposal remain open to votes.
    /// @param _initialProposalThreshold The minimum number of tokens needed to create a proposal
    function init(
        ERC20VotesUpgradeable _token,
        uint256 _quorumNumerator,
        uint256 _initialVotingDelayInBlocks,
        uint256 _initialVotingPeriodInBlocks,
        uint256 _initialProposalThreshold,
        uint256 _bootstrapEndBlock,
        address[] calldata _initialBootstrapProposers
    ) external initializer
    {
        __Governor_init("BSNGovernor");
        __GovernorSettings_init(_initialVotingDelayInBlocks, _initialVotingPeriodInBlocks, _initialProposalThreshold);
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(_quorumNumerator);
        __UUPSUpgradeable_init();

        bootstrapEndBlock = _bootstrapEndBlock;

        uint256 numOfBootstrapProposers = _initialBootstrapProposers.length;
        if (numOfBootstrapProposers <= 1) revert ArrayLengthError();

        for (uint256 i; i < numOfBootstrapProposers; ++i) {
            address _initialBootstrapProposer = _initialBootstrapProposers[i];

            if(_initialBootstrapProposer == address(0)) revert ZeroAddress();

            isBootstrapProposer[_initialBootstrapProposer] = true;

            emit BoostrapProposerAdded(_initialBootstrapProposer);
        }
    }

    /// @dev Governance can vote to upgrade the DAO contract
    function _authorizeUpgrade(address)
    internal
    onlyGovernance
    override
    {}

    /// @notice Allow governance to update the end block if we are still in the bootstrap phase
    function updateBootstrapEndBlock(uint256 _newEnd) external onlyBootstrapProposerInBootstrapPeriod {
        bootstrapEndBlock = _newEnd;
        emit BootstrapEndBlockUpdated();
    }

    /// @dev Allows a boostrap proposer to add further bootstrap proposers
    function addBootstrapProposer(address _proposer) external onlyBootstrapProposerInBootstrapPeriod {
        isBootstrapProposer[_proposer] = true;
        emit BoostrapProposerAdded(_proposer);
    }

    /// @notice For a given proposal, whether the vote was successful based on the configured voting rules
    function voteSucceeded(uint256 _proposalId) external view returns (bool) {
        return _voteSucceeded(_proposalId);
    }

    /// @dev In bootstrap mode, proposals always succeed
    function _voteSucceeded(uint256 _proposalId) internal view override(GovernorUpgradeable, GovernorCountingSimpleUpgradeable) returns (bool) {
        if (isInBootstrapMode()) return true;
        return super._voteSucceeded(_proposalId);
    }

    /// @notice Allows token holders to propose transactions for the DAO to execute
    /// @dev During bootstrap mode, only whitelisted accounts are allowed to propose
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        string memory _description
    )
    public
    override
    returns (uint256)
    {
        if (isInBootstrapMode() && !isBootstrapProposer[msg.sender]) revert NoProposals();
        return super.propose(
            _targets,
            _values,
            _calldatas,
            _description
        );
    }

    /// @dev During bootstrap mode, only whitelisted accounts are allowed to execute proposals
    function execute(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        bytes32 _descriptionHash
    ) public payable override returns (uint256) {
        if (isInBootstrapMode() && !isBootstrapProposer[msg.sender]) revert NoExecution();
        return super.execute(
            _targets,
            _values,
            _calldatas,
            _descriptionHash
        );
    }

    /// @notice Length of time that voters have to rage quit their position before a proposal accepts votes
    function votingDelay()
    public
    view
    override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
    {
        if (isInBootstrapMode()) return 0;
        return super.votingDelay();
    }

    /// @notice Length of time a proposal remains open to votes
    function votingPeriod()
    public
    view
    override(IGovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
    {
        if (isInBootstrapMode()) return 0;
        return super.votingPeriod();
    }

    /// @notice Quorum required before proposal has a chance of succeeding
    function quorum(uint256 blockNumber)
    public
    view
    override(IGovernorUpgradeable, GovernorVotesQuorumFractionUpgradeable)
    returns (uint256)
    {
        if (isInBootstrapMode()) return 0;
        return super.quorum(blockNumber);
    }

    /// @notice Total number of votes that an account has at a particular block number
    function getVotes(address account, uint256 blockNumber)
    public
    view
    override(IGovernorUpgradeable, GovernorVotesUpgradeable)
    returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    /// @notice After boostrap, minimum number of tokens required for submitting a proposal
    function proposalThreshold()
    public
    view
    override(GovernorUpgradeable, GovernorSettingsUpgradeable)
    returns (uint256)
    {
        if (isInBootstrapMode()) return 0;
        return super.proposalThreshold();
    }

    /// @notice Bootstrap mode is enabled when the end block is set to a far future block number
    function isInBootstrapMode()
    public
    view
    returns (bool) {
        return block.number < bootstrapEndBlock;
    }
}