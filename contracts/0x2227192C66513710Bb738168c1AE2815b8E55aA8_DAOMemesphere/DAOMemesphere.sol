/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

/*
  ___ ___    ___  ___ ___    ___  _____ ____  __ __    ___  ____     ___ 
|   |   |  /  _]|   |   |  /  _]/ ___/|    \|  |  |  /  _]|    \   /  _]
| _   _ | /  [_ | _   _ | /  [_(   \_ |  o  )  |  | /  [_ |  D  ) /  [_ 
|  \_/  ||    _]|  \_/  ||    _]\__  ||   _/|  _  ||    _]|    / |    _]
|   |   ||   [_ |   |   ||   [_ /  \ ||  |  |  |  ||   [_ |    \ |   [_ 
|   |   ||     ||   |   ||     |\    ||  |  |  |  ||     ||  .  \|     |
|___|___||_____||___|___||_____| \___||__|  |__|__||_____||__|\_||_____|
                                                                        */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DAOMemesphere {
    struct Proposal {
        string description;
        uint voteCount;
        address[] votedAddresses;
    }

    struct Voter {
        uint weight; // voting power
        bool voted;
    }

    address public chairperson;
    mapping (address => Voter) public voters;
    Proposal[] public proposals;

    constructor() {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
    }

    function addVoter(address voter, uint weight) public {
        require(msg.sender == chairperson, "Only the chairperson can add a voter.");
        require(!voters[voter].voted, "The voter has already voted.");
        voters[voter].weight = weight;
    }

    function propose(string memory description) public returns (uint proposalID) {
        Proposal memory newProposal;
        newProposal.description = description;
        newProposal.voteCount = 0;

        proposals.push(newProposal);

        return proposals.length - 1;
    }

    function vote(uint proposalID) public {
        Voter storage voter = voters[msg.sender];
        require(voter.weight != 0, "Has no right to vote");
        require(!voter.voted, "Already voted");
        voter.voted = true;
        proposals[proposalID].voteCount += voter.weight;
        proposals[proposalID].votedAddresses.push(msg.sender);
    }

    function execute(uint proposalID) public {
        Proposal storage p = proposals[proposalID];
        require(p.voteCount * 2 > getTotalVoters(), "This proposal didn't receive enough votes to be executed.");
        // your code to execute proposal here
    }

    function getTotalVoters() public view returns (uint total) {
        for (uint i = 0; i < proposals.length; i++) {
            for (uint j = 0; j < proposals[i].votedAddresses.length; j++){
                total += voters[proposals[i].votedAddresses[j]].weight;
            }
        }
    }
}