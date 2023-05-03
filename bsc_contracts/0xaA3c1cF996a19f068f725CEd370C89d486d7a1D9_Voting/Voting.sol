/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Voting is Ownable {
    IERC20 public votingToken;
    uint256[] public tiers;
    mapping(uint256 => uint256) public tierVoteWeights;
    mapping(uint256 => string) public options;
    bool public isVotingActive;
    uint256 public votingEndTime;
    mapping(uint256 => uint256) public votes;
    mapping(address => uint256) public votesCast;

    event VoteCast(uint256 indexed option, address indexed voter, uint256 numVotes);
    event VotingStarted();
    event VotingEnded();

    constructor(address _votingToken) {
        require(_votingToken != address(0), "Invalid token address");
        votingToken = IERC20(_votingToken);
    }

    function setTiers(uint256[] calldata _tiers) external onlyOwner {
        require(_tiers.length > 0 && _tiers.length <= 5, "Tiers should be between 1 and 5");
        tiers = _tiers;
    }

    function setTierVoteWeights(uint256[] calldata _voteWeights) external onlyOwner {
        require(_voteWeights.length > 0 && _voteWeights.length <= 5, "Vote weights should be between 1 and 5");
        for (uint256 i = 0; i < _voteWeights.length; i++) {
            tierVoteWeights[i] = _voteWeights[i];
        }
    }

    function setOptions(string[] calldata _options) external onlyOwner {
        require(_options.length == 4, "There should beexactly 4 options");
        for (uint256 i = 0; i < _options.length; i++) {
            options[i] = _options[i];
        }
    }

    function startVoting(uint256 _duration) external onlyOwner {
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

    function vote(uint256 _option, uint256 _numVotes) external {
        require(isVotingActive, "Voting is not active");
        require(bytes(options[_option]).length > 0, "Invalid option");
        require(block.timestamp < votingEndTime, "Voting period has ended");
        uint256 allowedVotes = getVotingWeight(msg.sender);
        require(votesCast[msg.sender] + _numVotes <= allowedVotes, "Exceeds allowed votes");
        votes[_option] += _numVotes;
        votesCast[msg.sender] += _numVotes;
        emit VoteCast(_option, msg.sender, _numVotes);
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

    function getOptions() public view returns (string[] memory) {
        string[] memory optionList = new string[](4);
        for (uint256 i = 0; i < 4; i++) {
            optionList[i] = options[i];
        }
        return optionList;
    }

    function getTierVoteWeights() public view returns (uint256[] memory) {
        uint256[] memory weightList = new uint256[](tiers.length);
        for (uint256 i = 0; i < tiers.length; i++) {
            weightList[i] = tierVoteWeights[i];
        }
        return weightList;
    }

    function getVotes() public view returns (uint256[] memory) {
        uint256[] memory voteList = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            voteList[i] = votes[i];
        }
        return voteList;
    }
}