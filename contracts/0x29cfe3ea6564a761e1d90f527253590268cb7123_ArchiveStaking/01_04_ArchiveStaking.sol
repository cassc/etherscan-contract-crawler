// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ArchiveStaking is Ownable {
    struct Staking {
        uint256 lastReward;
        uint256 amount;
        uint256 rewarded;
        uint256 pendingReward;
        bool isUnstaked;
        bool isInitialized;
    }

    mapping(address => Staking) public stakers;

    uint256 public maxApr = 1000000;
    uint256 public minStaking = 1 * 10 ** 18;
    uint256 public totalStaked;
    uint256 public totalEth;

    uint256 public rewardPeriod = 300;
    uint256 private rewardPeriodsPerYear = 365 days / rewardPeriod;

    bool public stakingEnabled = true;
    bool public claimEnabled = true;

    IERC20 private token;

    event Stake(address indexed staker, uint256 amount, uint totalStaked);
    event Reward(address indexed staker, uint256 amount);
    event UnStake(address indexed staker, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
    * @notice Starts a new staking or adds tokens to the active staking.
    * @param amount Amount of Archive tokens to stake.
    */
    function stake(uint256 amount) external {
        require(stakingEnabled, "disabled");
        require(amount >= minStaking, "less than minimum");

        address staker = _msgSender();

        require(token.balanceOf(staker) >= amount, "insufficient token");
        require(token.allowance(staker, address(this)) >= amount, "not allowed");

        if (stakers[staker].isInitialized && !stakers[staker].isUnstaked) {
            stakers[staker].pendingReward = _getStakingReward(stakers[staker]);
            stakers[staker].amount += amount;
            stakers[staker].lastReward = block.timestamp;
        } else {
            stakers[staker] = Staking(block.timestamp, amount, 0, 0, false, true);
        }

        totalStaked += amount;
        token.transferFrom(staker, address(this), amount);

        emit Stake(staker, amount, stakers[staker].amount);
    }

    /**
    * @notice Claim rewards and withdraw the amount of tokens from staking.
    * @param amount Amount of tokens to unstake.
    */
    function unstake(uint256 amount) external {
        address staker = _msgSender();

        Staking storage staking = stakers[staker];
        require(amount <= staking.amount, "insufficient token");

        _claim(staker);

        if (staking.amount == amount) {
            staking.isUnstaked = true;
            staking.amount = 0;
        } else {
            staking.amount -= amount;
        }

        totalStaked -= amount;
        token.transfer(staker, amount);

        emit UnStake(staker, amount);
    }

    /**
    * @notice Claim rewards to staker account.
    */
    function claim() external {
        _claim(_msgSender());
    }

    /**
    * @notice Handle deposit of eth amount to smart contract account.
    */
    receive() external payable {
        if (msg.value > 0) {
            totalEth += msg.value;
        }
    }

    /**
    * @notice Handle deposit of eth amount to smart contract account.
    */
    fallback() external payable {
        if (msg.value > 0) {
            totalEth += msg.value;
        }
    }

    /**
    * @notice Withdraw ETH from smart contract account.
    * @param to Address to withdraw.
    * @param amount Amount of ETH to withdraw.
    */
    function withdrawEth(address to, uint256 amount) external onlyOwner {
        _withdrawEth(to, amount);
    }

    /**
    * @notice Set the rewards period in seconds for charge rewards.
    * @param _rewardPeriod Period each {_rewardPeriod} seconds charge rewards.
    */
    function setRewardPeriod(uint256 _rewardPeriod) external onlyOwner {
        require(_rewardPeriod > 0, "less than one");
        rewardPeriod = _rewardPeriod;
        rewardPeriodsPerYear = 365 days / _rewardPeriod;
    }

    /**
    * @notice Set the maximum of APR (Annual Percentage Rate).
    * @param _maxApr Maximum Annual Percentage Rate.
    */
    function setMaxApr(uint256 _maxApr) external onlyOwner {
        maxApr = _maxApr;
    }

    /**
    * @notice Turn on or off staking operation.
    * @param _stakingEnabled Flag to set true or false.
    */
    function setStakingEnabled(bool _stakingEnabled) external onlyOwner {
        stakingEnabled = _stakingEnabled;
    }

    /**
    * @notice Turn on or off claiming rewards operation.
    * @param _claimEnabled Flag to set true or false.
    */
    function setClaimEnabled(bool _claimEnabled) external onlyOwner {
        claimEnabled = _claimEnabled;
    }

    /**
    * @notice Get the rewards amount for the staker account.
    * @param staker Address of the staker account.
    */
    function getStakingReward(address staker) public view returns (uint256) {
        return _getStakingReward(stakers[staker]);
    }

    /**
    * @notice Returns APR for staker based on staked amount and total ETH on smart contract balance.
    */
    function getApr(address staker) public view returns (uint256) {
        return _getApr(stakers[staker]);
    }

    /**
    * @notice Withdraw ETH from smart contract account.
    * @param to Address to withdraw.
    * @param amount Amount of ETH to withdraw.
    */
    function _withdrawEth(address to, uint256 amount) private {
        require(totalEth >= amount, "insufficient eth");
        payable(to).transfer(amount);
        totalEth -= amount;
    }

    /**
    * @notice Rewards calculation and withdraw to staker account.
    * @param staker Staker account address.
    */
    function _claim(address staker) private {
        require(claimEnabled, "disabled");

        Staking storage staking = stakers[staker];
        uint256 reward = _getStakingReward(staking);

        staking.lastReward = block.timestamp;
        staking.rewarded += reward;
        staking.pendingReward = 0;

        _withdrawEth(staker, reward);

        emit Reward(staker, reward);
    }

    /**
    * @notice Rewards calculation for staking
    * @param staking Staking record
    */
    function _getStakingReward(Staking storage staking) private view returns (uint256) {
        require(staking.isInitialized && !staking.isUnstaked, "no staking");

        uint256 apr = _getApr(staking);
        uint256 rewardsTime = block.timestamp - staking.lastReward;

        uint256 periods = rewardsTime / rewardPeriod;
        uint256 reward = totalEth * apr * periods / 1000000 / rewardPeriodsPerYear;

        return staking.pendingReward + reward;
    }

    /**
    * @notice Returns APR for staker based on staked amount and total ETH on smart contract balance.
    */
    function _getApr(Staking storage staker) private view returns (uint256) {
        if (staker.amount == 0) {
            return 0;
        } else {
            uint256 apr = (staker.amount * 1000000) / totalStaked;
            if (apr > maxApr) {
                return maxApr;
            } else {
                return apr;
            }
        }
    }
}