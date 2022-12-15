// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
//import "./rewardToken.sol";

contract FarmXYZBase is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public rewardBalance;

    string public name = "FarmXYZBase";

    uint256 public totalValueLocked = 0;

    uint256 public mandatoryLockTime;
    IERC20 public stakeToken;
    IERC20 public rewardToken;
    uint16 public apy;
    uint256 private ratePerSecond;

    event DepositToRewardsPool(address indexed from, uint256 amount);
    event WithdrawFromRewardsPool(address indexed to, uint256 amount);

    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);
    event YieldWithdraw(address indexed to, uint256 amount);

    /**
     * @param _stakeToken - The token users can stake
     * @param _rewardToken - The token users get as a reward
     * @param _apy - The APY users get for staking percent values 0 and above
    */
    constructor(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint16 _apy
    ) {
        require(_apy > 0, "Can't have 0 APY pool");
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        updateApy(_apy);
    }

    function calculateRatePerSecond() internal view returns (uint256) {
        return uint256(apy) * 10 ** 18 / 100 / (365 days);
    }

    function updateApy(uint16 _apy) public onlyOwner {
        apy = _apy;
        ratePerSecond = calculateRatePerSecond();
    }

    function rewardsPerDay() public view returns (uint256) {
        return totalValueLocked * ratePerSecond * 24 * 3600;
    }

    function totalRewardPool() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function depositToRewardPool(uint256 amount) public {
        require(rewardToken.balanceOf(msg.sender) >= amount, "You don't own enough tokens");
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        emit DepositToRewardsPool(msg.sender, amount);
    }

    function emergencyWithdrawFromRewardPool(uint256 amount) public onlyOwner {
        require(rewardToken.balanceOf(address(this)) >= amount, "There aren't enough tokens in the pool");
        rewardToken.safeTransferFrom(address(this), msg.sender, amount);
        emit WithdrawFromRewardsPool(msg.sender, amount);
    }

    function stake(uint256 amount) public {
        require(amount > 0, "You cannot stake zero tokens");
        require(stakeToken.balanceOf(msg.sender) >= amount, "You don't own enough tokens");

        if (isStaking[msg.sender] == true) {
            console.log("Sender is already staking, calculating current balance and saving state");
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            console.log("Current pending balance", toTransfer);
            rewardBalance[msg.sender] += toTransfer;
        }

        stakeToken.transferFrom(msg.sender, address(this), amount);
        stakingBalance[msg.sender] += amount;
        totalValueLocked += amount;
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(isStaking[msg.sender] == true, "Nothing to unstake");
        require(stakingBalance[msg.sender] >= amount, "Balance is lower than amount");

        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        startTime[msg.sender] = block.timestamp;
        uint256 balTransfer = amount;
        amount = 0;
        stakingBalance[msg.sender] -= balTransfer;
        totalValueLocked -= balTransfer;
        stakeToken.transfer(msg.sender, balTransfer);
        rewardBalance[msg.sender] += yieldTransfer;
        if (stakingBalance[msg.sender] == 0) {
            console.log("Sender removed all tokens, setting isStaking to false");
            isStaking[msg.sender] = false;
            // TODO Transfer all yield to user???
        }
        emit Unstake(msg.sender, balTransfer);
    }

    /**
     * Returns the number of seconds since the user staked his tokens
     */
    function calculateYieldTime(address user) public view returns (uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        console.log("[calculateYieldTime] Start: %s. End: %s. Diff: %s", startTime[user], end, totalTime);
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns (uint256) {
        uint256 time = calculateYieldTime(user);
        console.log("calc yield for %s", user);
        console.log("time %s balance %s ratePerSecond %s", time, stakingBalance[user], ratePerSecond);
        uint256 rawYield = (stakingBalance[user] * time * ratePerSecond) / 10 ** 18;
        console.log('[calculateYieldTotal] RawYield: %s', rawYield);

        return rawYield;
    }

    function withdrawYield(bool compound) public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        console.log('[withdrawYield-before] ToTransfer: %s. Rewards: %s. Staked: %s', toTransfer, rewardBalance[msg.sender], stakingBalance[msg.sender]);
        require(
            toTransfer > 0 ||
            rewardBalance[msg.sender] > 0,
            "Nothing to withdraw"
        );

        if (rewardBalance[msg.sender] != 0) {
            uint256 oldBalance = rewardBalance[msg.sender];
            rewardBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }

        startTime[msg.sender] = block.timestamp;

        if (compound == true) {
            console.log('[withdrawYield-compound] StakingBalance: %s. To: %s. Amount: %s', stakingBalance[msg.sender], msg.sender, toTransfer);
            stakingBalance[msg.sender] += toTransfer;
        } else {
            console.log('[withdrawYield-transfer] From: %s. To: %s. Amount: %s', address(this), msg.sender, toTransfer);
            rewardToken.transfer(msg.sender, toTransfer);
        }
        console.log('[withdrawYield-after] ToTransfer: %s. Rewards: %s. Staked: %s', toTransfer, rewardBalance[msg.sender], stakingBalance[msg.sender]);

        emit YieldWithdraw(msg.sender, toTransfer);
    }

}