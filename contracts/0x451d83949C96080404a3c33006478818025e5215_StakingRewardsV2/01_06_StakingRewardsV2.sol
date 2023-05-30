// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

//
//                                 (((((((((((()                                 
//                              (((((((((((((((((((                              
//                            ((((((           ((((((                            
//                           (((((               (((((                           
//                         (((((/                 ((((((                         
//                        (((((                     (((((                        
//                      ((((((                       ((((()                      
//                     (((((                           (((((                     
//                   ((((((                             (((((                    
//                  (((((                                                        
//                ((((((                        (((((((((((((((                  
//               (((((                       (((((((((((((((((((((               
//             ((((((                      ((((((             (((((.             
//            (((((                      ((((((.               ((((((            
//          ((((((                     ((((((((                  (((((           
//         (((((                      (((((((((                   ((((((         
//        (((((                     ((((((.(((((                    (((((        
//       (((((                     ((((((   (((((                    (((((       
//      (((((                    ((((((      ((((((                   (((((      
//      ((((.                  ((((((          (((((                  (((((      
//      (((((                .((((((            ((((((                (((((      
//       ((((()            (((((((                (((((             ((((((       
//        .(((((((      (((((((.                   ((((((((     ((((((((         
//           ((((((((((((((((                         ((((((((((((((((           
//                .((((.                                    (((()         
//                                  
//                               attrace.com
//
// Based on: https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Inheritance
import "./Owned.sol";

