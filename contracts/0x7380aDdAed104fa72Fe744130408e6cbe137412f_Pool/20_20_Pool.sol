// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./components/Governor.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IDispatcher.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Company Entry Point
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IPool,
    Governor
{
    /// @dev Service address
    IService public service;

    /// @dev Minimum amount of votes that ballot must receive
    uint256 public ballotQuorumThreshold;

    /// @dev Minimum amount of votes that ballot's choice must receive in order to pass
    uint256 public ballotDecisionThreshold;

    /// @dev Ballot voting duration, blocks
    uint256 public ballotLifespan;

    /// @dev Pool trademark
    string public trademark;

    /// @dev Pool jurisdiction
    uint256 public jurisdiction;

    /// @dev Pool EIN
    string public EIN;

    /// @dev Metadata pool record index
    uint256 public metadataIndex;

    /// @dev Pool entity type
    uint256 public entityType;

    /// @dev Pool date of incorporatio
    string public dateOfIncorporation;

    /**
     * @dev block delay for executeBallot
     * [0] - ballot value in USDT after which delay kicks in
     * [1] - base delay applied to all ballots to mitigate FlashLoan attacks.
     * [2] - delay for TransferETH proposals
     * [3] - delay for TransferERC20 proposals
     * [4] - delay for TGE proposals
     * [5] - delay for GovernanceSettings proposals
     */
    uint256[10] public ballotExecDelay;

    /// @dev last proposal id created by account
    mapping(address => uint256) public lastProposalIdForAccount;

    /// @dev Is pool launched or not
    bool public poolLaunched;

    /// @dev Pool tokens addresses
    mapping(IToken.TokenType => IToken) public tokens;

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Create TransferETH proposal
     * @param jurisdiction_ Jurisdiction
     * @param EIN_ EIN
     * @param dateOfIncorporation_ Date of incorporation
     * @param entityType_ Entity type
     * @param metadataIndex_ Metadata index
     */
    function initialize(
        uint256 jurisdiction_,
        string memory EIN_,
        string memory dateOfIncorporation_,
        uint256 entityType_,
        uint256 metadataIndex_
    ) external initializer {
        __Ownable_init();

        service = IService(IDispatcher(msg.sender).service());
        _transferOwnership(address(service));
        jurisdiction = jurisdiction_;
        EIN = EIN_;
        dateOfIncorporation = dateOfIncorporation_;
        entityType = entityType_;
        metadataIndex = metadataIndex_;
    }

    /**
     * @dev Create TransferETH proposal
     * @param owner_ Pool owner
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     * @param trademark_ Trademark
     */
    function launch(
        address owner_,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
        string memory trademark_
    ) external onlyService unlaunched {
        poolLaunched = true;
        _transferOwnership(owner_);

        service.dispatcher().validateBallotParams(
            ballotQuorumThreshold_,
            ballotDecisionThreshold_,
            ballotLifespan_, 
            ballotExecDelay_
        );

        trademark = trademark_;
        ballotQuorumThreshold = ballotQuorumThreshold_;
        ballotDecisionThreshold = ballotDecisionThreshold_;
        ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    /**
     * @dev Set pool preference token
     * @param token_ Token address
     * @param tokenType_ Token type
     */
    function setToken(address token_, IToken.TokenType tokenType_) external onlyService launched {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tokens[tokenType_] = IToken(token_);
    }

    /**
     * @dev Set Service governance settings
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     */
    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay_
    ) external onlyPool whenNotPaused launched {
        service.dispatcher().validateBallotParams(
            ballotQuorumThreshold_,
            ballotDecisionThreshold_,
            ballotLifespan_, 
            ballotExecDelay_
        );

        ballotQuorumThreshold = ballotQuorumThreshold_;
        ballotDecisionThreshold = ballotDecisionThreshold_;
        ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Cast ballot vote
     * @param proposalId Pool proposal ID
     * @param votes Amount of tokens
     * @param support Against or for
     */
    function castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) external nonReentrant whenNotPaused launched {
        if (votes == type(uint256).max) {
            votes = tokens[IToken.TokenType.Governance].unlockedBalanceOf(msg.sender, proposalId);
        } else {
            require(
                votes <= tokens[IToken.TokenType.Governance].unlockedBalanceOf(msg.sender, proposalId),
                ExceptionsLibrary.LOW_UNLOCKED_BALANCE
            );
        }
        require(votes > 0, ExceptionsLibrary.VALUE_ZERO);

        _castVote(proposalId, votes, support);
        tokens[IToken.TokenType.Governance].lock(
            msg.sender,
            votes,
            getProposal(proposalId).endBlock,
            proposalId
        );
    }

    /**
     * @dev Create pool proposal
     * @param target Proposal transaction recipient
     * @param value Amount of ETH token
     * @param cd Calldata to pass on in .call() to transaction recipient
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal ID
     */
    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash
    )
        external
        onlyProposalGateway
        whenNotPaused
        launched
        returns (uint256 proposalId)
    {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        values[0] = value;

        proposalId = _propose(
            ballotLifespan,
            ballotQuorumThreshold,
            ballotDecisionThreshold,
            targets,
            values,
            cd,
            description,
            _getTotalSupply() -
                _getTotalTGEVestedTokens() -
                tokens[IToken.TokenType.Governance].balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1), // --> ballotExecDelay(1)
            proposalType,
            metaHash,
            address(0)
        );
    }

    /**
     * @dev Create pool proposal
     * @param targets Proposal transaction recipients
     * @param values Amounts of ETH token
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     * @return proposalId Created proposal ID
     */
    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash,
        address token_
    )
        external
        onlyProposalGateway
        whenNotPaused
        launched
        returns (uint256 proposalId)
    {
        proposalId = _propose(
            ballotLifespan,
            ballotQuorumThreshold,
            ballotDecisionThreshold,
            targets,
            values,
            "",
            description,
            _getTotalSupply() -
                _getTotalTGEVestedTokens() -
                tokens[IToken.TokenType.Governance].balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1), // --> ballotExecDelay(1)
            proposalType,
            metaHash,
            token_
        );
    }

    function setLastProposalIdForAccount(address creator, uint256 proposalId) external onlyProposalGateway launched {
        lastProposalIdForAccount[creator] = proposalId;
    }

    /**
     * @dev Calculate pool TVL
     * @return Pool TVL
     */
    function getTVL() public returns (uint256) {
        IQuoter quoter = service.uniswapQuoter();
        IDispatcher dispatcher = service.dispatcher();
        address[] memory tokenWhitelist = dispatcher.tokenWhitelist();
        uint256 tvl = 0;

        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            if (tokenWhitelist[i] == address(0)) {
                tvl += address(this).balance;
            } else {
                uint256 balance = IERC20Upgradeable(tokenWhitelist[i])
                    .balanceOf(address(this));
                if (balance > 0) {
                    tvl += quoter.quoteExactInput(
                        dispatcher.tokenSwapPath(tokenWhitelist[i]),
                        balance
                    );
                }
            }
        }
        return tvl;
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     */
    function executeBallot(uint256 proposalId) external whenNotPaused launched {
        _executeBallot(proposalId, service);
    }

    /**
     * @dev Cancel proposal, callable only by Service
     * @param proposalId Proposal ID
     */
    function serviceCancelBallot(uint256 proposalId) external onlyService launched {
        _cancelBallot(proposalId);
    }

    /**
     * @dev Pause pool and corresponding TGEs and GovernanceToken
     */
    function pause() public onlyServiceOwner {
        _pause();
    }

    /**
     * @dev Pause pool and corresponding TGEs and GovernanceToken
     */
    function unpause() public onlyServiceOwner {
        _unpause();
    }

    // RECEIVE

    receive() external payable {
        // Supposed to be empty
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return maximum proposal ID
     * @return Maximum proposal ID
     */
    function maxProposalId() external view returns (uint256) {
        return lastProposalId;
    }

    /**
     * @dev Return if pool had a successful governance TGE
     * @return Is any governance TGE successful
     */
    function isDAO() external view returns (bool) {
        return tokens[IToken.TokenType.Governance].isPrimaryTGESuccessful();
    }

    /**
     * @dev Return pool owner
     * @return Owner address
     */
    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    function getBallotExecDelay() external view returns(uint256[10] memory) {
        return ballotExecDelay;
    }

    // INTERNAL FUNCTIONS

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Return token total supply
     * @return Total pool token supply
     */
    function _getTotalSupply() internal view override returns (uint256) {
        return tokens[IToken.TokenType.Governance].totalSupply();
    }

    /**
     * @dev Return amount of tokens currently vested in TGE vesting contract(s)
     * @return Total pool vesting tokens
     */
    function _getTotalTGEVestedTokens()
        internal
        view
        override
        returns (uint256)
    {
        return tokens[IToken.TokenType.Governance].getTotalTGEVestedTokens();
    }

    /**
     * @dev Return pool paused status
     * @return Is pool paused
     */
    function paused()
        public
        view
        override(IPool, PausableUpgradeable)
        returns (bool)
    {
        // Pausable
        return super.paused();
    }

    // MODIFIER

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier launched() {
        require(poolLaunched, ExceptionsLibrary.NOT_LAUNCHED);
        _;
    }

    modifier unlaunched() {
        require(!poolLaunched, ExceptionsLibrary.LAUNCHED);
        _;
    }

    modifier onlyServiceOwner() {
        require(
            msg.sender == service.owner(),
            ExceptionsLibrary.NOT_SERVICE_OWNER
        );
        _;
    }

    modifier onlyProposalGateway() {
        require(
            msg.sender == service.proposalGateway(),
            ExceptionsLibrary.NOT_DISPATCHER
        );
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(this), ExceptionsLibrary.NOT_POOL);
        _;
    }

    // function test83212() external pure returns (uint256) {
    //     return 3;
    // }
}