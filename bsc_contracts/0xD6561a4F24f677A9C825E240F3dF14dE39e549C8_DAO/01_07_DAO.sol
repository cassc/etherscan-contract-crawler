/************************************************************
 *
 * Autor: BotPlanet
 *
 * 446576656c6f7065723a20416e746f6e20506f6c656e79616b61 ****/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO is Ownable, ReentrancyGuard {
    // Structs

    struct User {
        uint256 balance;
        uint256 lastVoteEndTime;
        mapping(uint256 => bool) isVoted;
    }

    struct Proposal {
        address targetContract; // Target contract who receive quorum decision and call function with arguments
        bytes encodedMessage; // Message to send if quorum vote "true" to target contract (function + arguments)
        string description; // Description of proposal
        bool isFinished; // Indicate if this proposal is finished
        uint256 endTime; // When proposal is end and is not possible vote more
        uint256 consenting; // Sum of balances of users who voted "true". Is not number of users
        uint256 dissenters; // Sum of balances of users who voted "false". Is not number of users
        uint256 usersVotedTotal; // Count of user who voted true and false
        uint256 minumumUserTokens; // How many tokens is needed to vote. Zero is not allowed
        uint256 usersVotedTrue; // Count of user who voted true
    }

    // Events

    event Received(address indexed sender, uint256 amount);
    event ETHWithdrawn(address indexed receiver, uint256 indexed amount);

    event Credited(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);

    event ProposalAdded(uint256 indexed id, uint256 time);
    event Voted(address indexed user, uint256 indexed proposal, bool answer);
    event FinishedEmergency(uint indexed proposalId);
    event Finished(
        uint256 indexed ProposalId,
        bool status,
        address indexed targetContract,
        uint256 votesAmount,
        uint256 usersVotedTotal,
        uint256 usersVotedTrue
    );

    // Usings

    using Counters for Counters.Counter;

    // Attributies

    Counters.Counter private _proposalsCounter;
    Counters.Counter private _activeUsers;
    // Token used for vote
    IERC20 private _voteToken;
    // Miminum quorum % accepted in proposal
    uint256 private _minimumQuorum;
    // Time to vote in seconds
    uint256 private _debatingPeriodDuration;
    // Minimum sum of votes balances to accept proposal
    uint256 private _minimumVotes;
    mapping(address => User) private _users;
    mapping(uint256 => Proposal) private _proposals;

    // Modifiers

    modifier endProposalCondition(uint256 proposalId) {
        require(
            _proposals[proposalId].endTime <= block.timestamp,
            "DAO: Voting time is not over yet"
        );
        require(
            _proposals[proposalId].isFinished == false,
            "DAO: Voting has already ended"
        );
        _;
    }

    // Constructos

    constructor(
        address voteToken_,
        uint256 minimumQuorum_,
        uint256 debatingPeriodDuration_,
        uint256 minimumVotes_
    ) {
        _voteToken = IERC20(voteToken_);
        _minimumQuorum = minimumQuorum_;
        _debatingPeriodDuration = debatingPeriodDuration_;
        _minimumVotes = minimumVotes_;
    }

    // Public methods

    // Add proposal for vote by active users.
    // Signature param - encoded function with args.
    function addProposal(
        address targetContract_,
        bytes calldata signature_,
        string calldata description_,
        uint256 minumumUserTokens_
    ) external onlyOwner nonReentrant {
        uint256 current = _proposalsCounter.current();

        _proposals[current] = Proposal(
            targetContract_,
            signature_,
            description_,
            false,
            block.timestamp + _debatingPeriodDuration,
            0,
            0,
            0,
            minumumUserTokens_,
            0
        );

        _proposalsCounter.increment();
        emit ProposalAdded(current, block.timestamp);
    }

    // User deposit some tokens. Is necesary to allow vote in proposal
    function deposit(uint256 amount_) external {
        require(amount_ > 0, "DAO: Amount is 0");
        _voteToken.transferFrom(msg.sender, address(this), amount_);
        if (_users[msg.sender].balance == 0) {
            _activeUsers.increment();
        }
        _users[msg.sender].balance += amount_;
        emit Credited(msg.sender, amount_);
    }

    // User vote for proposal true or false
    function vote(uint256 proposalId_, bool answer_) external nonReentrant {
        require(_users[msg.sender].balance > 0, "DAO: No tokens on balance");
        require(
            _users[msg.sender].balance >=
                _proposals[proposalId_].minumumUserTokens,
            "DAO: Need more tokens to vote"
        );
        require(
            _proposals[proposalId_].endTime > block.timestamp,
            "DAO: The voting is already over or does not exist"
        );
        require(
            _users[msg.sender].isVoted[proposalId_] == false,
            "DAO: You have already voted in this proposal"
        );

        if (answer_) {
            _proposals[proposalId_].consenting += _users[msg.sender].balance;
            _proposals[proposalId_].usersVotedTrue++;
        } else {
            _proposals[proposalId_].dissenters += _users[msg.sender].balance;
        }

        _users[msg.sender].isVoted[proposalId_] = true;
        _users[msg.sender].lastVoteEndTime = _proposals[proposalId_].endTime;
        _proposals[proposalId_].usersVotedTotal++;

        emit Voted(msg.sender, proposalId_, answer_);
    }

    // Finish proposal when is ended period of vote.
    // If Quorum vote "true" - execute encoded message to target contract.
    // If Quorum vote "false" - don't do nothing
    function finishProposal(uint256 proposalId_)
        external
        endProposalCondition(proposalId_)
        nonReentrant
    {
        Proposal storage proposal = _proposals[proposalId_];

        uint256 votesAmount = proposal.consenting + proposal.dissenters;
        // The number of users is multiplied by 10 to the 3rd power
        // to eliminate errors, provided that users are less than 10 / 100
        uint256 votersPercentage = _calculateVotersPercentage();
        uint256 usersTrue = proposal.usersVotedTrue * 10**3;

        if (votesAmount >= _minimumVotes && usersTrue >= votersPercentage) {
            (bool success, bytes memory returnedData) = proposal
                .targetContract
                .call{value: 0}(proposal.encodedMessage);
            require(success, string(returnedData));

            emit Finished(
                proposalId_,
                true,
                proposal.targetContract,
                votesAmount,
                proposal.usersVotedTotal,
                proposal.usersVotedTrue
            );
        } else {
            emit Finished(
                proposalId_,
                false,
                proposal.targetContract,
                votesAmount,
                proposal.usersVotedTotal,
                proposal.usersVotedTrue
            );
        }
        proposal.isFinished = true;
    }

    // A function that can be called by proposal voting to end the voting urgently.
    function endProposal(uint256 proposalId_)
        external
        onlyOwner
        endProposalCondition(proposalId_)
    {
        _proposals[proposalId_].isFinished = true;
        emit FinishedEmergency(proposalId_);
    }

    // User is allowed to withdraw his tokens when is ended proposal time to vote
    function withdrawTokens(uint256 amount_) external {
        require(
            _users[msg.sender].balance >= amount_,
            "DAO: Insufficient funds on the balance"
        );
        require(
            _users[msg.sender].lastVoteEndTime < block.timestamp,
            "DAO: The last vote you participated in hasn't ended yet"
        );

        _users[msg.sender].balance -= amount_;

        if (_users[msg.sender].balance == 0) {
            _activeUsers.decrement();
        }

        emit TokensWithdrawn(msg.sender, amount_);
    }

    // Withdraw ETH/BNB/etc, contract need it in case of quorum vote "true" and is needed to execute function to target contract
    function withdrawETH(address payable to_, uint256 amount_)
        external
        onlyOwner
    {
        Address.sendValue(to_, amount_);
        emit ETHWithdrawn(to_, amount_);
    }

    // Receive ETH/BNB/etc needed to execute encoded message to target contract
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Get proposal information by id
    function getProposalById(uint256 id_)
        external
        view
        returns (Proposal memory)
    {
        return _proposals[id_];
    }

    // Getters associated with counters

    // Get last proposal id
    function getLastProposalId() external view returns (uint256) {
        return _proposalsCounter.current();
    }

    // Get number of active users with balance in DAO is greater zero
    function getActiveUsers() external view returns (uint256) {
        return _activeUsers.current();
    }

    // Getters associated with user

    // Check if user is voted for proposal by wallet address of user and proposal id
    function isUserVoted(address voter_, uint256 proposalId_)
        external
        view
        returns (bool)
    {
        return _users[voter_].isVoted[proposalId_];
    }

    // Get end time of voted last proposal by user
    function userLastVoteEndTime(address voter_)
        external
        view
        returns (uint256)
    {
        return _users[voter_].lastVoteEndTime;
    }

    // Get balance of user in DAO
    function getUserBalance(address voter_) external view returns (uint256) {
        return _users[voter_].balance;
    }

    // Getters associated with condition constants

    // Get token address contract used by balance of users
    function getToken() external view returns (address) {
        return address(_voteToken);
    }

    // Get minimum quorum to decision. Normaly is 51% of total active users
    function getMinQuorum() external view returns (uint256) {
        return _minimumQuorum;
    }

    // Get debate period in seconds
    function getDebatePeriod() external view returns (uint256) {
        return _debatingPeriodDuration;
    }

    // Get minum numbers of votes to accept proposal
    function getMinVotes() external view returns (uint256) {
        return _minimumVotes;
    }

    // Private methods

    // Calculate voters percentage by minumum quorum
    function _calculateVotersPercentage() private view returns (uint256) {
        return ((_activeUsers.current() * 10**3) / 100) * _minimumQuorum;
    }
}