contract StakingRewardsV2 is Owned {
    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    // Address who can configure reward strategy
    address public rewardsDistribution;

    // Timestamp when the reward period is over. It can be extended with extendPeriod function
    uint256 public periodFinish;

    // Timestamp when the lock period is over. After this participants can take out their stake without penalty. Also the rewards are unlocked by month.
    // This period CANNOT be extended with the extendPeriod function
    uint256 public lockPeriodFinish;

    // Total token reward / period duration (seconds)
    uint256 public rewardRate;

    // Specifies the length of the time window in which rewards will be provided to stakers (seconds).
    uint256 public rewardsDuration;

    // Timestamp which specifies last time the reward has been updated during staking period
    uint256 public lastUpdateTime;

    // Reward per token stored with last reward update
    uint256 public rewardPerTokenStored;

    // Penalty that staker has to pay when it unstakes its tokens before lockPeriodFinish is finished
    uint256 public withdrawPenalty;

    // The total amount of rewards paid out
    uint256 public totalRewardsPaid;

    // The total amount of rewards lost due to unstaking before lockPeriodFinish
    uint256 public totalRewardsLost;

    // Mapping of last reward per tokens stored per user, updated when user stakes, withdraws or get its rewards
    mapping(address => uint256) public userRewardPerTokenPaid;

    // Mapping of rewards per user, updated with updateReward modifier. Do not use to calculated rewards so far, use earned function instead
    mapping(address => uint256) public rewards;

    // Mapping of rewards paid out so far per user.
    mapping(address => uint256) public rewardsPaid;

    // Total balance how much has been staked by the users
    uint256 public balance;

    // Mapping of staking balance per user
    mapping(address => uint256) public balances;

    // This timestamp defines from which moment it is allowed to recover the staking token in case of issues
    uint256 public recoveryEnabledAt;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration,
        uint256 _withdrawPenalty
    ) Owned(_owner) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
        withdrawPenalty = _withdrawPenalty;
        recoveryEnabledAt = 1704067200; //  Monday, 1 January 2024 00:00:00
    }

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    // True if staking time window has past
    function isPeriodFinished() public view returns (bool) {
        return block.timestamp > periodFinish;
    }

    // Current reward per token per second
    function rewardPerToken() public view returns (uint256) {
        if (balance == 0) {
            return rewardPerTokenStored;
        }
        return (rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) /
            balance);
    }

    // Total amount of staking rewards earned by account
    function earned(address account) public view returns (uint256) {
        uint256 _rewardPerToken = rewardPerToken();
        return
            ((balances[account] *
                (_rewardPerToken - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    // Function for UI to retrieve the unlocked rewards
    function unlockedRewards(address account) public view returns (uint256) {
        return _calculateUnlocked(earned(account)) - rewardsPaid[account];
    }

    /* ========== PRIVATE VIEWS ========== */

    // Calculate how much of amount is unlocked based on current block and lockPeriod
    function _calculateUnlocked(uint256 amount) private view returns (uint256) {
        if (block.timestamp <= lockPeriodFinish) {
            return 0;
        }
        return ((amount / 12) *
            ((block.timestamp - lockPeriodFinish) / 30 days));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Stake amount in contract
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "412: cannot stake 0");
        balance += amount;
        balances[msg.sender] += amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    // Withdraw stake, note that after period is finished the caller can only withdraw its full stake
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "412: cannot withdraw 0");

        uint256 penalty;
        // before lockPeriodFinish there is a penalty
        if (block.timestamp < lockPeriodFinish) {
            require(amount == balances[msg.sender], "412: amount not valid");
            penalty = (amount / 100) * withdrawPenalty;
            // remove the penalty from the user amount to transfer
            balance -= amount;
            amount -= penalty;
            totalRewardsLost += rewards[msg.sender];
            rewards[msg.sender] = 0;
            balances[msg.sender] = 0;
            // transfer the user lost token to the contract owner
            stakingToken.transfer(owner, penalty);
        } else {
            require(amount <= balances[msg.sender], "412: amount too high");
            balance -= amount;
            balances[msg.sender] -= amount;
        }

        stakingToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, penalty);
    }

    // Withdraw all unlocked rewards
    function getReward() public updateReward(msg.sender) {
        uint256 reward = _calculateUnlocked(rewards[msg.sender]) -
            rewardsPaid[msg.sender];
        if (reward > 0) {
            rewardsPaid[msg.sender] += reward;
            totalRewardsPaid += reward;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // User exits the staking
    function exit() external {
        withdraw(balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // start the period and set the amount of the total reward
    function startPeriod(uint256 reward)
        external
        onlyRewardsDistribution
        updateReward(address(0))
    {
        require(periodFinish == 0, "412: contract already started");
        rewardRate = reward / rewardsDuration;

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 currentBalance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= currentBalance / rewardsDuration,
            "412: reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        //Set the lock period time. Note this cannot be updated
        lockPeriodFinish = periodFinish;
        emit RewardSet(reward);
    }

    // Update the amount of reward to be devided over the remaining staking time.
    function updateRewardAmount(uint256 reward)
        external
        onlyBeforePeriodFinish
        onlyRewardsDistribution
        updateReward(address(0))
    {
        uint256 remaining = periodFinish - block.timestamp;
        uint256 leftover = remaining * rewardRate;
        rewardRate = (reward + leftover) / remaining;

        uint256 currentbalance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= (currentbalance / rewardsDuration),
            "412: reward too high"
        );

        emit RewardSet(reward);
    }

    // Extend the staking window. Note that the penalty will be not applicable in the extended time.
    function extendPeriod(uint256 extendTime)
        external
        onlyBeforePeriodFinish
        onlyRewardsDistribution
        updateReward(address(0))
    {

        // leftover reward tokens left
        uint256 remaining = periodFinish - block.timestamp;
        uint256 leftover = remaining * rewardRate;
        // extend the period
        periodFinish += extendTime;
        rewardsDuration += extendTime;

        // calculate remaining time
        remaining = periodFinish - block.timestamp;
        // new rewardRate
        rewardRate = leftover / remaining;

        uint256 currentbalance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= currentbalance / rewardsDuration,
            "412: reward too high"
        );

        emit PeriodExtend(periodFinish);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        if (tokenAddress == address(stakingToken)) {
            // can only eject the staking token after timestamp defined in recoveryEnabledAt 
            require(recoveryEnabledAt <= block.timestamp, "401: recovery not allowed");
        }
        IERC20(tokenAddress).transfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRecoveryEnabledAt(uint256 _recoveryEnabledAt)
        external
        onlyOwner
    {
        require(_recoveryEnabledAt > recoveryEnabledAt, "412: ts should be in future"); 
        recoveryEnabledAt = _recoveryEnabledAt;
    }

    // Delegate restrictive function to new address
    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== MODIFIERS ========== */

    // Save in rewards the tokens earned
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // Restrict admin function
    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution || msg.sender == owner,
            "401: not allowed"
        );
        _;
    }

    // Only when contract is still within active staking time window.
    modifier onlyBeforePeriodFinish() {
        require(block.timestamp < periodFinish, "412: period is finished");
        _;
    }

    /* ========== EVENTS ========== */

    // Reward has been set
    event RewardSet(uint256 indexed reward);

    // Period is extended
    event PeriodExtend(uint256 indexed periodEnds);

    // New staking participant
    event Staked(address indexed user, uint256 amount);

    // Participant has withdrawn part or full stake
    event Withdrawn(address indexed user, uint256 amount, uint256 penalty);

    // Reward has been paid out
    event RewardPaid(address indexed user, uint256 reward);

    // recovered all token from contract
    event Recovered(address indexed token, uint256 amount);
}