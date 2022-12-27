// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ISingleRewardPool.sol";

abstract contract SingleRewardPool is ISingleRewardPool, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint256 public rewardsDuration = 12 hours;
    uint256 public totalSupply;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 public periodFinish;
    uint256 public rewardRate;
    address public immutable stakingToken;
    address public immutable rewardToken;
    address public poolRewardDistributor;
    address public seniorage;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public userLastDepositTime;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event PoolRewardDistributorUpdated(address indexed poolRewardDistributor);
    event SeniorageUpdated(address indexed seniorage);
    
    modifier onlyPoolRewardDistributor {
        require(
            msg.sender == poolRewardDistributor,
            "SingleRewardPool: caller is not the PoolRewardDistributor contract"
        );
        _;
    }
    
    modifier updateReward(address user_) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (user_ != address(0)) {
            rewards[user_] = earned(user_);
            userRewardPerTokenPaid[user_] = rewardPerTokenStored;
        }
        _;
    }
    
    /**
    * @param stakingToken_ Staking token address.
    * @param rewardToken_ Reward token address.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    * @param seniorage_ Seniorage contract address.
    */
    constructor(
        address stakingToken_,
        address rewardToken_,
        address poolRewardDistributor_,
        address seniorage_
    ) {
        stakingToken = stakingToken_;
        rewardToken = rewardToken_;
        poolRewardDistributor = poolRewardDistributor_;
        seniorage = seniorage_;
    }

    /**
    * @notice Sets the PoolRewardDistributor contract address.
    * @dev Could be called by the owner in case of address reset.
    * @param poolRewardDistributor_ PoolRewardDistributor contract address.
    */
    function setPoolRewardDistributor(address poolRewardDistributor_) external onlyOwner {
        poolRewardDistributor = poolRewardDistributor_;
        emit PoolRewardDistributorUpdated(poolRewardDistributor_);
    }
    
    /**
    * @notice Sets the Seniorage contract address.
    * @dev Could be called by the owner in case of address reset.
    * @param seniorage_ Seniorage contract address.
    */
    function setSeniorage(address seniorage_) external onlyOwner {
        seniorage = seniorage_;
        emit SeniorageUpdated(seniorage_);
    }

    /**
    * @notice Triggers stopped state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @notice Returns to normal state.
    * @dev Could be called by the owner in case of resetting addresses.
    */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
    * @notice Sets rewards duration.
    * @dev Could be called only by the owner.
    * @param rewardsDuration_ New rewards duration value.
    */
    function setRewardsDuration(uint256 rewardsDuration_) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "SingleRewardPool: duration cannot be changed now"
        );
        rewardsDuration = rewardsDuration_;
        emit RewardsDurationUpdated(rewardsDuration);
    }
    
    /**
    * @notice Deposits tokens for the user.
    * @dev Updates user's last deposit time. The deposit amount of tokens cannot be equal to 0.
    * @param amount_ Amount of tokens to deposit.
    */
    function stake(
        uint256 amount_
    ) 
        external 
        whenNotPaused
        nonReentrant 
        updateReward(msg.sender) 
    {
        require(
            amount_ > 0, 
            "SingleRewardPool: can not stake 0"
        );
        totalSupply += amount_;
        balances[msg.sender] += amount_;
        userLastDepositTime[msg.sender] = block.timestamp;
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount_);
        emit Staked(msg.sender, amount_);
    }
    
    /**
    * @notice Withdraws all tokens deposited by the user and gets rewards for him.
    * @dev Withdrawal comission is the same as for the `withdraw()` function.
    */
    function exit() external whenNotPaused {
        withdraw(balances[msg.sender]);
        getReward();
    }
    
    /**
    * @notice Notifies the contract of an incoming reward and recalculates the reward rate.
    * @dev Called by the PoolRewardDistributor contract once every 12 hours.
    * @param reward_ Reward amount.
    */
    function notifyRewardAmount(
        uint256 reward_
    ) 
        external
        onlyPoolRewardDistributor 
        updateReward(address(0)) 
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward_ / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward_ + leftover) / rewardsDuration;
        }
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration, 
            "SingleRewardPool: provided reward too high"
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward_);
    }
    
    /**
    * @notice Retrieves the total reward amount for duration.
    * @dev The function allows to get the amount of reward to be distributed in the current period.
    * @return Total reward amount for duration.
    */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }
    
    /**
    * @notice Withdraws desired amount of deposited tokens for the user.
    * @dev If 24 hours have not yet passed since the last deposit by the user, 
    * a fee of 50% is charged from the withdrawn amount of deposited tokens
    * and sent to the Seniorage contract, otherwise a 10% fee will be instead of 50%. 
    * The withdrawn amount of tokens cannot exceed the amount of the deposit or be equal to 0.
    * @param amount_ Desired amount of tokens to withdraw.
    */
    function withdraw(
        uint256 amount_
    ) 
        public 
        whenNotPaused 
        nonReentrant 
        updateReward(msg.sender) 
    {
        require(
            amount_ > 0, 
            "SingleRewardPool: can not withdraw 0"
        );
        totalSupply -= amount_;
        balances[msg.sender] -= amount_;
        uint256 seniorageFeeAmount;
        if (block.timestamp < userLastDepositTime[msg.sender] + 1 days) {
            seniorageFeeAmount = amount_ / 2;
        } else {
            seniorageFeeAmount = amount_ / 10;
        }
        IERC20(stakingToken).safeTransfer(seniorage, seniorageFeeAmount);
        IERC20(stakingToken).safeTransfer(msg.sender, amount_ - seniorageFeeAmount);
        emit Withdrawn(msg.sender, amount_ - seniorageFeeAmount);
    }

    /**
    * @notice Transfers rewards to the user.
    * @dev There are no fees on the reward.
    */
    function getReward() public whenNotPaused nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(rewardToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    /**
    * @notice Retrieves the last time reward was applicable.
    * @dev Allows the contract to correctly calculate rewards earned by users.
    * @return Last time reward was applicable.
    */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }
    
    /**
    * @notice Retrieves the amount of reward per token staked.
    * @dev The logic is derived from the StakingRewards contract.
    * @return Amount of reward per token staked.
    */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            (lastTimeRewardApplicable() - lastUpdateTime)
            * rewardRate
            * 1e18
            / totalSupply
            + rewardPerTokenStored;
    }
    
    /**
    * @notice Retrieves the amount of rewards earned by the user.
    * @dev The logic is derived from the StakingRewards contract.
    * @param user_ User address.
    * @return Amount of rewards earned by the user.
    */
    function earned(address user_) public view returns (uint256) {
        return
            balances[user_]
            * (rewardPerToken() - userRewardPerTokenPaid[user_])
            / 1e18
            + rewards[user_];
    }
}