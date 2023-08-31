// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IKarrotChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function claim(uint256 _pid) external;
    function attack() external;
    function getUserStakedAmount(address _user) external view returns (uint256);
    function getTotalStakedAmount() external view returns (uint256);
    function setAllocationPoint(uint256 _pid, uint128 _allocPoint, bool _withUpdatePools) external;
    function setLockDuration(uint256 _pid, uint256 _lockDuration) external;
    function updateRewardPerBlock(uint88 _rewardPerBlock) external;
    function setDebaseMultiplier(uint48 _debaseMultiplier) external;
    function openKarrotChefDeposits() external;
    function setDepositIsPaused(bool _isPaused) external;
    function setThresholdFullProtecKarrotBalance(uint256 _thresholdFullProtecKarrotBalance) external;
    function setClaimTaxRate(uint16 _maxTaxRate) external;
    function setFullProtecLiquidityProportion(uint16 _fullProtecLiquidityProportion) external;
    function getFullToChefRatio(address _user) external view returns (uint256);
}