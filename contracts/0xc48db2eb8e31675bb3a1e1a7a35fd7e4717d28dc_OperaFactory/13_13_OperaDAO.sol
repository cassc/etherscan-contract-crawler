pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
//This contract is used to vote on which token liquidity pools to be returned.
import "OperaToken.sol";
import "OperaFactory.sol";

contract OperaDAO {
    address public owner;
    address public operaFactoryAddress;
    address public operaTokenAddress =
        0x3bd8268791DE798d4ED5d424d49412cF42B8eC3a;

    uint64 public lobbyCount;
    uint64 public voteTime = 86400;
    uint64 public cooldownTimer = 604800;
    uint64 public delayTimer = 86400;
    mapping(uint64 => uint256) public tokenIdVoteTimer;
    mapping(uint64 => VoteState) public tokenIdVoteState;
    mapping(uint64 => uint64) public tokenIdVoteLobby;
    mapping(uint64 => uint64) public lobbyVoterCount;
    mapping(uint64 => mapping(uint64 => Vote)) public votingLobbyToPositionVote;
    mapping(address => mapping(uint256 => bool))
        public voterAlreadyVotedForLobby;
    mapping(address => bool) public nonVoter;

    struct Vote {
        address voter;
        bool vote;
    }
    enum VoteState {
        NOTINITIATED,
        VOTING,
        COOLDOWN,
        REMOVELPDELAY,
        COMPLETED
    }
    event tokenVoteStateChanged(
        uint64 tokenId,
        uint64 lobbyId,
        uint256 blocktime,
        VoteState state
    );
    event voteEmitted(address voter, uint64 lobbyId, uint64 tokenId, bool vote);
    event voteCounted(
        address voter,
        uint64 tokenId,
        uint64 lobbyId,
        uint256 amount
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setFactoryAddress(address factory) external onlyOwner {
        operaFactoryAddress = factory;
    }

    function updateVoterStatus(address voter, bool state) external onlyOwner {
        nonVoter[voter] = state;
    }

    function setTimers(
        uint64 cooldown,
        uint64 delay,
        uint64 _voteTime
    ) external onlyOwner {
        require(cooldown <= 604800, "No more than 1 week");
        require(delay <= 86400, "No more than 1 day");
        require(_voteTime <= 86400, "No more than 1 day");
        cooldownTimer = cooldown;
        delayTimer = delay;
        voteTime = _voteTime;
    }

    function startTimer(uint64 tokenId, uint64 time) external {
        require(
            msg.sender == operaFactoryAddress,
            "Only the factory can start a timer for a token."
        );
        tokenIdVoteTimer[tokenId] = time;
        tokenIdVoteState[tokenId] = VoteState.COOLDOWN;
        emit tokenVoteStateChanged(
            tokenId,
            0,
            block.timestamp,
            VoteState.COOLDOWN
        );
    }

    function startVoteForTokenId(uint64 id) external {
        require(
            tokenIdVoteState[id] == VoteState.COOLDOWN,
            "Voting needs to be in cooldown."
        );
        require(
            tokenIdVoteTimer[id] > 0 && tokenIdVoteTimer[id] <= block.timestamp,
            "Still on cooldown."
        );
        tokenIdVoteTimer[id] = block.timestamp;
        tokenIdVoteState[id] = VoteState.VOTING;
        tokenIdVoteLobby[id] = lobbyCount;
        lobbyCount += 1;
        emit tokenVoteStateChanged(
            id,
            tokenIdVoteLobby[id],
            block.timestamp,
            VoteState.VOTING
        );
    }

    function voteForId(uint64 id, bool vote) external {
        require(tokenIdVoteState[id] == VoteState.VOTING, "Voting not enabled");
        require(!nonVoter[msg.sender], "You cannot vote.");
        uint64 lobbyId = tokenIdVoteLobby[id];
        require(
            voterAlreadyVotedForLobby[msg.sender][lobbyId] == false,
            "You already voted"
        );
        voterAlreadyVotedForLobby[msg.sender][lobbyId] = true;
        uint64 voterCount = lobbyVoterCount[lobbyId];
        votingLobbyToPositionVote[lobbyId][voterCount] = Vote(msg.sender, vote);
        lobbyVoterCount[lobbyId] += 1;
        emit voteEmitted(msg.sender, lobbyId, id, vote);
    }

    function completeVote(uint64 id) external {
        require(
            tokenIdVoteState[id] == VoteState.VOTING,
            "Not currently voting."
        );
        require(
            tokenIdVoteTimer[id] + voteTime <= block.timestamp,
            "Voting in effect."
        );

        if (getVoteResult(tokenIdVoteLobby[id], id)) {
            tokenIdVoteState[id] = VoteState.REMOVELPDELAY;
            tokenIdVoteTimer[id] = block.timestamp + delayTimer;
            emit tokenVoteStateChanged(
                id,
                tokenIdVoteLobby[id],
                block.timestamp,
                VoteState.REMOVELPDELAY
            );
        } else {
            tokenIdVoteState[id] = VoteState.COOLDOWN;
            tokenIdVoteTimer[id] = block.timestamp + cooldownTimer;
            OperaFactory factory = OperaFactory(payable(operaFactoryAddress));
            factory.increaseLockTime(id, cooldownTimer + voteTime);
            emit tokenVoteStateChanged(
                id,
                tokenIdVoteLobby[id],
                block.timestamp,
                VoteState.COOLDOWN
            );
        }
    }

    function getVoteResult(
        uint64 lobbyId,
        uint64 tokenId
    ) internal returns (bool) {
        OperaToken operaToken = OperaToken(payable(operaTokenAddress));

        uint256 voteFor;
        uint256 voteAgainst;
        Vote memory tempVote;
        uint256 tempVoteAmount;
        for (uint64 i = 0; i < lobbyVoterCount[lobbyId]; i++) {
            tempVote = votingLobbyToPositionVote[lobbyId][i];
            tempVoteAmount = operaToken.balanceOf(tempVote.voter);
            if (tempVote.vote) {
                voteFor += tempVoteAmount;
            } else {
                voteAgainst += tempVoteAmount;
            }
            emit voteCounted(tempVote.voter, tokenId, lobbyId, tempVoteAmount);
        }
        uint256 totalVotes = voteFor + voteAgainst;
        uint256 voteThreshhold = (totalVotes * 60) / 100;
        if (voteFor >= voteThreshhold) {
            return true;
        } else {
            return false;
        }
    }

    function removeTokenLP(uint64 id) external {
        require(
            tokenIdVoteState[id] == VoteState.REMOVELPDELAY,
            "Not in remove lp State."
        );
        require(
            tokenIdVoteTimer[id] <= block.timestamp,
            "Delay still in effect."
        );
        tokenIdVoteState[id] = VoteState.COMPLETED;
        emit tokenVoteStateChanged(
            id,
            tokenIdVoteLobby[id],
            block.timestamp,
            VoteState.COMPLETED
        );
        OperaFactory factory = OperaFactory(payable(operaFactoryAddress));
        factory.claimLiquidityFromLockerWithId(id);
        bool removedLP = factory.removeLiquidity(id);
        require(removedLP, "Failed to removed liquidity");
    }
}