// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMRewardProvider {

    event Stake(address indexed sender, uint amount, address indexed to);
    event Withdraw(address indexed sender, uint amount, uint rewardAmount, address indexed to);

    event AddRewards(address indexed sender, uint32 startHour, uint32 endHour, uint amountPerHours);
    event ArrangeFailedRewards(address indexed sender, uint32 startHour, uint32 endHour, uint amountPerHours);
    event AllPosition(address indexed owner, uint amount, uint extraAmount, uint32 startHour, uint32 endLocking, uint indexed idx);
    event SyncStatistics(address indexed sender, uint amountIn, uint amountOut, uint aggregatedRewards, uint32 hour);
    event UpdateRewardFactor(address indexed sender, uint oldFactor, uint newFactor);

    function getRewardFactor(uint16 _days) external view returns (uint factor);
    function updateRewardFactor(uint16 lockedDays, uint factor) external returns (bool);

    function allPosition(address investor, uint idx) external view returns(uint amount, uint extraAmount, uint32 startHour, uint32 endLocking);
    function allPositionLength(address investor) external view returns (uint);
    function calcRewards(address investor, uint idx) external returns (uint rewardAmount, bool isLocked);
    
    function getTreasuryFields() external view returns (uint32 syncHour, uint totalAmount, uint pendingRewards, uint32 initialHour, uint16 lastSession);
    function getDailyStatistics(uint32 hourFromEpoch) external view returns (uint amountIn, uint amountOut, uint aggregatedRewards, uint32 next);
    function syncStatistics() external;
    function hoursToSession(uint32 hourFromEpoch) external view returns (uint16 session);
    function getPeriods(uint16 session) external view returns (uint amountPerHours, uint32 startHour, uint32 endHour);

    function decimals() external pure returns (uint8);
}