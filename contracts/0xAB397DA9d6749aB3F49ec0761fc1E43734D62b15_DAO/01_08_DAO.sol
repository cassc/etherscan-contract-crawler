//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract DAO is OwnableUpgradeable {
    uint32 constant minimumVotingPeriod = 10 minutes;
    uint256 numOfProposals;

    enum Status {
        InProduction,
        Active,
        Completed,
        Closed
    }

    struct DaoProposals {
        uint256 id;
        uint256 amount;
        uint256 livePeriod;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isVoted;
        string title;
        string description;
        bool votingPassed;
        uint8 result;
        bool paid;
        address payable daoAddress;
        address payable proposer;
        address paidBy;
        Status status;
    }

    struct UserVotes {
        address userAddress;
        uint256 userVotes;
    }

    IERC20Upgradeable public hoichiToken;
    mapping(uint256 => DaoProposals) private daoProposals;
    mapping(address => uint256) private contributorVotes;
    mapping(uint => uint) private votesCount;
    mapping(uint256 => UserVotes[]) private totalVotes;

    event NewDaoProposal(address indexed proposer, uint256 amount);
    event ProposalCompleted(uint256 proposalId, uint8 result);
    event paymentSent(address indexed proposer, address indexed daoAddress, uint256 amount);
    event Received(address, uint);


    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function initialize(address _hoichit) public initializer {
        require(_hoichit != address(0), "GOV: INVALID_PIXT");
        __Ownable_init();
        hoichiToken = IERC20Upgradeable(_hoichit);
    }

    function createProposal(
        string calldata title,
        string calldata description,
        uint256 amount
    ) external {
        require(
            hoichiToken.balanceOf(msg.sender) >= 1e18,
            "createProposal: insufficiency balance"
        );
        uint256 proposalId = numOfProposals++;
        DaoProposals storage proposal = daoProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = payable(msg.sender);
        proposal.title = title;
        proposal.description = description;
        // proposal.daoAddress = payable(daoAddress);
        proposal.amount = amount;
        proposal.livePeriod = block.timestamp + minimumVotingPeriod;

        emit NewDaoProposal(msg.sender, amount);
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (DaoProposals memory)
    {
        return daoProposals[proposalId];
    }

    function getProposals() public view returns (DaoProposals[] memory props) {
        props = new DaoProposals[](numOfProposals);
        for (uint256 index = 0; index < numOfProposals; index++) {
            props[index] = daoProposals[index];
        }
    }

    function vote(uint256 proposalId, bool supportProposal, uint256 _amount) external {
        DaoProposals storage daoProposal = daoProposals[proposalId];

        votable(daoProposal);

        uint256 amount;
        amount = _amount;

        daoProposal.isVoted = true;
        daoProposal.status = Status.Active;

         if (supportProposal){
            daoProposal.votesFor=daoProposal.votesFor + amount;
        }else{
            daoProposal.votesAgainst = daoProposal.votesAgainst + amount;
        }
        totalVotes[proposalId].push(UserVotes(msg.sender, amount));
        contributorVotes[msg.sender] = contributorVotes[msg.sender] + amount;
    }

    // user voting on a proposal multiple times
    // function to track number of votes, to achieve the 1 hoichi = 1 vote functionality

    function votable(DaoProposals storage daoProposal) private {
        if (
            daoProposal.votingPassed ||
            daoProposal.livePeriod <= block.timestamp
        ) {
            daoProposal.votingPassed = true;
            revert("Voting period has passed on this proposal");
        }

        // for (uint256 votes = 0; votes < tempVotes.length; votes++) {
        //     if (daoProposal.id == tempVotes[votes])
        //         revert("This stakeholder already voted on this proposal");
        // }
    }

    function getVotes(uint proposalId) public view returns(uint) {
        return votesCount[proposalId];
    }

        function getTotalVotes() public view returns(uint256) {
        return contributorVotes[msg.sender];
    }

    function payProposal(uint256 proposalId) external {
        DaoProposals storage daoProposal = daoProposals[proposalId];

        if(daoProposal.livePeriod <= block.timestamp)
        revert("voting has not passed on this proposal");

        if(daoProposal.paid)
            revert("Payment has been made to this proposal");

        if(daoProposal.votesFor == daoProposal.votesAgainst)
            revert("The proposal does not have the amount of vote to pass");

        daoProposal.paid == true;
        daoProposal.paidBy = msg.sender;

        emit paymentSent(msg.sender, daoProposal.proposer, daoProposal.amount);

        return daoProposal.proposer.transfer(daoProposal.amount);
    }  


    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
}