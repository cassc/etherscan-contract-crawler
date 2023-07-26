// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


interface IVLPenpieReader {
     struct UserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amountInCoolDown; // total amount comitted to the unlock slot, never changes except when reseting slot
     }    
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
    function expectedPenaltyAmount(uint256 _slotIndex) external view returns(uint256 penaltyAmount, uint256 amountToUser) ;
    function expectedPenaltyAmountByAccount(address account, uint256 _slotIndex) external view returns(uint256 penaltyAmount, uint256 amountToUser) ;
    function totalPenalty() external view returns (uint256);

}