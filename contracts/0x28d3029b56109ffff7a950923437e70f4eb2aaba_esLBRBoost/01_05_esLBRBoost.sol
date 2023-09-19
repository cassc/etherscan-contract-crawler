// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IesLBR.sol";
import "../interfaces/IMiningIncentives.sol";


contract esLBRBoost is Ownable {
    esLBRLockSetting[] public esLBRLockSettings;
    mapping(address => LockStatus) public userLockStatus;
    IMiningIncentives public miningIncentives;

    // Define a struct for the lock settings
    struct esLBRLockSetting {
        uint256 duration;
        uint256 miningBoost;
    }

    // Define a struct for the user's lock status
    struct LockStatus {
        uint256 lockAmount;
        uint256 unlockTime;
        uint256 duration;
        uint256 miningBoost;
    }

    event StakeLBR(address indexed user, uint256 amount, uint256 time);
    event NewLockSetting(uint256 duration, uint256 miningBoost);
    event UserLockStatus(address indexed user, uint256 lockAmount, uint256 unlockTime, uint256 duration, uint256 miningBoost);
    event Unlock(address indexed user, uint256 unLockAmount, uint256 unlockTime);

    // Constructor to initialize the default lock settings
    constructor(address _miningIncentives) {
        esLBRLockSettings.push(esLBRLockSetting(30 days, 5 * 1e18));
        esLBRLockSettings.push(esLBRLockSetting(90 days, 10 * 1e18));
        esLBRLockSettings.push(esLBRLockSetting(180 days, 25 * 1e18));
        esLBRLockSettings.push(esLBRLockSetting(365 days, 50 * 1e18));
        miningIncentives = IMiningIncentives(_miningIncentives);
    }

    // Function to add a new lock setting
    function addLockSetting(esLBRLockSetting memory setting) external onlyOwner {
        esLBRLockSettings.push(setting);
        emit NewLockSetting(setting.duration, setting.miningBoost);
    }

    /**
     * @notice The user can set the lock status and choose to use either esLBR or LBR.
     * @param id The ID of the lock setting.
     * @param lbrAmount The amount of LBR to be locked.
     * @param useLBR A flag indicating whether to use LBR or not.
     */
    function setLockStatus(uint256 id, uint256 lbrAmount, bool useLBR) external {
        require(id < esLBRLockSettings.length, "Invalid lock setting ID");
        esLBRLockSetting memory _setting = esLBRLockSettings[id];
        LockStatus memory userStatus = userLockStatus[msg.sender];
        if (userStatus.unlockTime > block.timestamp) {
            require(userStatus.duration <= _setting.duration, "Your lock-in period has not ended, and the term can only be extended, not reduced.");
        }
        if(useLBR) {
            IesLBR(miningIncentives.LBR()).burn(msg.sender, lbrAmount);
            IesLBR(miningIncentives.esLBR()).mint(msg.sender, lbrAmount);
            emit StakeLBR(msg.sender, lbrAmount, block.timestamp);
        }
        require(IesLBR(miningIncentives.esLBR()).balanceOf(msg.sender) >= userStatus.lockAmount + lbrAmount, "IB");
        miningIncentives.refreshReward(msg.sender);
        userLockStatus[msg.sender] = LockStatus(userStatus.lockAmount + lbrAmount, block.timestamp + _setting.duration, _setting.duration, _setting.miningBoost);
        emit UserLockStatus(msg.sender, userLockStatus[msg.sender].lockAmount, userLockStatus[msg.sender].duration, _setting.duration, _setting.miningBoost);
    }

    function unlock() external {
        LockStatus storage userStatus = userLockStatus[msg.sender];
        require(userStatus.unlockTime < block.timestamp, "TNM");
        emit Unlock(msg.sender, userStatus.lockAmount, block.timestamp);
        userStatus.lockAmount = 0;
    }

    // Function to get the user's unlock time
    function getUnlockTime(address user) external view returns (uint256 unlockTime) {
        unlockTime = userLockStatus[user].unlockTime;
    }

    /**
     * @notice calculate the user's mining boost based on their lock status
     * @dev Based on the user's userUpdatedAt time, finishAt time, and the current time,
     * there are several scenarios that could occur, including no acceleration, full acceleration, and partial acceleration.
     */
    function getUserBoost(address user, uint256 userUpdatedAt, uint256 finishAt) external view returns (uint256) {
        LockStatus memory userStatus = userLockStatus[user];
        uint256 boostEndTime = userStatus.unlockTime;
        if (userUpdatedAt >= boostEndTime || userUpdatedAt >= finishAt || userStatus.lockAmount == 0) {
            return 0;
        }
        uint needLockedAmount = getAmountNeedLocked(user);
        if(needLockedAmount == 0) return 0;
        uint256 maxBoost = userLockStatus[user].miningBoost;

        if (finishAt > boostEndTime && block.timestamp > boostEndTime) {
            uint256 time = block.timestamp > finishAt ? finishAt : block.timestamp;
            maxBoost = ((boostEndTime - userUpdatedAt) * maxBoost) / (time - userUpdatedAt);
        }
        if (userStatus.lockAmount >= needLockedAmount) {
            return maxBoost;
        }
        return maxBoost * userStatus.lockAmount / needLockedAmount;
    }

    function getAmountNeedLocked(address user) public view returns (uint256) {
        uint256 stakedAmount = miningIncentives.stakedOf(user);
        uint256 totalStaked = miningIncentives.totalStaked();
        if(stakedAmount == 0 || totalStaked == 0) return 0;
        return stakedAmount * (IesLBR(miningIncentives.LBR()).totalSupply() + IesLBR(miningIncentives.esLBR()).totalSupply()) / totalStaked;
    }
}