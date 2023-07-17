// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Poolable.
@dev This contract manage configuration of pools
*/
abstract contract Poolable is Ownable {
    struct Pool {
        uint256 lockDuration; // locked timespan
        uint256 minDuration; // min deposit timespan
        bool opened; // flag indicating if the pool is open
        uint256 rewardAmount; // amount rewarded when lockDuration is reached
    }

    // pools mapping
    mapping(uint256 => Pool) private _pools;
    uint256 public poolsLength;

    /**
     * @dev Emitted when a pool is created
     */
    event PoolAdded(uint256 poolIndex, Pool pool);

    /**
     * @dev Emitted when a pool is updated
     */
    event PoolUpdated(uint256 poolIndex, Pool pool);

    /**
     * @dev Modifier that checks that the pool at index `poolIndex` is open
     */
    modifier whenPoolOpened(uint256 poolIndex) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(_pools[poolIndex].opened, "Poolable: Pool is closed");
        _;
    }

    /**
     * @dev Modifier that checks that the now() - `depositDate` is above or equal to the min lock duration for pool at index `poolIndex`
     */
    modifier whenUnlocked(uint256 poolIndex, uint256 depositDate) {
        require(
            isUnlocked(poolIndex, depositDate),
            "Poolable: Not unlocked"
        );
        _;
    }

    function getPool(uint256 poolIndex) public view returns (Pool memory) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex];
    }

    function addPool(Pool calldata pool) external onlyOwner {
        uint256 poolIndex = poolsLength;

        _pools[poolIndex] = pool;
        poolsLength = poolsLength + 1;

        emit PoolAdded(poolIndex, _pools[poolIndex]);
    }

    function updatePool(uint256 poolIndex, Pool calldata pool)
        external
        onlyOwner
    {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        Pool storage editedPool = _pools[poolIndex];

        editedPool.lockDuration = pool.lockDuration;
        editedPool.minDuration = pool.minDuration;
        editedPool.opened = pool.opened;
        editedPool.rewardAmount = pool.rewardAmount;

        emit PoolUpdated(poolIndex, editedPool);
    }

    function isUnlocked(uint256 poolIndex, uint256 depositDate) internal view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(
            depositDate < block.timestamp,
            "Poolable: Invalid deposit date"
        );
        return block.timestamp - depositDate >= _pools[poolIndex].lockDuration;
    }

    function isUnlockable(uint256 poolIndex, uint256 depositDate) internal view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(
            depositDate < block.timestamp,
            "Poolable: Invalid deposit date"
        );
        return block.timestamp - depositDate >= _pools[poolIndex].minDuration;
    }

    function isPoolOpened(uint256 poolIndex) public view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex].opened;
    }
}