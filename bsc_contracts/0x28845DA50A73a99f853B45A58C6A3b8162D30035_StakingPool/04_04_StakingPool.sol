// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
/// @title SafeOne Chain Single Staking Pool Rewards Smart Contract 
/// @author @m3tamorphTECH
/// @notice Designed based on the Synthetix staking rewards contract

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error TokensLocked();
error TokensUnlocked();

contract StakingPool is Ownable {
   
    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    uint public poolDuration;
    uint public poolStartTime;
    uint public poolEndTime;
    uint public updatedAt;
    uint private _totalStaked;

    address payable public teamWallet;
    uint public immutable earlyWithdrawFee = 10;
    uint public immutable lockPeriod = 3 days;

    uint public rewardRate; 
    uint public rewardPerTokenStored; 

    mapping(address => uint) public userStakedBalance;
    mapping(address => uint) public userUnlockedTime;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public userRewards; 

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            userRewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken) {
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        teamWallet = payable(0x87Cd02775eba9233D1b27aE5340Ece05d7FBd841);
    }

    receive() external payable {
        teamWallet.transfer(msg.value);
    }

    fallback() external payable {
        teamWallet.transfer(msg.value);
    }
    
   /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint _amount) external updateReward(msg.sender) {
        if(_amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] += _amount;
        _totalStaked += _amount;
        userUnlockedTime[msg.sender] = block.timestamp + lockPeriod;
        bool success = stakedToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert();
        emit Staked(msg.sender, _amount);
    }

    function withdraw() public updateReward(msg.sender) {
        if(block.timestamp < userUnlockedTime[msg.sender]) revert TokensLocked();
        uint amount = userStakedBalance[msg.sender];
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;
        bool success = stakedToken.transfer(msg.sender, amount);
        if (!success) revert();
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyWithdraw() public updateReward(msg.sender) {
        if(block.timestamp > userUnlockedTime[msg.sender]) revert TokensUnlocked();
       
        uint _amount = userStakedBalance[msg.sender];
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= _amount;

        uint fee = _amount * earlyWithdrawFee / 100;
        stakedToken.transfer(teamWallet, fee);

        uint amountReceived = _amount - fee;
        bool success = stakedToken.transfer(msg.sender, amountReceived);
        if (!success) revert();
        emit Withdrawn(msg.sender, _amount);
    }

    function claimRewards() public updateReward(msg.sender) {
        uint rewards = userRewards[msg.sender];
        if (rewards > 0) {
            userRewards[msg.sender] = 0;
            bool success = rewardToken.transfer(msg.sender, rewards);
            if (!success) revert();
            emit RewardPaid(msg.sender, rewards);
        }
    }

    /* ========== VIEW & GETTER FUNCTIONS ========== */

    function earned(address _account) public view returns (uint) {
        return (userStakedBalance[_account] * 
            (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18
            + userRewards[_account];
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(block.timestamp, poolEndTime);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate *
        (lastTimeRewardApplicable() - updatedAt) * 1e18
        ) / _totalStaked;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function totalRewardTokens() public view returns (uint) {
        if (rewardToken == stakedToken) {
            return (rewardToken.balanceOf(address(this)) - _totalStaked);
        }
        return rewardToken.balanceOf(address(this));
    }

    function balanceOf(address _account) external view returns (uint256) {
        return userStakedBalance[_account];
    }

    /* ========== OWNER RESTRICTED FUNCTIONS ========== */

    function setPoolDuration(uint _duration) external onlyOwner {
        require(poolEndTime < block.timestamp, "Pool still live");
        poolDuration = _duration;
    }

    function setPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
        if (block.timestamp >= poolEndTime) {
            rewardRate = _amount / poolDuration;
        } else {
            uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / poolDuration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * poolDuration <= rewardToken.balanceOf(address(this)),
            "reward amount > balance. Fund this contract with more reward tokens."
        );

        poolStartTime = block.timestamp;
        poolEndTime = block.timestamp + poolDuration;
        updatedAt = block.timestamp;
    } 

    function topUpPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
        uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (_amount + remainingRewards) / poolDuration;
        
        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * poolDuration <= rewardToken.balanceOf(address(this)),
            "reward amount > balance. Fund this contract with more reward tokens."
        );
        updatedAt = block.timestamp;
    } 

    function withdrawPoolRewards(uint256 _amount) external onlyOwner updateReward(address(0)) {
        uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (remainingRewards - _amount) / poolDuration;

        require(rewardRate > 0, "reward rate = 0");

        bool success = rewardToken.transfer(address(msg.sender), _amount);
        if (!success) revert();

        require(
            rewardRate * poolDuration <= rewardToken.balanceOf(address(this)),
            "reward amount > balance. Fund this contract with more reward tokens."
        );
        updatedAt = block.timestamp;
    }

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }
}