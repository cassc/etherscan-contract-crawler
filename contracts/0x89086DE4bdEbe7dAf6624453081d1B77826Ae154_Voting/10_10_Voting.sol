// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting is AccessControl {
    using SafeMath for uint256;

    address public owner;
    address public Token;

    struct Proposal {
        uint32 id;
        string title;
        uint voteCountYes;
        uint voteCountNo;
        uint256 startDate;
        uint256 expirationDate;
        mapping(address => Voter) voters;
    }
    enum VotingOption {NotVoted, Yes, No, Total}

    struct Voter {
        address wallet;
        VotingOption value;
        bool voted;
    }

    mapping(uint32 => Proposal) public proposals;

    event NewProposal(uint32 _id, string title, uint256 start, uint256 expire);
    event ModifyExpireProposal(uint32 _id, uint256 start, uint256 expire);
    event Vote(address holder, uint32 _id, VotingOption value, uint256 _amount);

    constructor(address _token) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        owner = _msgSender();
        Token = _token;
    }

    modifier proposalsExists(uint32 _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Vote: Proposal does not exist.");
        _;
    }

    modifier proposalsOpen(uint32 _proposalId)  {
        require(block.timestamp <= proposals[_proposalId].expirationDate, "Vote: Proposal expired.");
        require(block.timestamp >= proposals[_proposalId].startDate, "Vote: Proposal not start.");
        _;
    }

    modifier isHolderToken()  {
        require(IERC20(Token).balanceOf(_msgSender()) >= 0, 'Vote: You must be holder');
        _;
    }

    function getProposal(uint32 proposalId) public proposalsExists(proposalId) view returns (uint32, string memory, uint256, uint256) {
        Proposal storage p = proposals[proposalId];
        return (p.id, p.title, p.startDate, p.expirationDate);
    }

    function modifyProposal(uint32 proposalId, uint256 startTime, uint256 expiration) public proposalsExists(proposalId) onlyRole(DEFAULT_ADMIN_ROLE) {
        Proposal storage p = proposals[proposalId];
        if (startTime > 0) {
            p.startDate = startTime;
        }
        if (expiration > 0) {
            p.expirationDate = expiration;
        }
        emit ModifyExpireProposal(proposalId, p.startDate, p.expirationDate);
    }

    function setToken(address _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Token = _token;
    }

    function addProposal(uint32 proposalId, string memory title, uint256 startTime, uint256 expiration) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(proposals[proposalId].id != proposalId, "Vote: The proposal existed.");
        require(startTime <= expiration, "Vote: The proposal time invalid.");

        Proposal storage p = proposals[proposalId];
        p.id = proposalId;
        p.title = title;
        p.startDate = startTime;
        p.expirationDate = expiration;
        emit NewProposal(p.id, p.title, p.startDate, p.expirationDate);
    }

    function isVotingOpen(uint32 proposalId) public proposalsExists(proposalId) view returns (bool) {
        Proposal storage p = proposals[proposalId];
        return block.timestamp <= p.expirationDate;
    }

    function canVote(uint32 proposalId, address _who) public proposalsExists(proposalId) view returns (bool) {
        Proposal storage p = proposals[proposalId];
        return p.voters[_who].voted == false;
    }

    function vote(uint32 proposalId, VotingOption _vote) public proposalsExists(proposalId) proposalsOpen(proposalId) isHolderToken returns (uint256) {
        require(!proposals[proposalId].voters[_msgSender()].voted, "Vote: Holder voted for this proposal.");
        require(_vote > VotingOption.NotVoted && _vote < VotingOption.Total, "Vote: The vote value not validate.");
        uint256 _amount = IERC20(Token).balanceOf(_msgSender());
        Proposal storage p = proposals[proposalId];

        if (_vote == VotingOption.Yes) {
            p.voteCountYes = p.voteCountYes.add(_amount);
        } else if (_vote == VotingOption.No) {
            p.voteCountNo = p.voteCountNo.add(_amount);
        }
        p.voters[_msgSender()].wallet = _msgSender();
        p.voters[_msgSender()].value = _vote;
        p.voters[_msgSender()].voted = true;

        emit Vote(_msgSender(), proposalId, _vote, _amount);
        return block.number;

    }

    function votingPercentages(uint32 proposalId, uint256 _expectedVotingAmount) external proposalsExists(proposalId) view returns (
        uint256 noPercent,
        uint256 noVotes,
        uint256 yesPercent,
        uint256 yesVotes,
        uint256 totalVoted,
        uint256 turnoutPercent
    ) {
        Proposal storage p = proposals[proposalId];
        noVotes = p.voteCountNo;
        yesVotes = p.voteCountYes;
        totalVoted = noVotes.add(yesVotes);
        require(totalVoted > 0, "Vote: Don't any voting");

        uint256 oneHundredPercent = 10000;
        noPercent = p.voteCountNo.mul(oneHundredPercent).div(totalVoted);
        yesPercent = oneHundredPercent.sub(noPercent);

        turnoutPercent = totalVoted.mul(oneHundredPercent).div(_expectedVotingAmount);
    }
}