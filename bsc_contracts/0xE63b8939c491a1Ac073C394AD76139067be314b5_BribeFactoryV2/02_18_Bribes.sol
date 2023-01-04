// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IMinter.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './libraries/Math.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import 'hardhat/console.sol';


interface IERC20Ext {
    function name() external returns(string memory);
    function symbol() external returns(string memory);
}

contract Bribe is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant WEEK = 7 days; // rewards are released over 7 days
    uint256 public firstBribeTimestamp;

    /* ========== STATE VARIABLES ========== */

    struct Reward {
        uint256 periodFinish;
        uint256 rewardsPerEpoch;
        uint256 lastUpdateTime; 
    }

    mapping(address => mapping(uint => Reward)) public rewardData;  // token -> startTimestamp -> Reward
    mapping(address => bool) public isRewardToken;
    address[] public rewardTokens;
    address public voter;
    address public bribeFactory;
    address public minter;
    address public ve;
    address public owner;

    string public TYPE;

    // tokenId -> reward token -> lastTime
    mapping(uint256 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(uint256 => mapping(address => uint256)) public userTimestamp;

    //uint256 private _totalSupply;
    mapping(uint256 => uint256) public _totalSupply;
    mapping(uint256 => mapping(uint256 => uint256)) private _balances; //tokenId -> timestamp -> amount

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner,address _voter,address _bribeFactory, string memory _type)  {
        require(_bribeFactory != address(0) && _voter != address(0) && _owner != address(0));
        voter = _voter;
        bribeFactory = _bribeFactory;
        firstBribeTimestamp = 0;
        ve = IVoter(_voter)._ve();
        minter = IVoter(_voter).minter();
        require(minter != address(0));
        owner = _owner;

        TYPE = _type;
    }

    function getEpochStart() public view returns(uint){
        return IMinter(minter).active_period();
    }

    function getNextEpochStart() public view returns(uint){
        return getEpochStart() + WEEK;
    }

    function addReward(address _rewardsToken) public {
        require( (msg.sender == owner || msg.sender == bribeFactory), "addReward: permission is denied!" );
        require(!isRewardToken[_rewardsToken], "Reward token already exists");

        isRewardToken[_rewardsToken] = true;
        rewardTokens.push(_rewardsToken);
    }

    /* ========== VIEWS ========== */

    function rewardsListLength() external view returns(uint256) {
        return rewardTokens.length;
    }

    function totalSupply() external view returns (uint256) {
        uint256 _currentEpochStart = IMinter(minter).active_period(); // claim until current epoch
        return _totalSupply[_currentEpochStart];
    }

    function totalSupplyAt(uint256 _timestamp) external view returns (uint256) {
        return _totalSupply[_timestamp];
    }

    
    function balanceOfAt(uint256 tokenId, uint256 _timestamp) public view returns (uint256) {
        return _balances[tokenId][_timestamp];
    }

    // get last deposit available balance (getNextEpochStart)
    function balanceOf(uint256 tokenId) public view returns (uint256) {
        uint256 _timestamp = getNextEpochStart();
        return _balances[tokenId][_timestamp];
    }


    function earned(uint256 tokenId, address _rewardToken) public view returns(uint256){
        uint k = 0;
        uint reward = 0;
        uint256 _endTimestamp = IMinter(minter).active_period(); // claim until current epoch
        uint256 _userLastTime = userTimestamp[tokenId][_rewardToken];

        if(_endTimestamp == _userLastTime){
            return 0;
        }

        // if user first time then set it to firstBribe as start scan
        if(_userLastTime == 0){
            _userLastTime = firstBribeTimestamp;
        }

        for(k; k < 50; k++){
            reward += _earned(tokenId, _rewardToken, _userLastTime);
            _userLastTime = _userLastTime + WEEK;
            if(_userLastTime >= _endTimestamp){
                // if we reach the current epoch, exit
                break;
            }
        }  
        return reward;  
    }

    function _earned(uint256 tokenId, address _rewardToken, uint256 _timestamp) internal view returns (uint256) {
        uint256 _balance = balanceOfAt(tokenId, _timestamp);
        if(_balance == 0){
            return 0;
        } else {
            uint256 _rewardPerToken = rewardPerToken(_rewardToken, _timestamp);
            uint256 _rewards = _rewardPerToken * _balance / 1e18;
            return _rewards;
        }
    }

    function rewardPerToken(address _rewardsToken, uint256 _timestmap) public view returns (uint256) {
        if (_totalSupply[_timestmap] == 0) {
            return rewardData[_rewardsToken][_timestmap].rewardsPerEpoch;
        }
        return rewardData[_rewardsToken][_timestmap].rewardsPerEpoch * 1e18 / _totalSupply[_timestmap];
    }

 
    /* ========== MUTATIVE FUNCTIONS ========== */

    function _deposit(uint256 amount, uint256 tokenId) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(msg.sender == voter);
        uint256 _startTimestamp = IMinter(minter).active_period() + WEEK;
        uint256 _oldSupply = _totalSupply[_startTimestamp]; 
        _totalSupply[_startTimestamp] =  _oldSupply + amount;
        _balances[tokenId][_startTimestamp] = _balances[tokenId][_startTimestamp] + amount;
        emit Staked(tokenId, amount);
    }

    function _withdraw(uint256 amount, uint256 tokenId) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(msg.sender == voter);
        uint256 _startTimestamp = IMinter(minter).active_period() + WEEK; 
        // incase of bribe contract reset in gauge proxy
        if (amount <= _balances[tokenId][_startTimestamp]) {
            uint256 _oldSupply = _totalSupply[_startTimestamp]; 
            uint256 _oldBalance = _balances[tokenId][_startTimestamp];
            _totalSupply[_startTimestamp] =  _oldSupply - amount;
            _balances[tokenId][_startTimestamp] =  _oldBalance - amount;
            emit Withdrawn(tokenId, amount);
        }

    }

    function getReward(uint tokenId, address[] memory tokens) external nonReentrant  {
        require(IVotingEscrow(ve).isApprovedOrOwner(msg.sender, tokenId));
        uint256 _endTimestamp = IMinter(minter).active_period(); // claim until current epoch
        uint256 reward = 0;
        address _owner = IVotingEscrow(ve).ownerOf(tokenId);
        
        for (uint256 i = 0; i < tokens.length; i++) {
            address _rewardToken = tokens[i];
            reward = earned(tokenId, _rewardToken);          
            if (reward > 0) {
                IERC20(_rewardToken).safeTransfer(_owner, reward);
                emit RewardPaid(_owner, _rewardToken, reward);
            }
            userTimestamp[tokenId][_rewardToken] = _endTimestamp;
        }
    }

    function getRewardForOwner(uint tokenId, address[] memory tokens) public nonReentrant  {
        require(msg.sender == voter);
        uint256 _endTimestamp = IMinter(minter).active_period(); // claim until current epoch
        uint256 reward = 0;
        address _owner = IVotingEscrow(ve).ownerOf(tokenId);

        for (uint256 i = 0; i < tokens.length; i++) {
            address _rewardToken = tokens[i];
            reward = earned(tokenId, _rewardToken);     
            if (reward > 0) {
                IERC20(_rewardToken).safeTransfer(_owner, reward);
                emit RewardPaid(_owner, _rewardToken, reward);
            }
            userTimestamp[tokenId][_rewardToken] = _endTimestamp;
        }
    }

    function notifyRewardAmount(address _rewardsToken, uint256 reward) external nonReentrant {
        require(isRewardToken[_rewardsToken], "reward token not verified");
        IERC20(_rewardsToken).safeTransferFrom(msg.sender,address(this),reward);

        uint256 _startTimestamp = IMinter(minter).active_period() + WEEK; //period points to the current thursday. Bribes are distributed from next epoch (thursday)
        if(firstBribeTimestamp == 0){
            _startTimestamp = (block.timestamp / WEEK * WEEK) + WEEK; //if first then save current thursday
            firstBribeTimestamp = _startTimestamp;
        }

        uint256 _lastReward = rewardData[_rewardsToken][_startTimestamp].rewardsPerEpoch;
        
        rewardData[_rewardsToken][_startTimestamp].rewardsPerEpoch = _lastReward + reward;
        rewardData[_rewardsToken][_startTimestamp].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken][_startTimestamp].periodFinish = _startTimestamp + WEEK;

        emit RewardAdded(_rewardsToken, reward, _startTimestamp);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)));
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setVoter(address _Voter) external onlyOwner {
        require(_Voter != address(0));
        voter = _Voter;
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
    }

    function addRewardToken(address _token) external onlyOwner {
        require(_token != address(0));
        isRewardToken[_token] = true;
        rewardTokens.push(_token);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }

    /* ========== MODIFIERS ========== */

    /* ========== EVENTS ========== */

    event RewardAdded(address rewardToken, uint256 reward, uint256 startTimestamp);
    event Staked(uint256 indexed tokenId, uint256 amount);
    event Withdrawn(uint256 indexed tokenId, uint256 amount);
    event RewardPaid(address indexed user,address indexed rewardsToken,uint256 reward);
    event Recovered(address token, uint256 amount);
}