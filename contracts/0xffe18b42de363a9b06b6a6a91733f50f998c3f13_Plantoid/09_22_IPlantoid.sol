// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IPlantoidSpawner {
    function spawnPlantoid(bytes32, bytes calldata)
        external
        returns (address payable);
}

/// @title Plantoid
/// @dev Blockchain based lifeform
///
///
contract IPlantoid {
    error StillProposing();
    error AlreadyDistributed();
    error CannotAdvance();
    error CannotSubmitProposal();
    error StillVoting();
    error NotInVoting();
    error AlreadyVoting();
    error CannotVeto();
    error NotMinted();
    error NotOwner();
    error AlreadyRevealed();
    error InvalidProposal();
    error Vetoed();
    error NoVotingTokens();
    error URIQueryForNonexistentToken();
    error ThresholdNotReached();
    error AlreadyVoted();
    error NotArtist();
    error NotWinner();
    error CannotSpawn();
    error NothingToWithdraw();
    error FailedToSendETH();
    error FailedToSpawn();

    event NewPlantoid(address oracle);
    event Deposit(uint256 amount, address sender, uint256 indexed tokenId);
    event Revealed(uint256 tokenId, string uri);
    event ProposalSubmitted(
        address proposer,
        string proposalUri,
        uint256 round,
        uint256 proposalId
    );
    event ProposalStarted(uint256 round, uint256 end);
    event VotingStarted(uint256 round, uint256 end);
    event GraceStarted(uint256 round, uint256 end);
    event Voted(address voter, uint256 votes, uint256 round, uint256 choice);
    event ProposalVetoed(uint256 round, uint256 proposal);
    event ProposalAccepted(uint256 round, uint256 proposal);
    event NewSpawn(
        uint256 round,
        address spawner,
        address newPlantoid,
        string name,
        string symbol
    );
    event RoundInvalidated(uint256 round);

    enum RoundState {
        Pending,
        Proposal,
        Voting,
        Grace,
        Completed,
        Invalid,
        NeedsAdvancement,
        NeedsSettlement,
        Spawned
    }

    struct Proposal {
        uint256 votes;
        address proposer;
        bool vetoed;
        string uri;
    }

    struct Round {
        uint256 roundStart;
        uint256 proposalEnd;
        uint256 votingEnd;
        uint256 graceEnd;
        uint256 proposalCount;
        uint256 totalVotes;
        uint256 winningProposal;
        bool fundsDistributed;
        mapping(uint256 => Proposal) proposals;
        /// @notice Whether or not a vote has been cast
        mapping(address => bool) hasVoted;
        RoundState roundState;
    }
}