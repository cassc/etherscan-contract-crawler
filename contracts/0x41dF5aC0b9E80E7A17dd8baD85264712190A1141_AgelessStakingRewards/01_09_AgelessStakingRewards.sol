// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./utils/PriceCalculator.sol";

contract AgelessStakingRewards is Ownable, ReentrancyGuard, PriceCalculator {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    address public treasury;

    enum LOCK_TIER {
        NO_LOCK,
        ONE_WEEK,
        ONE_MONTH,
        THREE_MONTH
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardPerTokenPaid;
        uint256 rewardToBeClaimed;
        uint8 lockTier;
        uint256 stakedTime;
    }

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // tier reward multiplier
    mapping (uint8 => uint256) public tierMutiplier;
    // tier => period in sec
    mapping (uint256 => uint256) public tierLockupPeriod;

    // // User address => rewardPerTokenStored
    // mapping(address => uint) public userRewardPerTokenPaid;
    // // User address => rewards to be claimed
    // mapping(address => uint) public rewards;

    mapping (address => UserInfo) public users;

    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // Total staked
    uint public totalSupply;

    constructor(address _stakingToken, address _rewardToken, address _treasury) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        treasury = _treasury;
        tierMutiplier[uint8(LOCK_TIER.NO_LOCK)] = 100;
        tierMutiplier[uint8(LOCK_TIER.ONE_WEEK)] = 125;
        tierMutiplier[uint8(LOCK_TIER.ONE_MONTH)] = 150;
        tierMutiplier[uint8(LOCK_TIER.THREE_MONTH)] = 200;
        tierLockupPeriod[uint(LOCK_TIER.NO_LOCK)] = 0;
        tierLockupPeriod[uint(LOCK_TIER.ONE_WEEK)] = 604800;
        tierLockupPeriod[uint(LOCK_TIER.ONE_MONTH)] = 2592000;
        tierLockupPeriod[uint(LOCK_TIER.THREE_MONTH)] = 7776000;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        UserInfo storage user = users[_account];

        if (_account != address(0)) {
            user.rewardToBeClaimed = earned(_account);
            user.rewardPerTokenPaid = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function tvl() public view returns (uint256) {
        return totalSupply * getTokenPriceInEthPair(IUniswapV2Router02(uniswapRouter), address(rewardsToken)) / 1e18;
    }

    function apr() public view returns (uint256) {
        uint256 reward = uint256(86400) * 365 * rewardRate;
        if (reward > 0) {
            return tvl() > 0 ? reward * getTokenPriceInEthPair(IUniswapV2Router02(uniswapRouter), address(rewardsToken)) / tvl() : 0;
        }
        return 0;
    }

    function stake(uint _amount, uint8 _lockTier) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        UserInfo storage user = users[_msgSender()];

        if (user.amount > 0) {
            require(_lockTier >= user.lockTier, 'lock tier cannot be less than previous one');
        }

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        user.amount += _amount;
        user.stakedTime = block.timestamp;
        user.lockTier = _lockTier;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        UserInfo storage user = users[_msgSender()];
        if (!claimable(_msgSender())) {
            user.rewardToBeClaimed -= user.rewardToBeClaimed * 1e12 * _amount / user.amount / 1e12;
        }
        user.amount -= _amount;
        if (user.amount == 0) {
            user.lockTier = 0;
            user.stakedTime = 0;
        }
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint) {
        UserInfo memory user = users[_account];
        uint multiplier = tierMutiplier[user.lockTier];

        return ((user.amount * (rewardPerToken() - user.rewardPerTokenPaid)) * multiplier / 100 / 1e18) + user.rewardToBeClaimed;
    }

    function claimable(address _account) public view returns (bool) {
        UserInfo memory user = users[_account];
        uint lockupPeriod = tierLockupPeriod[user.lockTier];
        return user.stakedTime + lockupPeriod <= block.timestamp;
    }

    function claimRewards() external nonReentrant updateReward(msg.sender) {
        require(claimable(_msgSender()), "not claimable");
        UserInfo storage user = users[msg.sender];
        if (user.rewardToBeClaimed > 0) {
            rewardsToken.transferFrom(treasury, msg.sender, user.rewardToBeClaimed);
            user.rewardToBeClaimed = 0;
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(treasury),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}