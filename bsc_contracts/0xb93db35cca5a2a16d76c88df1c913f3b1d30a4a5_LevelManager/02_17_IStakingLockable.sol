// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./IStaking.sol";

interface IStakingLockable is IStaking {
    function setLockPeriod(uint256 _lockPeriod) external;

    function setLevelManager(address _address) external;

    function getLockPeriod() external view returns (uint256);

    function lock(address account, uint256 saleStart) external;

    function getUnlocksAt(address account) external view returns (uint256);

    function isLocked(address account) external view returns (bool);

    function getLockedAmount(address account) external view returns (uint256);
}