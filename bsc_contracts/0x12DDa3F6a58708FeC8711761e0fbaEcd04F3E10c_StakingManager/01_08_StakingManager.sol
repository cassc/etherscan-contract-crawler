//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingManager is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lunar;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    LevelInfo[] public levelInfo;

    bool public isStakingEnabled = false;

    struct UserInfo {
        uint256 amount; //amount of lunar the user has provided
        uint256 withdrawAmount;
        uint256 rewardDebt;
        uint256 initialTime;
        uint256 lockEndTime; // lock end time.
    }

    struct LevelInfo {
        uint256 stakingDuration;
        uint256 reward;
        uint256 minTxAmount;
        uint256 maxTxAmount;
        uint256 totalStaked;
        bool flexible;
    }

    constructor(IERC20 _lunar) {
        lunar = _lunar;

        _setDefaultLevels(30 days, 200, 760000000000000000000000, 0, false); // if 0 for min/max Tx amount, no limit
        _setDefaultLevels(15 days, 100, 760000000000000000000000, 0, false); // if 0 for min/max Tx amount, no limit
        _setDefaultLevels(15 days, 20, 760000000000000000000000, 0, true); // if 0 for min/max Tx amount, no limit
    }

    function _setDefaultLevels(
        uint256 stakingDuration,
        uint256 reward,
        uint256 minTxAmount,
        uint256 maxTxAmount,
        bool flexible
    ) internal {
        levelInfo.push(
            LevelInfo({
                stakingDuration: stakingDuration,
                reward: reward,
                minTxAmount: minTxAmount,
                maxTxAmount: maxTxAmount,
                totalStaked: 0,
                flexible: flexible
            })
        );
    }

    /// @notice Update the given level's data. Can only be called by owner.
    /// @param _lid The id of the level. See `levelInfo`.
    /// @param _minTxAmount Whether call "massUpdatePools" operation.
    /// @param _maxTxAmount Whether call "massUpdatePools" operation.
    function set(
        uint256 _lid,
        uint256 _minTxAmount,
        uint256 _maxTxAmount
    ) external onlyOwner {
        levelInfo[_lid].minTxAmount = _minTxAmount;
        levelInfo[_lid].maxTxAmount = _maxTxAmount;
    }

    function safeLunarTransfer(address _to, uint256 _amount) internal {
        uint256 lunarBal = lunar.balanceOf(address(this));
        if (_amount > lunarBal) {
            lunar.transfer(_to, lunarBal);
        } else {
            lunar.transfer(_to, _amount);
        }
    }

    function updateUserStake(address _address, uint256 _lid) internal {
        UserInfo memory user = userInfo[_lid][_address];
        uint256 rewardAmount = getRewards(_address, _lid);
        user.rewardDebt = rewardAmount;
        user.initialTime = block.timestamp;
        user.lockEndTime = user.initialTime + levelInfo[_lid].stakingDuration;
        userInfo[_lid][_address] = user;
    }

    function stake(uint256 _amount, uint256 _lid) external nonReentrant {
        require(isStakingEnabled, "Staking is not allowed");

        UserInfo memory user = userInfo[_lid][msg.sender];
        LevelInfo memory level = levelInfo[_lid];

        require(
            level.minTxAmount <= _amount,
            "amount is less than minTxAmount"
        );

        if (level.maxTxAmount > 0) {
            require(
                level.maxTxAmount >= _amount,
                "amount is greater than maxTxAmount"
            );
        }

        lunar.transferFrom(msg.sender, address(this), _amount);

        updateUserStake(msg.sender, _lid);

        user.amount = user.amount.add(_amount);
        user.initialTime = block.timestamp;
        user.lockEndTime = block.timestamp + level.stakingDuration;
        userInfo[_lid][msg.sender] = user;
        levelInfo[_lid].totalStaked = levelInfo[_lid].totalStaked.add(_amount);
    }

    function harvest(uint256 _lid) external nonReentrant {
        uint256 rewardAmount = getRewards(msg.sender, _lid);
        require(rewardAmount > 0, "harvest: not enough funds");

        updateUserStake(msg.sender, _lid);

        userInfo[_lid][msg.sender].rewardDebt = 0;
        safeLunarTransfer(msg.sender, rewardAmount);
    }

    function withdraw(uint256 _lid) external nonReentrant {
        UserInfo storage user = userInfo[_lid][msg.sender];
        LevelInfo memory level = levelInfo[_lid];
        require(user.amount > 0, "withdraw: insufficient amount");
        if (!level.flexible) {
            require(
                block.timestamp >= user.lockEndTime,
                "staking period has not ended"
            );
        }
        uint256 _amount = user.amount;
        updateUserStake(msg.sender, _lid);

        levelInfo[_lid].totalStaked = levelInfo[_lid].totalStaked.sub(_amount);
        user.amount = 0;

        user.withdrawAmount += _amount;

        uint256 rewardAmount = getRewards(msg.sender, _lid);
        user.rewardDebt = 0;

        userInfo[_lid][msg.sender] = user;

        uint256 withdrawalAmount = rewardAmount.add(_amount);

        safeLunarTransfer(msg.sender, withdrawalAmount);
    }

    function getRewards(address account, uint256 _lid)
        public
        view
        returns (uint256)
    {
        uint256 pendingReward = 0;
        UserInfo memory user = userInfo[_lid][account];
        if (user.amount > 0) {
            LevelInfo memory level = levelInfo[_lid];
            uint256 stakeAmount = user.amount;
            uint256 timeDiff;
            unchecked {
                timeDiff = block.timestamp - user.initialTime;
            }
            if (timeDiff >= level.stakingDuration) {
                return stakeAmount.mul(level.reward).div(100);
            }
            uint256 rewardAmount = (((stakeAmount * level.reward) / 100) *
                timeDiff) / level.stakingDuration;
            pendingReward = rewardAmount;
        }

        uint256 pending = user.rewardDebt.add(pendingReward);
        return pending;
    }

    function getUserDetails(address account, uint256 _lid)
        external
        view
        returns (UserInfo memory, uint256)
    {
        uint256 reward = getRewards(account, _lid);
        UserInfo memory user = userInfo[_lid][account];
        return (user, reward);
    }

    function emergencyWithdraw(uint256 _lid) external nonReentrant returns (uint256) {
        UserInfo memory user = userInfo[_lid][msg.sender];
        require(user.amount > 0, "Nothing to withdraw");

        uint256 stakedAmount = user.amount;

        levelInfo[_lid].totalStaked = levelInfo[_lid].totalStaked.sub(
            user.amount
        );

        user.amount = 0;
        userInfo[_lid][msg.sender] = user;

        safeLunarTransfer(msg.sender, stakedAmount);
        return stakedAmount;
    }

    function disableStaking() external onlyOwner returns (bool) {
        isStakingEnabled = false;
        return true;
    }

    function enableStaking() external onlyOwner returns (bool) {
        isStakingEnabled = true;
        return true;
    }
}