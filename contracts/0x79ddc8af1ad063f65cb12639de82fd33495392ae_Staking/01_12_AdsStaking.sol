// SPDX-License-Identifier: Unlicensed 
pragma solidity ^0.8.2;

// Building blocks
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

// Inheritance
import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

 /**
 * @title Alkimi Exchange Staking Contract
 * @author Jorge A Martinez
 * @notice This contract was developed with specific constraints around the reward function.
 * @notice Ownership of this contract is transferred on deployment to the address specified in the _owner parameter.
 */
contract Staking is IStaking, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    uint256 public constant override STAKING_CAP = 30_000_000E18;
    uint256 public constant override REWARDS_DURATION = 365 days;
    uint256 public override totalStaked;
    uint256 public override stakingPeriodStart;
    uint256 public override stakingPeriodEnd;
    uint256 public override rewardsPeriodStart;
    uint256 public override rewardsPeriodEnd;
    uint256 public override rewardAmount;
    uint256 public override initialRewardAmount;
    uint256 public override totalRewardPaid;

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public rewardPaid;
    mapping(address => uint256) public rewards;

    IERC20 public ADS;

    /* ========== MODIFIERS ========== */

    /**
     * @dev Updates a user's reward before they stake tokens, unstake tokens, and claim rewards.
     * @dev Intended to only be active when contract is stocked with reward tokens.
     */
    modifier updateReward(address account) {
        if (rewardAmount > 0) 
            rewards[account] = grossEarnings(account).sub(rewardsReceived(account));
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event StakingWindowIncrease(uint256 indexed numDays);

    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Sets the owner and ADS addreses.
     * @param _owner The public address of the EOA to own this contract.
     * @param _adsAddress $ADS contract address.
     */
    constructor(
        address _owner,
        address _adsAddress
    ) Ownable() {
        require(_owner != address(0), "Cannot set _owner to the zero address");
        require(_adsAddress != address(0), "Cannot set _adsAddress to the zero address");
        transferOwnership(_owner);
        ADS = IERC20(_adsAddress);
        stakingPeriodStart = block.timestamp;
        stakingPeriodEnd = block.timestamp.add(30 days);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Exposes the staking balance of a given account address.
     * @param account The address of the user whose staking balance you want to see.
     */
    function balanceOfStake(address account) external view override returns (uint256) {
        return stakedAmount[account];
    }

    /**
     * @dev Helper that returns whichever is sooner, the current timestamp or the rewardPeriodEnd timestamp.
     */
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, rewardsPeriodEnd);
    }

    /**
     * @dev Returns staked tokens unlock timestamp
     * @dev Only usable after staking has commenced
     */
    function tokensUnlockedTimestamp() external view override returns (uint256) {
        return (rewardsPeriodStart > 0) ? rewardsPeriodStart.add(90 days) : 0;
    }

    /**
     * @dev Calculates and exposes the rewards an account has accumulated over the reward period.
     * @dev grossEarnings = stakedAmount * rewardThatsLeft * howLongYouveBeenStaking / totalStakedAmount / 365 days.
     * @param account The address of the account you wish to see.
     */
    function grossEarnings(address account) public view override returns (uint256 earnings) {
        return stakedAmount[account].mul(rewardAmount).mul(lastTimeRewardApplicable().sub(rewardsPeriodStart)).div(totalStaked).div(365 days);
    }

    /**
     * @dev Exposes the amount of rewards an account has received.
     * @param account The address of the account whose paid out rewards you want to see.
     */
    function rewardsReceived(address account) public view override returns (uint256 rewardReceived) {
        return rewardPaid[account];
    }

    /** 
     * @dev Shows an account's live APY as people unstake and claim rewards.
     * @param account The address of the account whose APY you want to see.
     * @return Five digit sequence, first two digits are integers, last three are decimals.
     */
    function APY(address account) external view override returns (uint256) {
        uint256 rewardRemaining;
        uint256 timeSinceRewardsStarted;
        uint256 unclaimedReward;
        uint256 timeNormalizationFactor;
        uint256 rewardNormalizationFactor;
        uint256 stakeAmount = stakedAmount[account];
        { // avoid Stack too deep
            rewardRemaining = initialRewardAmount.sub(totalRewardPaid);
            timeSinceRewardsStarted = lastTimeRewardApplicable().sub(rewardsPeriodStart);
            unclaimedReward = (timeSinceRewardsStarted > 0) ? rewardRemaining.sub(rewardRemaining.mul(timeSinceRewardsStarted).div(365 days)) : 1;
            timeNormalizationFactor = (timeSinceRewardsStarted != 365 days && timeSinceRewardsStarted != 0) ? SafeMath.div(SafeMath.mul(365 days, 1E5), SafeMath.sub(365 days, timeSinceRewardsStarted)) : 1;
            rewardNormalizationFactor = (rewardAmount > 0 && rewardAmount != totalRewardPaid) ? (rewardAmount.mul(1E5)).div(rewardAmount.sub(totalRewardPaid)) : 1;
        }
        return (rewardAmount > 0 && stakeAmount > 0 && totalStaked > 0) ? (stakeAmount.mul(1E5).mul(unclaimedReward).div(totalStaked).div(stakeAmount)).mul(timeNormalizationFactor).mul(rewardNormalizationFactor).div(1E10) : 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Allows users to stake their $ADS tokens into the contract.
     * @dev Users need to give ADS staking contract an ADS allowance to transfer your tokens.
     * @param amount The amount of ADS tokens a user wants to stake in the contract.
     */
    function stake(uint256 amount) external override nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake zero tokens");
        require(totalStaked.add(amount) <= STAKING_CAP, "Staking contract has been filled");
        require(block.timestamp <= stakingPeriodEnd, "Staking period is over");
        require(rewardAmount == 0, "Rewards have already been added");
        totalStaked = totalStaked.add(amount);
        stakedAmount[msg.sender] = stakedAmount[msg.sender].add(amount);
        ADS.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Removes a user's entire staked $ADS from the contract and any rewards accumulated.
     * @dev Once you unstake, there's no staking back in.
     */
    function unstake() external override nonReentrant updateReward(msg.sender) {
        uint256 amount = stakedAmount[msg.sender];
        require(amount > 0, "You don't have staked ADS");
        require(block.timestamp >= stakingPeriodEnd, "Cannot unstake during staking period");
        require(block.timestamp >= rewardsPeriodStart.add(90 days), "Cannot unstake until three months after rewards active");
        uint256 reward = _payoutReward();
        totalStaked = totalStaked.sub(amount);
        rewardAmount = rewardAmount.sub(rewardPaid[msg.sender]);
        stakedAmount[msg.sender] = 0;
        if (reward > 0) {
            amount = amount.add(reward);
            emit RewardPaid(msg.sender, reward);
        }
        ADS.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Allows users to claim their earned rewards without unstaking their tokens.
     */
    function claimReward() external override nonReentrant updateReward(msg.sender) {
        uint256 reward = _payoutReward();
        if (reward > 0) {
            ADS.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev Tracks stakers rewards and total reward paid out.
     */
    function _payoutReward() internal returns (uint256 reward) {
        reward = rewards[msg.sender];
        if (reward > 0) {
            require(totalRewardPaid.add(reward) <= initialRewardAmount, "Out of rewards");
            rewards[msg.sender] = 0;
            rewardPaid[msg.sender] = rewardPaid[msg.sender].add(reward);
            totalRewardPaid = totalRewardPaid.add(reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @dev Allows contract owner() to load up the contract with reward tokens.
     * @dev Allows owners to add more rewards if they would like to.
     * @param reward The amount of ADS tokens the owner wants to put up for rewards.
     */
    function sendRewardTokens(uint256 reward) external override onlyOwner {
        initialRewardAmount = initialRewardAmount.add(reward);
        rewardAmount = rewardAmount.add(reward);
        if (rewardsPeriodStart == 0) {
            stakingPeriodEnd = block.timestamp;
            rewardsPeriodStart = block.timestamp;
            rewardsPeriodEnd = rewardsPeriodStart.add(REWARDS_DURATION);
        }
        ADS.safeTransferFrom(msg.sender, address(this), reward);
        emit RewardAdded(reward);
    }

    /**
     * @dev Increases the staking window by numDays.
     * @param numDays Number of days to extend the staking window by.
    //  */
    function increaseStakingPeriod(uint256 numDays) external override onlyOwner {
        stakingPeriodEnd = stakingPeriodEnd.add(numDays.mul(1 days));
        emit StakingWindowIncrease(numDays);
    }

}