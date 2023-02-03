// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/IPositionsController.sol';

/// @dev locks the asset of the position owner for a certain time
abstract contract PositionLockerBase {
    mapping(uint256 => uint256) public unlockTimes; // unlock time by position
    mapping(uint256 => bool) _permamentLocks;

    modifier onlyUnlockedPosition(uint256 positionId) {
        require(!_positionLocked(positionId), 'for unlocked positions only');
        _;
    }

    modifier onlyLockedPosition(uint256 positionId) {
        require(_positionLocked(positionId), 'for locked positions only');
        _;
    }

    function positionLocked(uint256 positionId) external view returns (bool) {
        return _positionLocked(positionId);
    }

    function _positionLocked(uint256 positionId)
        internal
        view
        virtual
        returns (bool)
    {
        return
            _isPermanentLock(positionId) ||
            block.timestamp < unlockTimes[positionId];
    }

    function isPermanentLock(uint256 positionId) external view returns (bool) {
        return _isPermanentLock(positionId);
    }

    function _isPermanentLock(uint256 positionId)
        internal
        view
        virtual
        returns (bool)
    {
        return _permamentLocks[positionId];
    }

    function lapsedLockSeconds(uint256 positionId)
        external
        view
        returns (uint256)
    {
        if (!_positionLocked(positionId)) return 0;
        if (unlockTimes[positionId] > block.timestamp)
            return unlockTimes[positionId] - block.timestamp;
        else return 0;
    }
}