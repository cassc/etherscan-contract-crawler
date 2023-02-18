// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title Single Staking Pool Rewards Smart Contract 
/// @author @m3tamorphTECH
/// @notice Designed based on the OG Synthetix staking rewards contract
/// @dev version 1.3 - compatible with 9 decimal tokens

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IWETH.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error InvalidAddress();
error TokensLocked();

contract SafeOneChainStakingPool {
    using SafeERC20 for IERC20;
   
    /* ========== STATE VARIABLES ========== */

    address public owner;
    address payable public teamWallet;
    IWETH public immutable WBNB = IWETH(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    uint public constant EARLY_UNSTAKE_FEE = 1000;
    uint public constant LOCK_PERIOD = 3 days;
    uint public poolDuration;
    uint public poolStartTime;
    uint public poolEndTime;
    uint public updatedAt;
    uint public rewardRate; 
    uint public rewardPerTokenStored; 
    uint private _totalStaked;

    mapping(address => uint) public userStakedBalance;
    mapping(address => uint) public userUnlockedTime;
    mapping(address => uint) public userPaidRewards;
    mapping(address => uint) userRewardPerTokenPaid;
    mapping(address => uint) userRewards; 

    /* ========== MODIFIERS ========== */

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            userRewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyOwner() {
        if(msg.sender != owner) revert InvalidAddress();
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken) payable {
        owner = msg.sender;
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        teamWallet = payable(0x87Cd02775eba9233D1b27aE5340Ece05d7FBd841);
    }

    receive() external payable {}
    
   /* ========== MUTATIVE FUNCTIONS ========== */

    // might have to make these functions internal (since the tokens arent actually being transferred)
    function stake(uint _amount) external updateReward(msg.sender) {
        if(_amount <= 0) revert InvalidAmount();
        _totalStaked += _amount;
        userStakedBalance[msg.sender] += _amount;
        userUnlockedTime[msg.sender] = block.timestamp + LOCK_PERIOD;
        stakedToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function unstake(uint _amount) external updateReward(msg.sender) {
        if(block.timestamp < userUnlockedTime[msg.sender]) revert TokensLocked();
        if(_amount <= 0) revert InvalidAmount();
        if(_amount > userStakedBalance[msg.sender]) revert InvalidAmount();
        _totalStaked -= _amount;
        userStakedBalance[msg.sender] -= _amount;
        stakedToken.safeTransfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function emergencyUnstake() external updateReward(msg.sender) {
        uint amount = userStakedBalance[msg.sender];
        if(amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;
        uint fee = amount * EARLY_UNSTAKE_FEE / 10000;
        uint amountDue = amount - fee;
        stakedToken.safeTransfer(teamWallet, fee);
        stakedToken.safeTransfer(msg.sender, amountDue);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() public updateReward(msg.sender) {
        uint rewards = userRewards[msg.sender];
        if (rewards > 0) {
            userRewards[msg.sender] = 0;
            userPaidRewards[msg.sender] += rewards;
            if(rewardToken == IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)) {
                WBNB.withdraw(rewards);
                (bool success, ) = msg.sender.call{value: rewards}("");
                require(success, "Transfer of beans failed.");
            } else
            rewardToken.safeTransfer(msg.sender, rewards);
            emit RewardPaid(msg.sender, rewards);
        }
    }

    /* ========== VIEW & GETTER FUNCTIONS ========== */

    function earned(address _account) public view returns (uint) {
        return (userStakedBalance[_account] * 
            (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18 
            + userRewards[_account];
    }

    function lastTimeRewardApplicable() internal view returns (uint) {
        return _min(block.timestamp, poolEndTime);
    }

    function rewardPerToken() internal view returns (uint) {
        if (_totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / _totalStaked;
    }

    function _min(uint x, uint y) internal pure returns (uint) {
        return x <= y ? x : y;
    }

    function totalRewardTokens() internal view returns (uint) {
        if (rewardToken == stakedToken) {
            return (rewardToken.balanceOf(address(this)) - _totalStaked);
        }
        return rewardToken.balanceOf(address(this));
    }

    function balanceOf(address _account) external view returns (uint) {
        return userStakedBalance[_account];
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }

    /* ========== OWNER RESTRICTED FUNCTIONS ========== */

    function setPoolDuration(uint _duration) external onlyOwner {
        require(poolEndTime < block.timestamp, "Pool still live");
        poolDuration = _duration;
    }

    function setPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
        if (_amount <= 0) revert InvalidAmount();
        if (block.timestamp >= poolEndTime) {
            rewardRate = _amount / poolDuration;
        } else {
            uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / poolDuration;
        }
        if(rewardRate <= 0) revert InvalidAmount();
        //if(rewardRate * poolDuration > totalRewardTokens()) revert InvalidAmount();
        poolStartTime = block.timestamp;
        poolEndTime = block.timestamp + poolDuration;
        updatedAt = block.timestamp;
    } 

    function topUpPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
        uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (_amount + remainingRewards) / poolDuration;
        if(rewardRate <= 0) revert InvalidAmount();
        // if(stakedToken == rewardToken) {
        //     if(rewardRate * poolDuration > rewardToken.balanceOf(address(this)) - _totalStaked) revert InvalidAmount();
        // } else {
        //     if(rewardRate * poolDuration > rewardToken.balanceOf(address(this))) revert InvalidAmount();
        // }
        updatedAt = block.timestamp;
    } 

    function withdrawPoolRewards(uint256 _amount) external onlyOwner updateReward(address(0)) {
        uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (remainingRewards - _amount) / poolDuration;
        require(rewardRate > 0, "reward rate = 0");
        // if(stakedToken == rewardToken) {
        //     if(rewardRate * poolDuration > rewardToken.balanceOf(address(this)) - _totalStaked) revert InvalidAmount();
        // } else {
        //     if(rewardRate * poolDuration > rewardToken.balanceOf(address(this))) revert InvalidAmount();
        // }
        rewardToken.safeTransfer(address(msg.sender), _amount);
        updatedAt = block.timestamp;
    }

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        if(_newOwner == address(0)) revert InvalidAddress();
        owner = _newOwner;
    }

    function wrapBeans() external onlyOwner {
        uint balance = address(this).balance;
        IWETH(WBNB).deposit{value: balance}();
        assert(IWETH(WBNB).transfer(address(this), balance));
    }

    function unwrapBeans() external onlyOwner {
        uint balance = WBNB.balanceOf(address(this));
        WBNB.withdraw(balance);
        assert(address(this).balance >= balance);
    }

    function recoverBeans() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function recoverWrongToken(IERC20 _token) external onlyOwner {
        uint balance = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, balance);
    }
}