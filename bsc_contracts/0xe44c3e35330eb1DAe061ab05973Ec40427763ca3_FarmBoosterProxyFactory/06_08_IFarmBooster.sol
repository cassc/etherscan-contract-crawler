// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFarmBooster {
    function onWayaVaultUpdate(
        address _user,
        uint256 _lockedAmount,
        uint256 _lockedDuration,
        uint256 _totalLockedAmount,
        uint256 _maxLockDuration
    ) external;

    function updatePoolBoostMultiplier(address _user, uint256 _pid) external;

    function setProxy(address _user, address _proxy) external;

    function isBoosterPool(address _user, uint256 _pid) external view returns (bool);

    function linkedParams() external view returns (address, address);
}