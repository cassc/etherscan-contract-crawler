/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract IERC20Minimal {
    function balanceOf(address account) external view virtual returns (uint256) {}
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BabyBombVoting is Ownable {
    IERC20Minimal public votingToken;
    uint256[] private tiers;
    uint256[] private tierVoteWeights;
    string[4] private options;
    bool public isVotingActive;
    uint256 public votingEndTime;
    uint256 public votingSession;
    uint256[4] private votes;
    mapping(address => mapping(uint256 => uint256)) public sessionVotesCast;

    event VoteCast(uint256 indexed option, address indexed voter, uint256 numVotes);
    event VotingStarted();
    event VotingEnded();

    modifier votingPeriod() {
        require(isVotingActive, "Voting is not active");
        if (block.timestamp >= votingEndTime) {
            isVotingActive = false;
            emit VotingEnded();
        }
        _;
    }

    constructor(address _votingToken) {
        require(_votingToken != address(0), "Invalid token address");
        votingToken = IERC20Minimal(_votingToken);
    }

    function setTiers(uint256[] calldata _tiers) external onlyOwner {
        require(_tiers.length > 0 && _tiers.length <= 5, "Tiers should be between 1 and 5");
        require(_tiers[0] > 0, "First tier should be greater than 0");
        for (uint256 i = 1; i < _tiers.length; i++) {
            require(_tiers[i] > _tiers[i - 1], "Tiers should be in ascending order");
        }
        tiers = _tiers;
    }

    function setTierVoteWeights(uint256[] calldata _voteWeights) external onlyOwner {
        require(_voteWeights.length == tiers.length, "Vote weights should have the same length as tiers");
        tierVoteWeights = _voteWeights;
    }

    function setOptions(string calldata _option0, string calldata _option1, string calldata _option2, string calldata _option3) external onlyOwner {
        options[0] = _option0;
        options[1] = _option1;
        options[2] = _option2;
        options[3] = _option3;
    }

    function startVoting(uint256 _duration) external onlyOwner {
                require(tiers.length > 0, "Tiers must be set before starting a voting session");
        require(tierVoteWeights.length == tiers.length, "Tier vote weights must be set before starting a voting session");
        for (uint256 i = 0; i < options.length; i++) {
            require(bytes(options[i]).length > 0, "All options must be set before starting a voting session");
        }
        require(!isVotingActive, "Voting is already active");
        isVotingActive = true;
        votingEndTime = block.timestamp + _duration;
        emit VotingStarted();
    }

    function endVoting() external onlyOwner {
        require(isVotingActive, "Voting is not active");
        isVotingActive = false;
        emit VotingEnded();
    }

    function vote(uint256 _option, uint256 _numVotes) external votingPeriod {
        require(_option >= 0 && _option < 4, "Invalid option");
        uint256 allowedVotes = getVotingWeight(msg.sender);
        require(sessionVotesCast[msg.sender][votingSession] + _numVotes <= allowedVotes, "Exceeds allowed votes");
        votes[_option] += _numVotes;
        sessionVotesCast[msg.sender][votingSession] += _numVotes;
        emit VoteCast(_option, msg.sender, _numVotes);
    }

    function resetVotes() external onlyOwner {
        require(!isVotingActive, "Voting is still active");
        votingSession++;
        for (uint256 i = 0; i < 4; i++) {
            votes[i] = 0;
        }
    }

    function getVotingWeight(address _voter) private view returns (uint256) {
        uint256 balance = votingToken.balanceOf(_voter);
        uint256 tierIndex = 0;

        for (uint256 i = 0; i < tiers.length; i++) {
            if (balance >= tiers[i]) {
                tierIndex = i;
            } else {
                break;
            }
        }

        return tierVoteWeights[tierIndex];
    }

    function getOptions() public view returns (string[4] memory) {
        return options;
    }

    function getVotes() public view returns (uint256[4] memory) {
        return votes;
    }

    function getTiers() public view returns (uint256[] memory) {
        return tiers;
    }

    function getTierVoteWeights() public view returns (uint256[] memory) {
        return tierVoteWeights;
    }
}