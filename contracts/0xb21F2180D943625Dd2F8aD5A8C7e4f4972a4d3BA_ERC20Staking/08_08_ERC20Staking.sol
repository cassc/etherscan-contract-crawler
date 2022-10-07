// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @author Acquire.Fi
/// @title Acquire.Fi - ACQ LP staking contract
/// @notice Staking Contract that uses the Synthetix Staking model to distribute ACQ(ERC-20) token rewards in a dynamic way, proportionally based on the amount of LP Tokens staked by each staker at any given time

contract ERC20Staking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stakedToken;
    IERC20 public rewardsToken;

    bool public claiming;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 private rewardPerTokenStored;
    uint256 public totalStakedSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;
    mapping(uint256 => address) public stakedAssets;
    mapping(address => uint256) private tokensStaked;

    /// @param _stakedToken the address of the LP Token Contract
    /// @param _rewardsToken the address of the ERC20 token used for rewards
    constructor(address _stakedToken, address _rewardsToken) {
        stakedToken = IERC20(_stakedToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    /// @notice functon called by the users to Stake LP Tokens
    /// @param amount of the LP Tokens to be staked
    /// @dev the LP Tokens amount has to be prevoiusly approved for transfer in the ERC20 contract with the address of this contract
    function stake(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount != 0, "Staking: amount can't be 0!");
        stakedToken.safeTransferFrom(msg.sender, address(this), amount);
        tokensStaked[msg.sender] += amount;
        totalStakedSupply += amount;
        emit Staked(msg.sender, amount);
    }

    /// @notice function called by the user to Withdraw LP Tokens from staking
    /// @param amount of LP Tokens to be withdrawn
    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount != 0, "Staking: amount can't be 0!");
        stakedToken.safeTransfer(msg.sender, amount);
        tokensStaked[msg.sender] -= amount;
        totalStakedSupply -= amount;
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice function called by the user to claim his accumulated rewards
    function claimRewards() public nonReentrant updateReward(msg.sender) {
        require(claiming, "Rewards claiming in not yet enabled!");
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice function called by the user to withdraw all LP Tokens and claim the rewards in one transaction
    function withdrawAll() external {
        withdraw(tokensStaked[msg.sender]);
        claimRewards();
    }

    /// @notice function useful for Front End to see the stake and rewards for users
    /// @param _user the address of the user to get informations for
    /// @return _tokensStaked amount of LP Tokens that are staked by the user
    /// @return _availableRewards the rewards accumulated by the user
    function userStakeInfo(address _user)
        public
        view
        returns (uint256 _tokensStaked, uint256 _availableRewards)
    {
        _tokensStaked = tokensStaked[_user];
        _availableRewards = calculateRewards(_user);
    }

    /// @notice function for the Owner of the Contract to set the Staking to initialize a staking period and set the amount of tokens to be distributed as rewards in that period
    /// @param _amount the amount of Reward Tokens to be distributed
    /// @param _duration the duration in with the rewards will be distributed, in seconds
    function setStakingPeriod(uint256 _amount, uint256 _duration)
        external
        onlyOwner
    {
        setRewardsDuration(_duration);
        addRewardAmount(_amount);
    }

    /// @notice function used by owner to enable or disable the claimRewards function
    /// @param _newState the state of claiming
    function setClaimingState(bool _newState) external onlyOwner {
        claiming = _newState;
    }

    /// @return _lastRewardsApplicable the last time the rewards were applicable, returns block.timestamp if the rewards period is not ended
    function lastTimeRewardApplicable()
        public
        view
        returns (uint256 _lastRewardsApplicable)
    {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /// @notice calculates the rewards per token for the current time whenever a new deposit/withdraw is made to keep track of the correct token distribution between stakers
    function rewardPerToken() public view returns (uint256) {
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / totalStakedSupply);
    }

    /// @notice used to calculate the earned rewards for a user
    /// @param _user the address of the user to calculate available rewards for
    /// @return _rewards the amount of tokens available as rewards for the passed address
    function calculateRewards(address _user)
        public
        view
        returns (uint256 _rewards)
    {
        return
            ((tokensStaked[_user] *
                (rewardPerToken() - userRewardPerTokenPaid[_user])) / 1e18) +
            rewards[_user];
    }

    /// @return _distributedTokens the total amount of ERC20 Tokens distributed as rewards for the set staking period
    function getRewardForDuration()
        external
        view
        returns (uint256 _distributedTokens)
    {
        return rewardRate * rewardsDuration;
    }

    /// @notice function used by the Owner to add rewards to be distributed in the set staking period. Rewards can be added multiple times in the same staking period; this will increase the rewards rate for the active period.
    /// @param reward the amount of tokens to be added to the rewards pool
    /// @dev the Staking Contract have to already own enough Rewards Tokens to distribute all the rewards, so make sure to send all the tokens to the contract before calling this function
    function addRewardAmount(uint256 reward)
        public
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration,
            "Staking: Provided reward too high"
        );
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    /// @notice function used by the Owner to set the duration of a staking period. Multiple staking periods can be made in this contract, but one has to end before another is started.
    /// @param _rewardsDuration the duration of the staking period in seconds
    function setRewardsDuration(uint256 _rewardsDuration) internal {
        require(
            block.timestamp > periodFinish,
            "Staking: Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /// @notice modifier used to keep track of the dynamic rewards for user each time a deposit or withdraw is made
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = calculateRewards(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
}