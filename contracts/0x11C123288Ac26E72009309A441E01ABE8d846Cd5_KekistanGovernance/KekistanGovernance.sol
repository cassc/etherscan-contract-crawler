/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// File: IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: governane.sol

pragma solidity ^0.8.0;
//* SPDX-License-Identifier: Unlicensed


contract KekistanGovernance {
    IERC20 public token;
    uint256 public proposalCount;

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public votes;

    event ProposalCreated(uint256 id, address proposer, uint256 endTime);
    event ProposalVoted(uint256 id, address voter, bool vote, uint256 amount);
    event ProposalExecuted(uint256 id);

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    function createProposal(uint256 duration) public {
        require(duration > 0, "Duration must be > 0");
        proposalCount++;
        uint256 endTime = block.timestamp + duration;
        proposals[proposalCount] = Proposal(proposalCount, msg.sender, endTime, 0, 0, false);
        emit ProposalCreated(proposalCount, msg.sender, endTime);
    }

    function vote(uint256 proposalId, bool support) public {
        require(proposals[proposalId].endTime > block.timestamp, "Voting period has ended");
        require(!votes[proposalId][msg.sender], "Already voted");

        uint256 voterBalance = token.balanceOf(msg.sender);
        require(voterBalance > 0, "No tokens to vote with");

        if (support) {
            proposals[proposalId].forVotes += voterBalance;
        } else {
            proposals[proposalId].againstVotes += voterBalance;
        }

        votes[proposalId][msg.sender] = true;
        emit ProposalVoted(proposalId, msg.sender, support, voterBalance);
    }
}