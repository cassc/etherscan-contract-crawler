// stake: Lock tokens into our smart contract (Synthetix version?)
// withdraw: unlock tokens from our smart contract
// claimReward: users get their reward tokens
//      What's a good reward mechanism?
//      What's some good reward math?

// Added functionality ideas: Use users funds to fund liquidity pools to make income from that?

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "./RewardsDistributionRecipient.sol";
import "./Pausable.sol";
import "./Owned.sol";
import "./TokensRecoverable.sol";
// import "./IStakingRewards.sol";
// RewardsDistributionRecipient

contract StakingRewards is ReentrancyGuard, Pausable, TokensRecoverable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    /* ========== STATE VARIABLES ========== */
    
   
    

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public coolDownPeriod = 180 days;
    uint256 public rewardRate = 0;
  //  uint256 public rewardsDuration = 0;
    uint256 public lastUpdateTime;
  //  uint256 public currentPeriod;
    uint256 public rewardPerTokenStored;
    uint256 public RewardPool;
  //  uint256 lastDepositedTime;
    uint256 userCurrentLockedBalance;
    uint256 public totalLockedAmount; // total lock amount.	
	
	
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping (address => bool) private _isBlackList;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    
    struct UserInfo {
        uint256 lastDepositedTime; // keep track of deposited time for potential penalty.
        uint256 lockStartTime; // lock start time.
        uint256 lockEndTime; // lock end time.
        uint256 lockedAmount; // amount deposited during lock period.
    }
    
    
    mapping(address => UserInfo) public userInfo;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
   //     address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
     //   rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp;
    }  

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

  /*  function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }  */
    

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant notPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        checkStake(amount, msg.sender);   
 
    }

  function whitelist(address user, uint256 amount) public onlyOwner {
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
       
    }



    function checkStake(
        uint256 amount,
        
        address _user
    ) internal {
        UserInfo storage user = userInfo[_user];
        if (user.lockStartTime == block.timestamp) {
                user.lockedAmount = userCurrentLockedBalance;
                totalLockedAmount += user.lockedAmount;
                
            }
        // Calculate the total lock duration and check whether the lock duration meets the conditions.
 //       uint256 totalLockDuration = _lockDuration;
   //     if (user.lockEndTime >= block.timestamp) {
            // Adding funds during the lock duration is equivalent to re-locking the position, needs to update some variables.
            if (amount > 0) {
                user.lockStartTime = block.timestamp;
                totalLockedAmount -= user.lockedAmount;
                user.lockedAmount = 0;
            }
            
            if (amount > 0) {
            user.lastDepositedTime = block.timestamp;
        }
        
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
         emit Staked(msg.sender, amount, block.timestamp);
         }
     //    emit stake(_user, _amount, block.timestamp);
            
            
   function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(_getBlackStatus(msg.sender) == false , "Address in blacklist");
     ///   checkWithdraw(0, amount);
	
        
   /// function checkWithdraw(uint256 amount) internal {
        UserInfo storage user = userInfo[msg.sender];
       require(block.timestamp >= (user.lastDepositedTime).add(coolDownPeriod), "Too soon to leave.");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        require(_getBlackStatus(msg.sender) == false , "Address in blacklist");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            //_balances[msg.sender] = _balances[msg.sender].sub(reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
function addBlackList (address _evilUser) public onlyOwner {
        _isBlackList[_evilUser] = true;
    }
    
    function removeBlackList (address _clearedUser) public onlyOwner {
        _isBlackList[_clearedUser] = false;
    }

    function _getBlackStatus(address _maker) private view returns (bool) {
        return _isBlackList[_maker];
    }
    function exit() external {
       // withdraw(_balances[msg.sender]);
        getReward();
    }
    

    /* ========== RESTRICTED FUNCTIONS ========== */
    
    
    function feedRewardPool() external {
         uint256 reward = rewardsToken.allowance(msg.sender, address(this));
         RewardPool += reward;
         require(rewardsToken.transferFrom(msg.sender, address(this), reward));
         require(msg.sender == owner, "only owner can deposit tokens");
          //Transfers the tokens to smart contract
    }

  function setRewardRate(uint256 _rewardRate) external onlyOwner {
  	rewardRate = _rewardRate;
  emit RewardRateUpdated(rewardRate);
    }
    
    
    
  
  
   /*  function notifyRewardAmount(uint reward) external updateReward(address(0)) {
    
       if (block.timestamp >= periodFinish) {
       
            rewardRate = reward.div(rewardsDuration);
          } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

      lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration); 
        emit RewardAdded(reward);
    }  */

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
 /*   function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }  */
    

 /*   function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    } */

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
           
        }
        _;
    }

    /* ========== EVENTS ========== */

  //  event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRewardRate);
  //  event Recovered(address token, uint256 amount);
}