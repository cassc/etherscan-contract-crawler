// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ILocker.sol";

interface IVLMGP is ILocker {
    
    struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amountInCoolDown; // total amount comitted to the unlock slot, never changes except when reseting slot
    }    

    function MGP() external view returns(IERC20);
    function getUserUnlockingSchedule(address _user) external view returns (UserUnlocking[] memory slots);
    function getUserAmountInCoolDown(address _user) external view returns (uint256);
    function totalLocked() external view returns (uint256);
    function getFullyUnlock(address _user) external view returns(uint256 unlockedAmount);
    function getRewardablePercentWAD(address _user) external view returns(uint256 percent);
    function totalAmountInCoolDown() external view returns (uint256);
    function getUserNthUnlockSlot(address _user, uint256 n) external view returns (
        uint256 startTime,
        uint256 endTime,
        uint256 amountInCoolDown
    );

    function getUserUnlockSlotLength(address _user) external view returns (uint256);
    function getNextAvailableUnlockSlot(address _user) external view returns (uint256);
    function getUserTotalLocked(address _user) external view returns (uint256);
    function lock(uint256 _amount) external;
    function startUnlock(uint256 _amountToCoolDown) external;
    function cancelUnlock(uint256 _slotIndex) external;
    function unlock(uint256 slotIndex) external;
}