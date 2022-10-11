// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingReward is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    string public name;
    uint256 public duration; // Duration of rewards to be paid out (in seconds)
    uint256 public finishAt; // Timestamp of when the rewards finish
    uint256 public updatedAt; // Minimum of last updated time and reward finish time
    uint256 public rewardRate; // Reward to be paid out per second
    uint256 public rewardPerTokenStored; // Sum of (reward rate * duration * 1e18 / total supply)
    uint256 public totalSupply; // Total Staked
    uint256 public lockPeriod;
    uint256 public totalRewards;
    bool public IS_EMERGENCY;

    mapping(address => uint256) public lastStake; // timestamp when user stake
    mapping(address => uint256) public userRewardPerTokenPaid; // User address => rewardPerTokenStored
    mapping(address => uint256) public balanceOf; // User address => staked amount
    mapping(address => uint256) private rewards; // User address => rewards to be claimed

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 _amount);
    event Unstaked(address indexed user, uint256 _amount, uint256 timestamp);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address poolOwner,
        string memory _name,
        address _stakingToken,
        address _rewardsToken,
        uint256 _lockPeriod
    ) {
        transferOwnership(poolOwner);
        name = _name;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        lockPeriod = _lockPeriod;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRewardsDuration(uint256 _duration) external onlyOwner {
        require(finishAt < block.timestamp, "Reward duration not finished yet");
        duration = _duration;
        emit RewardsDurationUpdated(duration);
    }

    function notifyRewardAmount(uint256 _amount) external onlyOwner {
        if (block.timestamp > finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = rewardRate *
                (finishAt - block.timestamp);
            rewardRate = (remainingRewards + _amount) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= totalRewards,
            "Provided reward too high"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function initRewards(uint256 _amount) external onlyOwner {
        rewardsToken.transferFrom(msg.sender, address(this), _amount);
        totalRewards += _amount;
    }

    function emergencyToggle(bool _status) external onlyOwner {
        IS_EMERGENCY = _status;
    }

    function emergencyWithdrawReward() external onlyOwner {
        require(IS_EMERGENCY, "Only emergency situation");
        rewardsToken.transfer(msg.sender, totalRewards);
        totalRewards -= totalRewards;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 _amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(_amount > 0, "amount = 0");
        lastStake[msg.sender] = block.timestamp;
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            totalRewards -= reward;
            emit RewardPaid(msg.sender, reward);
        }
    }

    function unstake(uint256 _amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(_amount > 0, "Amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        require(
            block.timestamp - lastStake[msg.sender] >= lockPeriod,
            "Unable to unstake in locking period"
        );
        stakingToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, block.timestamp);
    }

    function exit() external {
        unstake(balanceOf[msg.sender]);
        getReward();
    }

    function emergencyWithdraw() public {
        require(IS_EMERGENCY, "Only emergency situation");
        uint256 balance = balanceOf[msg.sender];
        require(balance > 0, "Balance = 0");
        totalSupply -= balance;
        balanceOf[msg.sender] -= balance;
        stakingToken.transfer(msg.sender, balance);
    }

    /* ========== VIEWS ========== */

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(block.timestamp, finishAt);
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}