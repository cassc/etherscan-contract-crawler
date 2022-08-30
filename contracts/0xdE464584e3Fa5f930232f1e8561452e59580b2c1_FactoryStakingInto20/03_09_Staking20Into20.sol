// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking20Into20 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint16 public constant FEE_DENOMINATOR = 10000;

    uint256 public PRECISION_FACTOR;
    uint256 public REWARD_PER_SECOND;
    IERC20 public STAKE_TOKEN;
    IERC20 public REWARD_TOKEN;

    uint256 public PENALTY_PERIOD;
    uint16 public FEE_PERCENTAGE;

    uint256 public START_TIME;
    uint256 public END_TIME;
    uint256 public totalStaked;
    uint256 public accTokenPerShare;

    address public feeReceiver;

    bool public excessRewardWithdrawn;

    uint256 private lastActionTime;
    uint256 private _excessReward;

    mapping (address => UserInfo) public stakeInfo;

    struct UserInfo {
        uint256 amount;
        uint256 rewardTaken;
        uint256 enteredAt;
    }

    constructor(IERC20 _stakeToken, IERC20Metadata _rewardToken, uint256 _startTime, uint256 _endTime, uint256 _rewardPerSecond, uint256 _penaltyPeriod, uint16 _feePercentage) {
        require(_startTime < _endTime && _startTime >= block.timestamp, "Cannot set these start and end times");
        require(_feePercentage <= FEE_DENOMINATOR, "Cannot set fee higher than 100%");
        STAKE_TOKEN = _stakeToken;
        REWARD_TOKEN = _rewardToken;
        START_TIME = _startTime;
        lastActionTime = _startTime;
        END_TIME = _endTime;
        REWARD_PER_SECOND = _rewardPerSecond;
        PENALTY_PERIOD = _penaltyPeriod;
        FEE_PERCENTAGE = _feePercentage;
        PRECISION_FACTOR = 10 ** (uint256(30) - uint256(_rewardToken.decimals()));
        feeReceiver = msg.sender;
    }

    function generalInfo() external view returns(IERC20, IERC20, uint256, uint256, uint256, uint256, uint16) {
        return (STAKE_TOKEN, REWARD_TOKEN, START_TIME, END_TIME, REWARD_PER_SECOND, PENALTY_PERIOD, FEE_PERCENTAGE);
    }

    function pendingReward(address account) external view returns(uint256) {
        if (totalStaked > 0) {
            UserInfo storage stake = stakeInfo[account];
            uint256 adjustedTokenPerShare =
                accTokenPerShare + (((_getMultiplier(lastActionTime, block.timestamp) * REWARD_PER_SECOND) * PRECISION_FACTOR)) / totalStaked;
            return ((stake.amount * adjustedTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
        }
        else {
            return 0;
        }
    }

    function setFeeReceiver(address _feeReceiver) external {
        require(msg.sender == feeReceiver, "Not a fee receiver");
        require(_feeReceiver != address(0), "Cannot set zero address");
        feeReceiver = _feeReceiver;
    }

    function withdrawExcessReward() external {
        require(msg.sender == feeReceiver, "Not a fee receiver");
        require(block.timestamp >= END_TIME, "Pool not yet ended");
        require(!excessRewardWithdrawn, "Excess reward already withdrawn");
        excessRewardWithdrawn = true;
        REWARD_TOKEN.safeTransfer(feeReceiver, excessReward());
    }

    function deposit(uint256 amount) external nonReentrant {
        require(block.timestamp >= START_TIME && block.timestamp < END_TIME, "Pool not yet started or already ended");
        require(block.timestamp < END_TIME - PENALTY_PERIOD, "Too late to stake");
        require(amount > 0, "Cannot stake zero");
        UserInfo storage stake = stakeInfo[msg.sender];
        _updatePool();
        STAKE_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        uint256 reward = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
        if (reward > 0) {
            REWARD_TOKEN.safeTransfer(msg.sender, reward);
        }
        totalStaked += amount;
        stake.amount += amount;
        stake.rewardTaken = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR);
        stake.enteredAt = block.timestamp;
    }

    function withdraw(uint256 amount) external nonReentrant {
        UserInfo storage stake = stakeInfo[msg.sender];
        require(stake.amount >= amount, "Cannot withdraw this much");
        _updatePool();
        uint256 toTransfer = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
        if (amount > 0) {
            stake.amount -= amount;
            totalStaked -= amount;
            if (stake.enteredAt + PENALTY_PERIOD >= block.timestamp) {
                uint256 fee = (amount * FEE_PERCENTAGE) / FEE_DENOMINATOR;
                STAKE_TOKEN.safeTransfer(feeReceiver, fee);
                amount -= fee;
            }
            STAKE_TOKEN.safeTransfer(msg.sender, amount);
        }
        if (toTransfer > 0) {
            REWARD_TOKEN.safeTransfer(msg.sender, toTransfer);
        }
        stake.rewardTaken = (stake.amount * accTokenPerShare) / PRECISION_FACTOR;
    }

    function excessReward() public view returns(uint256) {
        if (totalStaked == 0) {
            return REWARD_TOKEN.balanceOf(address(this));
        }
        return _excessReward;
    }

    function _updatePool() private {
        if (block.timestamp <= lastActionTime) {
            return;
        }

        if (totalStaked == 0) {
            _excessReward += ((block.timestamp - lastActionTime) * REWARD_PER_SECOND);
            lastActionTime = block.timestamp;
            return;
        }

        uint256 reward = (_getMultiplier(lastActionTime, block.timestamp) * REWARD_PER_SECOND);
        accTokenPerShare += (reward * PRECISION_FACTOR) / totalStaked;
        lastActionTime = block.timestamp;
    }

    function _getMultiplier(uint256 _from, uint256 _to) private view returns(uint256) {
        if (_to <= END_TIME) {
            return _to - _from;
        } else if (_from >= END_TIME) {
            return 0;
        } else {
            return END_TIME - _from;
        }
    }
}