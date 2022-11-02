//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ERC20Staking is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => bool) public rewardsDistribution;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier onlyRewardsDistribution() {
        require(rewardsDistribution[msg.sender] == true, "Caller is not RewardsDistribution contract");
        _;
    }

    modifier updateReward(address account) {
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    constructor(
        address _stakingToken,
        address _rewardsToken,
        address _rewardsDistribution
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        decimals = IERC20Metadata(_stakingToken).decimals();
        rewardsDistribution[_rewardsDistribution] = true;
    }

    function setRewardsDistribution(address _rewardsDistribution, bool _isRewardsDistribution) external onlyOwner {
        rewardsDistribution[_rewardsDistribution] = _isRewardsDistribution;
    }

    function earned(address account) public view returns (uint256) {
        return
            ((balanceOf[account] * (rewardPerTokenStored - userRewardPerTokenPaid[account])) / 10**decimals) +
            rewards[account];
    }

    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(balanceOf[msg.sender]);
        getReward();
    }

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution {
        if (totalSupply == 0) return;
        if (rewardPerTokenStored == 0) {
            rewardPerTokenStored += (rewardsToken.balanceOf(address(this)) * 10**decimals) / totalSupply;
        } else {
            rewardPerTokenStored += (reward * 10**decimals) / totalSupply;
        }
        emit RewardAdded(reward);
    }
}