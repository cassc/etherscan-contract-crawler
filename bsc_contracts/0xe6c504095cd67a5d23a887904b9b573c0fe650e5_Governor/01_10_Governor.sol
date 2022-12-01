// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./interfaces/IVotingPower.sol";
import "./interfaces/IBSKTStakingContract.sol";
// import "hardhat/console.sol"; // remove or comment 

contract Governor {
    using Timers for Timers.BlockNumber;
    using SafeCast for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _pollingCounter;
    Counters.Counter private _executiveCounter;
    address private _owner;
    address private basketCoin;
    address private stakedContract;
    address private basketCoinNFT;
    address private votingPowerContractor;

    constructor (address _basketCoin, address _stakedContract, address _basketCoinNFT, address _votingPowerContract) {
        require(_basketCoin != address(0), "BasketCoin not defined");
        require(_stakedContract != address(0), "StakedCoin not defined");
        require(_basketCoinNFT != address(0), "BasketCoinNFT not defined");
        require(_votingPowerContract != address(0), "VotiingPower Contract not defined");
        _owner = _msgSender();
        basketCoin = _basketCoin;
        stakedContract = _stakedContract;
        basketCoinNFT = _basketCoinNFT;
        votingPowerContractor = _votingPowerContract;
    }

    /**
        Events
     */
    event PollingProposalCreated(
        uint256 proposalId,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    event ExecutiveProposalCreated(
        uint256 proposalId,
        address proposer,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event pollingProposalCanceled(uint256 proposalId);
    event executiveProposalCanceled(uint256 proposalId);
    event PollingVoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);
    event ExecutiveVoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);
    /**
     * @dev Emitted when a proposal is canceled.
     */
    event PollingProposalCanceled(uint256 proposalId);
    event ExecutiveProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event PollingProposalExecuted(uint256 proposalId);
    event ExecutiveProposalExecuted(uint256 proposalId);


    enum VoteType {
        Against,
        For,
        Abstain
    }

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
    
    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
        address[] voters;
    }

    uint256 private quorumFractionDenominator = 100;
    uint256 private quorumFractionNumerator = 4;

    mapping(uint256 => ProposalVote) private _pollingProposalVotes;
    mapping(uint256 => ProposalVote) private _executiveProposalVotes;

    struct ProposalCore {
        Timers.BlockNumber voteStart;
        Timers.BlockNumber voteEnd;
        bool executed;
        bool canceled;
        string description;
        uint256 proposalStart;
        uint256 proposalEnd;
    }

    mapping(uint256 => ProposalCore) private _pollingProposals;
    mapping(uint256 => ProposalCore) private _executiveProposals;
    mapping(address => bool) private _admins;

    /**
        Access control Mechanisms
     */

    function _msgSender() view private returns (address) {
        return msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * add and remove admins to create executive proposals
     */

    function addAdmin(address admin) external onlyOwner {
        _admins[admin] = true;
    } 

    function removeAdmin(address admin) external onlyOwner {
        _admins[admin] = false;
    }

    function isAdmin(address user) external view returns (bool) {
        return _admins[user];
    }

    /**
     * Update quorum denominator
     */
    function updateQuorumDenominator(uint256 _quorumDenominator) external onlyOwner {
        quorumFractionDenominator = _quorumDenominator;
    }
    function updateQuorumNumerator(uint256 _quorumNumerator) external onlyOwner {
        quorumFractionNumerator = _quorumNumerator;
    }

    /**
     * Create Proposal for 
     */
    function createPollingProposal(string calldata description, uint64 votingPeriod, string[] calldata cards, string calldata pairName) public returns(uint256 _pollingProposalId) {
        {  
            require(((calculateVotingPower(cards, _msgSender(), pairName)) / (IVotingPower(votingPowerContractor).getDivisor())) > IVotingPower(votingPowerContractor).getMinimumVotingPower(), "Not enough voting power");
        }
        uint256 proposalId = _pollingCounter.current();
        _pollingCounter.increment();
        ProposalCore storage proposal = _pollingProposals[proposalId];

        {
            uint64 snapshot = block.number.toUint64();
            uint64 deadline = snapshot + votingPeriod;
            proposal.voteStart.setDeadline(snapshot);
            proposal.voteEnd.setDeadline(deadline);
            proposal.description = description;
            proposal.proposalStart = block.timestamp;
            proposal.proposalEnd = block.timestamp + votingPeriod;

            emit PollingProposalCreated(
                proposalId,
                _msgSender(), 
                snapshot,
                deadline,
                proposal.description
            );
            return proposalId;
        }
        
    }

    /**
     * Create Proposal for 
     */
    function createExecutiveProposal(string calldata description, uint64 votingPeriod, string[] calldata cards, string calldata pairName) public returns(uint256 _pollingProposalId) {
        require(_admins[_msgSender()] == true || _msgSender() == _owner, "Admin Access Required");
        uint256 votingPower = calculateVotingPower(cards, _msgSender(), pairName);
        require(votingPower / (IVotingPower(votingPowerContractor).getDivisor()) > IVotingPower(votingPowerContractor).getMinimumVotingPower(), "Not enough voting power");

        uint256 proposalId = _executiveCounter.current();
        _executiveCounter.increment();
        ProposalCore storage proposal = _executiveProposals[proposalId];
        
        uint64 snapshot = block.number.toUint64();
        uint64 deadline = snapshot + votingPeriod;
        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);
        proposal.description = description;
        proposal.proposalStart = block.timestamp;
        proposal.proposalEnd = block.timestamp + votingPeriod;

        emit ExecutiveProposalCreated(
            proposalId,
            _msgSender(), 
            snapshot,
            deadline,
            proposal.description
        );
        return proposalId;
    }

    function calculateVotingPower(string[] calldata cards, address voter, string calldata pairName) internal view returns(uint256 votingPower){
        uint256 power = 0;
        for(uint256 i=0; i< cards.length; i++) {
            power += IVotingPower(votingPowerContractor).getVotingPower(cards[i]);
        }
        power += IERC20(basketCoin).balanceOf(voter) * (IVotingPower(votingPowerContractor).getDivisor());
        power += IBSKTStakingPool(stakedContract).balanceOf(voter) * (IVotingPower(votingPowerContractor).getDivisor());

        if(IVotingPower(votingPowerContractor).getMultiplier(pairName) > 0) {
                power = power * IVotingPower(votingPowerContractor).getMultiplier(pairName);
        }
        return power;
    }

    function castPollingVote(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        string[] calldata cards, 
        string calldata pairName
    ) external {

        address voter = _msgSender();

        ProposalVote storage proposal = _pollingProposalVotes[proposalId];
        // require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 power = calculateVotingPower(cards, voter, pairName);

        require(!proposal.hasVoted[voter], "Governor: vote already cast");
        proposal.hasVoted[voter] = true;
        proposal.voters.push(voter);
        if(power > 0) {
            if (support == uint8(VoteType.Against)) {
                proposal.againstVotes += power;
            } else if (support == uint8(VoteType.For)) {
                proposal.forVotes += power;
            } else if (support == uint8(VoteType.Abstain)) {
                proposal.abstainVotes += power;
            } else {
                revert("Governor: invalid value for enum VoteType");
            }
        }

        emit PollingVoteCast(voter, proposalId, support, power, reason);  

    }

    function castExecutiveVote(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        string[] calldata cards, 
        string calldata pairName
    ) external {

        address voter = _msgSender();

        ProposalVote storage proposal = _executiveProposalVotes[proposalId];
        // require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 power = calculateVotingPower(cards, voter, pairName);

        require(!proposal.hasVoted[voter], "Governor: vote already cast");
        proposal.hasVoted[voter] = true;
        proposal.voters.push(voter);

        if(power > 0) {
            if (support == uint8(VoteType.Against)) {
                proposal.againstVotes += power;
            } else if (support == uint8(VoteType.For)) {
                proposal.forVotes += power;
            } else if (support == uint8(VoteType.Abstain)) {
                proposal.abstainVotes += power;
            } else {
                revert("Governor: invalid value for enum VoteType");
            }
        }

        emit ExecutiveVoteCast(voter, proposalId, support, power, reason);

    }

    function hasVotedOnPollingProposal(address user, uint256 proposalId) external view returns(bool hastVoted) {
       ProposalVote storage votingData = _pollingProposalVotes[proposalId];
       return votingData.hasVoted[user];
    }

    function hasVotedOnExecutiveProposal(address user, uint256 proposalId) external view returns(bool hastVoted) {
       ProposalVote storage votingData = _executiveProposalVotes[proposalId];
       return votingData.hasVoted[user];
    }

    function getVotingPowerOfUser(
        string[] calldata cards, 
        string calldata pairName,
        address user
    ) external view returns (uint256 votingPower) {
        return calculateVotingPower(cards, user, pairName);
    }

    function getPollingProposaldetails(uint256 proposalId) external view returns (
        string memory description,
        uint256 voteStart,
        uint256 voteEnd,
        uint256 againstVotes,
        uint256 forVotes,
        uint256 abstainVotes,
        address[] memory voters,
        ProposalState status
    ){
        ProposalCore storage proposal = _pollingProposals[proposalId];
        ProposalVote storage proposalVotes = _pollingProposalVotes[proposalId];
        ProposalState statusquo = pollingProposalStatus(proposalId);
        string memory _description = proposal.description;
        address[] memory _voters = proposalVotes.voters;

        return (
            _description,
            proposal.proposalStart,
            proposal.proposalEnd,
            proposalVotes.againstVotes,
            proposalVotes.forVotes,
            proposalVotes.abstainVotes,
            _voters,
            statusquo
        );

    }

    function getExecutiveProposaldetails(uint256 proposalId) external view returns (
        string memory description,
        uint256 voteStart,
        uint256 voteEnd,
        uint256 againstVotes,
        uint256 forVotes,
        uint256 abstainVotes,
        address[] memory voters,
        ProposalState status
    ){
        ProposalCore storage proposal = _executiveProposals[proposalId];
        ProposalVote storage proposalVotes = _executiveProposalVotes[proposalId];
        ProposalState statusquo = executiveProposalStatus(proposalId);
        string memory _description = proposal.description;
        address[] memory _voters = proposalVotes.voters;

        return (
            _description,
            proposal.proposalStart,
            proposal.proposalEnd,
            proposalVotes.againstVotes,
            proposalVotes.forVotes,
            proposalVotes.abstainVotes,
            _voters,
            statusquo
        );

    }

    function getPollingProposalCount() external view returns(uint256 count) {
        return _pollingCounter.current();
    }

    function getExecutiveProposalCount() external view returns(uint256 count) {
        return _executiveCounter.current();
    }

    function pollingProposalStatus(uint256 proposalId) public view virtual returns (ProposalState) {
        ProposalCore storage proposal = _pollingProposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = pollingProposalSnapshot(proposalId);
        
        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = pollingProposalDeadline(proposalId);
        if (deadline >= block.number) {
            return ProposalState.Active;
        }
       
        if (_pollingQuorumReached(proposalId) && _pollingVoteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    function executiveProposalStatus(uint256 proposalId) public view virtual returns (ProposalState) {
        ProposalCore storage proposal = _executiveProposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = executiveProposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = executiveProposalDeadline(proposalId);

        if (deadline >= block.number) {
            return ProposalState.Active;
        }

        if (_executiveQuorumReached(proposalId) && _executiveVoteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    function pollingProposalSnapshot(uint256 proposalId) public view virtual returns (uint256) {
        return _pollingProposals[proposalId].voteStart.getDeadline();
    }

    function executiveProposalSnapshot(uint256 proposalId) public view virtual returns (uint256) {
        return _executiveProposals[proposalId].voteStart.getDeadline();
    }

    function pollingProposalDeadline(uint256 proposalId) public view virtual  returns (uint256) {
        return _pollingProposals[proposalId].voteEnd.getDeadline();
    }

    function executiveProposalDeadline(uint256 proposalId) public view virtual returns (uint256) {
        return _executiveProposals[proposalId].voteEnd.getDeadline();
    }

    function _pollingQuorumReached(uint256 proposalId) internal view virtual returns (bool) {
        ProposalVote storage proposalvote = _pollingProposalVotes[proposalId];
        return quorum() <= ((proposalvote.forVotes + proposalvote.abstainVotes) / IVotingPower(votingPowerContractor).getDivisor());
    }

    function _executiveQuorumReached(uint256 proposalId) internal view virtual returns (bool) {
        ProposalVote storage proposalvote = _executiveProposalVotes[proposalId];
        return quorum() <= ((proposalvote.forVotes + proposalvote.abstainVotes)/ IVotingPower(votingPowerContractor).getDivisor());
    }

    function quorum() internal view virtual returns (uint256) {
        uint256 totalSupply = IERC20(basketCoin).totalSupply() + IBSKTStakingPool(stakedContract).totalSupply() + IERC721Enumerable(basketCoinNFT).totalSupply();
        return (totalSupply * quorumFractionNumerator) / quorumFractionDenominator;
    }

    function _pollingVoteSucceeded(uint256 proposalId) internal view virtual returns (bool) {
        ProposalVote storage proposalvote = _pollingProposalVotes[proposalId];
        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    function _executiveVoteSucceeded(uint256 proposalId) internal view virtual returns (bool) {
        ProposalVote storage proposalvote = _executiveProposalVotes[proposalId];
        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    function executePollingProposal(
        uint256 proposalId
    ) public virtual returns (uint256) {
        require(_admins[_msgSender()] == true || _msgSender() == _owner, "Admin Access Required");

        ProposalState status = pollingProposalStatus(proposalId);

        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _pollingProposals[proposalId].executed = true;

        emit PollingProposalExecuted(proposalId);

        return proposalId;
    }

    function executeExecutiveProposal(
        uint256 proposalId
    ) public virtual returns (uint256) {
        require(_admins[_msgSender()] == true || _msgSender() == _owner, "Admin Access Required");

        ProposalState status = executiveProposalStatus(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _executiveProposals[proposalId].executed = true;

        emit ExecutiveProposalExecuted(proposalId);

        return proposalId;
    }

    function cancelPollingProposal(uint256 proposalId) public virtual returns(uint256) {
        require(_admins[_msgSender()] == true || _msgSender() == _owner, "Admin Access Required");

        ProposalState status = pollingProposalStatus(proposalId);
        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );

        _pollingProposals[proposalId].canceled = true;
        emit pollingProposalCanceled(proposalId);

        return proposalId;
    }

    function cancelExecutiveProposal(uint256 proposalId) public virtual returns(uint256) {
        require(_admins[_msgSender()] == true || _msgSender() == _owner, "Admin Access Required");

        ProposalState status = executiveProposalStatus(proposalId);
        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );

        _executiveProposals[proposalId].canceled = true;
        emit executiveProposalCanceled(proposalId);

        return proposalId;
    }
}