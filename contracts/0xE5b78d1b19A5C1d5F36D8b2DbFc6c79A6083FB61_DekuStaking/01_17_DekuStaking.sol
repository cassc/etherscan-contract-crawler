// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DekuStakedToken} from "./DekuStakedToken.sol";

import "hardhat/console.sol";

contract DekuStaking is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    address[] public stakeholderList;
    mapping(address => Stakeholder) public stakeholderData;

    uint256 private constant BPS = 10000;
    uint256 public minStake = 10000e18;
    uint256 public maxStake = 250000e18;
    uint256 public maxTotalStake = 7200000e18;
    uint256 public totalStaked;
    uint256 public stakingPeriod;
    uint256 public stakedPeriod;
    uint256 public rewards;

    string public version = "TEST_v1";

    struct Stakeholder {
        bool staked;
        uint256 stakedAmount;
        uint256 rewardAmount;
        bool claimed;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsDeposited(uint256 rewards);
    event RewardAllocated(address user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _maxTotalStake
    ) {
        if (_maxTotalStake > 0) maxTotalStake = _maxTotalStake;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 _amount) external nonReentrant {
        if ((totalStaked + _amount) > maxTotalStake)
            revert MaximumTotalStakeReached({
                totalMaxStake: maxTotalStake,
                currentStakedAmount: totalStaked,
                remainingStakeableAmount: (maxTotalStake - totalStaked),
                stakerAmount: _amount
            });
        if (_amount < minStake)
            revert InvalidMinimumStake({minimumStakeAmount: minStake});
        if (_amount > maxStake)
            revert InvalidMaximumStake({maximumStakeAmount: maxStake});
        if (_amount > maxStake - stakeholderData[msg.sender].stakedAmount)
            revert StakeWouldBeGreaterThanMax();
        if (stakingToken.balanceOf(msg.sender) < _amount)
            revert InsufficientBalance();
        totalStaked = totalStaked + _amount;
        stakeholderData[msg.sender].stakedAmount =
            stakeholderData[msg.sender].stakedAmount +
            _amount;
        if (!stakeholderData[msg.sender].staked) {
            stakeholderList.push(msg.sender);
        }
        stakeholderData[msg.sender].staked = true;
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function unstake() external nonReentrant {
        uint256 rewardAmount;
        if (stakeholderData[msg.sender].claimed)
            revert UserAlreadyClaimedRewards(msg.sender);
        if (stakeholderData[msg.sender].rewardAmount == 0) {
            eligibleRewardAmount(msg.sender);
            rewardAmount = getRewardAmountForAccount(msg.sender);
        } else {
            rewardAmount = stakeholderData[msg.sender].rewardAmount;
        }
        uint256 stakedBalance = stakeholderData[msg.sender].stakedAmount;
        stakeholderData[msg.sender].stakedAmount = 0;
        stakeholderData[msg.sender].staked = false;
        stakingToken.safeTransfer(msg.sender, stakedBalance);
        stakeholderData[msg.sender].claimed = true;
        stakeholderData[msg.sender].rewardAmount = 0;
        rewardToken.safeTransfer(msg.sender, rewardAmount);
        emit Unstaked(msg.sender, stakedBalance);
        emit RewardPaid(msg.sender, rewardAmount);
    }

    function eligibleRewardAmount(address _staker) public {
        if (_staker == address(0)) revert ZeroAddress();
        if (stakeholderData[msg.sender].rewardAmount != 0)
            revert RewardsAlreadyCalculated();
        uint256 stakeAmount = getStakedAmountForAccount(_staker);
        uint256 stakedPercentage = ((stakeAmount * BPS) / totalStaked);
        uint256 reward = ((stakedPercentage * rewards) / BPS);
        console.log("reward:", reward);
        stakeholderData[msg.sender].rewardAmount = reward;
    }

    /* ========== VIEWS ========== */

    function getStakedAccounts() public view returns (address[] memory) {
        return stakeholderList;
    }

    function getStakedAmountForAccount(address account)
        public
        view
        returns (uint256 amount)
    {
        return stakeholderData[account].stakedAmount;
    }

    function getRewardAmountForAccount(address account)
        public
        view
        returns (uint256 amount)
    {
        return stakeholderData[account].rewardAmount;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function depositRewards(uint256 _amount) external onlyOwner {
        if (_amount == 0) revert RewardsCannotBeZero();
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        rewards += _amount;
        emit RewardsDeposited(_amount);
    }

    /* ====== Fallback functions ======== */
    receive() external payable {}

    /* ========== ERRORS ========== */

    error ZeroAddress();
    error InvalidRewardToken();
    error InvalidStakingToken();
    error InvalidMinimumStake(uint256 minimumStakeAmount);
    error InvalidMaximumStake(uint256 maximumStakeAmount);
    error InsufficientBalance();
    error MaximumTotalStakeReached(
        uint256 totalMaxStake,
        uint256 currentStakedAmount,
        uint256 remainingStakeableAmount,
        uint256 stakerAmount
    );
    error StakeWouldBeGreaterThanMax();
    error ProposedMaxStakeTooLow(uint256 currentMin, uint256 proposedMax);
    error ProposedMinStakeTooHigh(uint256 currentMax, uint256 proposedMin);
    error OnlyWhenInitialized();
    error OnlyWhenStakeable();
    error OnlyWhenStaked();
    error OnlyWhenReadyForUnstake();
    error RewardsNotTransferred();
    error StakingPeriodPassed();
    error StakingDurationTooShort();
    error StakedDurationTooShort();
    error RewardsCannotBeZero();
    error RewardsAlreadyCalculated();
    error UserAlreadyClaimedRewards(address _address);
}