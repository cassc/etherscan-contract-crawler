// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface INftyDreamsContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract NftyDreamsVote is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private nextProposalId;

    uint256[] public validTokens;
    INftyDreamsContract nftyDreamsContract;
    address public contractAddress = 0x36c1f502e1c438710dF22F55cAc00b677F09dFB7;

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 votingStarts;
        uint256 votingEnds;
        uint256 maxVotes;
        uint256[] options;
        mapping(address => uint256) voteFor;
        bytes32 merkleRoot;
        string merkleTreeInputURI;
    }

    mapping(uint256 => proposal) public Proposals;
    mapping(uint256 => mapping(uint256 => uint256)) private voteStatus;

    event VoteRecorded(address voter, uint256 proposal);
    event ProposalCreated(uint256 id, string description, address proposer);

    constructor() {
        nftyDreamsContract = INftyDreamsContract(contractAddress);
        validTokens = [1, 2, 3, 4, 5];
    }

    function createProposal(
        string memory _description,
        uint256[] memory _options,
        uint256 _votingStarts,
        uint256 _votingEnds,
        bytes32 _merkleRoot,
        string memory _merkleTreeInputURI
    ) external onlyOwner {
        nextProposalId.increment();
        proposal storage newProposal = Proposals[nextProposalId.current()];
        newProposal.id = nextProposalId.current();
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.votingStarts = _votingStarts;
        newProposal.votingEnds = _votingEnds;
        newProposal.options = _options;
        newProposal.merkleRoot = _merkleRoot;
        newProposal.merkleTreeInputURI = _merkleTreeInputURI;

        emit ProposalCreated(
            nextProposalId.current(),
            _description,
            msg.sender
        );
    }

    function voteOnProposal(
        uint256 _proposalId,
        uint256 _optionId,
        bytes32[] memory merkleProof
    ) external {
        require(
            block.number >= Proposals[_proposalId].votingStarts,
            "Voting not yet started for this Proposal"
        );
        require(Proposals[_proposalId].exists, "This Proposal does not exist");
        require(
            checkVoteEligibility(msg.sender),
            "You can not vote on this Proposal"
        );
        require(
            Proposals[_proposalId].voteFor[msg.sender] == 0,
            "You have already voted on this Proposal"
        );
        require(
            block.number <= Proposals[_proposalId].votingEnds,
            "The deadline has passed for this Proposal"
        );

        proposal storage p = Proposals[_proposalId];

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            _checkEligibility(p.merkleRoot, merkleProof, leaf) == true,
            "Address not eligible to vote"
        );

        voteStatus[_proposalId][_optionId] += 1;
        p.voteFor[msg.sender] = _optionId;

        emit VoteRecorded(msg.sender, _proposalId);
    }

    function _checkEligibility(
        bytes32 merkleRoot,
        bytes32[] memory merkleProof,
        bytes32 leaf
    ) internal pure returns (bool) {
        return (MerkleProof.verify(merkleProof, merkleRoot, leaf));
    }

    function checkIfVoted(uint256 _proposalId, address _account)
        external
        view
        returns (bool)
    {
        proposal storage p = Proposals[_proposalId];
        if (p.voteFor[_account] > 0) {
            return true;
        }
        return false;
    }

    function checkVoteEligibility(address _account) public view returns (bool) {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (nftyDreamsContract.balanceOf(_account, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function getVotes(uint256 _proposalId, uint256 _optionId)
        external
        view
        returns (uint256)
    {
        require(Proposals[_proposalId].exists, "This Proposal does not exist");
        require(
            block.number > Proposals[_proposalId].votingEnds,
            "Voting has not concluded"
        );

        return voteStatus[_proposalId][_optionId];
    }

    function addTokenId(uint256 _tokenId) external onlyOwner {
        validTokens.push(_tokenId);
    }

    function setContractAddress(address _contractAddress) external onlyOwner {
        contractAddress = _contractAddress;
    }
}