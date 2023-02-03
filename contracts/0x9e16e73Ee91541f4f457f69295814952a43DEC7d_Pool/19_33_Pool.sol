// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./governor/GovernorProposals.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/registry/IRecordsRegistry.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev These contracts are instances of on-chain implementations of user companies. The shareholders of the companies work with them, their addresses are used in the Registry contract as tags that allow obtaining additional legal information (before the purchase of the company by the client). They store legal data (after the purchase of the company by the client). Among other things, the contract is also the owner of the Token and TGE contracts.
/// @dev There can be an unlimited number of such contracts, including for one company owner. The contract can be in three states: 1) the company was created by the administrator, a record of it is stored in the Registry, but the contract has not yet been deployed and does not have an owner (buyer) 2) the contract is deployed, the company has an owner, but there is not yet a successful (softcap primary TGE), in this state its owner has the exclusive right to recreate the TGE in case of their failure (only one TGE can be launched at the same time) 3) the primary TGE ended successfully, softcap is assembled - the company has received the status of DAO.    The owner no longer has any exclusive rights, all the actions of the company are carried out through the creation and execution of propousals after voting. In this status, the contract is also a treasury - it stores the company's values in the form of ETH and/or ERC20 tokens.
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    GovernorProposals,
    IPool
{
    /// @dev The company's trade mark, label, brand name. It also acts as the Name of all the Governance tokens created for this pool.
    string public trademark;

    /// @dev When a buyer acquires a company, its record disappears from the Registry contract, but before that, the company's legal data is copied to this variable.
    IRegistry.CompanyInfo public companyInfo;

    /// @dev A list of tokens belonging to this pool. There can be only one valid Governance token and only one Preference token.
    mapping(IToken.TokenType => address) public tokens;

    /// @dev last proposal id for address. This method returns the proposal Id for the last proposal created by the specified address. 
    mapping(address => uint256) public lastProposalIdForAddress;

    // EVENTS

    /**
     * @dev Special event that is released when the receive method is used. Thus, it is possible to make the receipt of ETH by the contract more noticeable.
     * @param amount Amount of received ETH
     */
    event Received(uint256 amount);

    // MODIFIER
    /// @dev Is executed when the main contract is applied. It is used to transfer control of Registry and deployable user contracts for the final configuration of the company.
    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier onlyServiceAdmin() {
        require(
            service.hasRole(service.ADMIN_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_SERVICE_OWNER
        );
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(this), ExceptionsLibrary.NOT_POOL);
        _;
    }

    modifier onlyExecutor(uint256 proposalId) {
        if (
            proposals[proposalId].meta.proposalType ==
            IRecordsRegistry.EventType.Transfer
        ) {
            require(
                service.hasRole(service.EXECUTOR_ROLE(), msg.sender),
                ExceptionsLibrary.INVALID_USER
            );
        }
        _;
    }

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialization of a new pool and placement of user settings and data (including legal ones) in it
     * @param companyInfo_ Company info
     * @param owner_ Pool owner
     * @param trademark_ Trademark
     * @param governanceSettings_ GovernanceSettings_
     */
    function initialize(
        address owner_,
        string memory trademark_,
        NewGovernanceSettings memory governanceSettings_,
        IRegistry.CompanyInfo memory companyInfo_
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __GovernorProposals_init(IService(msg.sender));

        _transferOwnership(owner_);
        trademark = trademark_;
        _setGovernanceSettings(governanceSettings_);
        companyInfo = companyInfo_;
    }

    // RECEIVE
    /// @dev Method for receiving an Ethereum contract that issues an event.
    receive() external payable {
        emit Received(msg.value);
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev With this method, the owner of the Governance token of the pool can vote for one of the active propo-nodes, specifying its number and the value of the vote (for or against). One user can vote only once for one proposal with all the available balance that is in delegation at once.
     * @param proposalId Pool proposal ID
     * @param support Against or for
     */
    function castVote(uint256 proposalId, bool support)
        external
        nonReentrant
        whenNotPaused
    {
        _castVote(proposalId, support);
    }

    // RESTRICTED PUBLIC FUNCTIONS

    /**
     * @dev Adding a new entry about the deployed token contract to the list of tokens related to the pool.
     * @param token_ Token address
     * @param tokenType_ Token type
     */
    function setToken(address token_, IToken.TokenType tokenType_)
        external
        onlyService
    {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tokens[tokenType_] = token_;
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     */
    function executeProposal(uint256 proposalId)
        external
        whenNotPaused
        onlyExecutor(proposalId)
    {
        _executeProposal(proposalId, service);
    }

    /**
     * @dev Cancel proposal, callable only by Service
     * @param proposalId Proposal ID
     */
    function cancelProposal(uint256 proposalId) external onlyService {
        _cancelProposal(proposalId);
    }

    /**
     * @dev Pause pool and corresponding TGEs and Tokens
     */
    function pause() public onlyServiceAdmin {
        _pause();
    }

    /**
     * @dev Unpause pool and corresponding TGEs and Tokens
     */
    function unpause() public onlyServiceAdmin {
        _unpause();
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Getter showing whether this company has received the status of a DAO as a result of the successful completion of the primary TGE (that is, launched by the owner of the company and with the creation of a new Governance token). After receiving the true status, it is not transferred back. This getter is responsible for the basic logic of starting a contract as managed by token holders.
     * @return Is any governance TGE successful
     */
    function isDAO() external view returns (bool) {
        return
            IToken(tokens[IToken.TokenType.Governance])
                .isPrimaryTGESuccessful();
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
    /// @dev This getter is needed in order to return a Token contract address depending on the type of token requested (Governance or Preference).
    function getToken(IToken.TokenType tokenType)
        external
        view
        returns (IToken)
    {
        return IToken(tokens[tokenType]);
    }

    // INTERNAL FUNCTIONS

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Function that gets amount of votes for given account
     * @param account Account's address
     * @return Amount of votes
     */
    function _getCurrentVotes(address account)
        internal
        view
        override
        returns (uint256)
    {
        return IToken(tokens[IToken.TokenType.Governance]).getVotes(account);
    }

    /**
     * @dev This getter returns the maximum number of votes distributed among the holders of the Governance token of the pool, which is equal to the sum of the balances of all addresses, except TGE, holding tokens in vesting, where they cannot have voting power. The getter's answer is valid for the current block.
     * @return Amount of votes
     */
    function _getCurrentTotalVotes() internal view override returns (uint256) {
        IToken token = IToken(tokens[IToken.TokenType.Governance]);
        return token.totalSupply() - token.getTotalTGEVestedTokens();
    }

    /**
     * @dev Function that gets amount of votes for given account at given block
     * @param account Account's address
     * @param blockNumber Block number
     * @return Account's votes at given block
     */
    function _getPastVotes(address account, uint256 blockNumber)
        internal
        view
        override
        returns (uint256)
    {
        return
            IToken(tokens[IToken.TokenType.Governance]).getPastVotes(
                account,
                blockNumber
            );
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

    /**
     * @dev This function stores the proposal id for the last proposal created by the proposer address.
     * @param proposer Proposer's address
     * @param proposalId Proposal id
     */
    function _setLastProposalIdForAddress(address proposer, uint256 proposalId) internal override {
        lastProposalIdForAddress[proposer] = proposalId;
    }
}