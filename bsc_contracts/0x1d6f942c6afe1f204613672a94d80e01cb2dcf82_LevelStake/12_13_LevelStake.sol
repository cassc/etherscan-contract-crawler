// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ILevelStake} from "../interfaces/ILevelStake.sol";

/**
 * @title LevelStake
 * @notice Contract to stake LVL token and earn LGO reward.
 * @author Level
 */
contract LevelStake is Initializable, OwnableUpgradeable, ILevelStake {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 cooldowns;
    }

    uint256 private constant ACC_REWARD_PRECISION = 1e12;
    uint256 private constant MAX_REWARD_PER_SECOND = 1 ether;

    //== UNUSED: keep for frontend
    uint256 public constant COOLDOWN_SECONDS = 0;
    uint256 public constant UNSTAKE_WINDOWN = 0;
    //===============================

    IERC20 public LVL;
    IERC20 public LGO;

    uint256 public rewardPerSecond;
    uint256 public accRewardPerShare;
    uint256 public lastRewardTime;

    mapping(address => UserInfo) public userInfo;

    /**
     * @dev Called by the proxy contract
     *
     */
    function initialize(address _lvl, address _lgo, uint256 _rewardPerSecond) external initializer {
        __Ownable_init();
        require(_rewardPerSecond <= MAX_REWARD_PER_SECOND, "> MAX_REWARD_PER_SECOND");
        require(_lvl != address(0), "Invalid LVL address");
        require(_lgo != address(0), "Invalid LVL address");
        LVL = IERC20(_lvl);
        LGO = IERC20(_lgo);
        rewardPerSecond = _rewardPerSecond;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @dev Return the total rewards pending to claim by an staker
     * @param _to The user address
     * @return The rewards
     */
    function pendingReward(address _to) external view returns (uint256) {
        UserInfo storage user = userInfo[_to];
        uint256 lvlSupply = LVL.balanceOf(address(this));
        uint256 _accRewardPerShare = accRewardPerShare;
        if (block.timestamp > lastRewardTime && lvlSupply != 0) {
            uint256 time = block.timestamp - lastRewardTime;
            uint256 reward = time * rewardPerSecond;
            _accRewardPerShare += ((reward * ACC_REWARD_PRECISION) / lvlSupply);
        }
        return ((user.amount * _accRewardPerShare) / ACC_REWARD_PRECISION) - user.rewardDebt;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @dev Staked LVL tokens, and start earning rewards
     * @param _to Address to stake to
     * @param _amount Amount to stake
     */
    function stake(address _to, uint256 _amount) external override {
        require(_amount != 0, "INVALID_AMOUNT");
        UserInfo storage user = userInfo[_to];
        update();

        if (user.amount != 0) {
            uint256 pending = (user.amount * accRewardPerShare) / ACC_REWARD_PRECISION - user.rewardDebt;
            if (pending != 0) {
                _safeTransferLGO(_to, pending);
                emit RewardsClaimed(msg.sender, _to, pending);
            }
        }

        user.amount += _amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / ACC_REWARD_PRECISION;

        LVL.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _to, _amount);
    }

    /**
     * @dev Unstake tokens, and stop earning rewards
     * @param _to Address to unstake to
     * @param _amount Amount to unstake
     */
    function unstake(address _to, uint256 _amount) external override {
        update();
        require(_amount != 0, "INVALID_AMOUNT");
        UserInfo storage user = userInfo[msg.sender];

        uint256 amountToUnstake = (_amount > user.amount) ? user.amount : _amount;
        uint256 pending = ((user.amount * accRewardPerShare) / ACC_REWARD_PRECISION) - user.rewardDebt;

        user.amount -= amountToUnstake;
        user.rewardDebt = (user.amount * accRewardPerShare) / ACC_REWARD_PRECISION;

        if (pending != 0) {
            _safeTransferLGO(_to, pending);
            emit RewardsClaimed(msg.sender, _to, pending);
        }

        IERC20(LVL).safeTransfer(_to, amountToUnstake);

        emit Unstaked(msg.sender, _to, amountToUnstake);
    }

    /**
     * @dev Activates the cooldown period to unstake
     * - It can't be called if the user is not staking
     */
    function cooldown() external override {
        // doing nothing
    }

    /**
     * @dev Deactivates the cooldown period
     * - It can't be called if the user not on cooldown time
     */
    function deactivateCooldown() external override {
        // doing nothing
    }

    /**
     * @dev Claims LGO rewards to the address `to`
     * @param _to Address to stake for
     */
    function claimRewards(address _to) external {
        update();
        UserInfo storage user = userInfo[msg.sender];

        uint256 accumulatedReward = uint256((user.amount * accRewardPerShare) / ACC_REWARD_PRECISION);
        uint256 _pendingReward = uint256(accumulatedReward - user.rewardDebt);

        user.rewardDebt = accumulatedReward;

        if (_pendingReward != 0) {
            _safeTransferLGO(_to, _pendingReward);
            emit RewardsClaimed(msg.sender, _to, _pendingReward);
        }
    }

    /* ========== RESTRICTIVE FUNCTIONS ========== */

    /// @notice Sets the reward per second to be distributed. Can only be called by the owner.
    /// @param _rewardPerSecond The amount of LGO to be distributed per second.
    function setRewardPerSecond(uint256 _rewardPerSecond) public onlyOwner {
        require(_rewardPerSecond <= MAX_REWARD_PER_SECOND, "> MAX_REWARD_PER_SECOND");
        update();
        rewardPerSecond = _rewardPerSecond;
        emit RewardPerSecondUpdated(_rewardPerSecond);
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    function update() internal {
        if (block.timestamp > lastRewardTime) {
            uint256 lvlSupply = LVL.balanceOf(address(this));
            if (lvlSupply != 0) {
                uint256 time = block.timestamp - lastRewardTime;
                uint256 reward = time * rewardPerSecond;
                accRewardPerShare = accRewardPerShare + ((reward * ACC_REWARD_PRECISION) / lvlSupply);
            }
            lastRewardTime = block.timestamp;
        }
    }

    // Safe LGO transfer function, just in case if rounding error causes pool to not have enough LGOs.
    function _safeTransferLGO(address _to, uint256 _amount) internal {
        require(LGO != IERC20(address(0)), "LGO not set");
        uint256 lgoBalance = LGO.balanceOf(address(this));
        if (_amount > lgoBalance) {
            LGO.safeTransfer(_to, lgoBalance);
        } else {
            LGO.safeTransfer(_to, _amount);
        }
    }

    /* ========== EVENT ========== */

    event CooldownDeactivated(address indexed user);
    event Staked(address indexed from, address indexed to, uint256 amount);
    event Unstaked(address indexed from, address indexed to, uint256 amount);
    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed from, address indexed to, uint256 amount);
    event Cooldown(address indexed user);
    event RewardPerSecondUpdated(uint256 rewardPerSecond);
}