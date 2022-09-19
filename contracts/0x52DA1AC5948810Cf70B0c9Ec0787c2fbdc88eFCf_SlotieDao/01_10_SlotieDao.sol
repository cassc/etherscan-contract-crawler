// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./lib/WattsBurnerUpgradable.sol";

contract SlotieDao is WattsBurnerUpgradable {
    struct SimpleProposal {
        uint256 burnFee;
        uint256 deadline;
    }
    mapping(uint256 => SimpleProposal) public simpleProposals;
    mapping(address => mapping(uint256 => uint256)) public usersBurnedWatts;

    event CreateProposalEvent(uint256 indexed id, uint256 indexed burnFee, uint256 indexed deadline);
    event ProposalBurn(address indexed from, uint256 indexed proposalId, uint256 indexed burnedAmount);

    constructor(address[] memory _admins, address _watts, address _transferExtender)
    WattsBurnerUpgradable(_admins, _watts, _transferExtender) {}

    function initialize(address[] memory _admins, address _watts, address _transferExtender) public initializer {
       watts_burner_initialize(_admins, _watts, _transferExtender);
    }

    function CreateProposal(uint256 id, uint256 burnFee, uint256 deadline) external onlyRole(GameAdminRole) {
        SimpleProposal storage proposal = simpleProposals[id];
        require(proposal.burnFee + proposal.deadline == 0, "Proposal at ID already exists");
        require(deadline > block.timestamp + 1 hours, "Invalid deadline");
        require(burnFee > 1 ether, "Invalid burn fee");
        proposal.burnFee = burnFee;
        proposal.deadline = deadline;

        emit CreateProposalEvent(id, burnFee, deadline);
    }

    function DoProposalBurn(uint256 id) external {
        SimpleProposal memory proposal = simpleProposals[id];
        require(proposal.burnFee + proposal.deadline > 0, "Proposal at ID does not exists");
        require(proposal.deadline > block.timestamp, "Proposal expired");
        require(proposal.burnFee > 1 ether, "Invalid burn fee");
        require(usersBurnedWatts[msg.sender][id] < proposal.burnFee, "User already burned for this proposal");
        uint256 toBurn = proposal.burnFee - usersBurnedWatts[msg.sender][id];
        usersBurnedWatts[msg.sender][id] += toBurn;
        _burnWatts(toBurn);

        emit ProposalBurn(msg.sender, id, toBurn);
    }
}