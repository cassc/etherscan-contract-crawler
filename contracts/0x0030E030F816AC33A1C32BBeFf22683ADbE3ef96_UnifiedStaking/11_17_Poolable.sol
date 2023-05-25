// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

/** @title Poolable.
@dev This contract manage configuration of pools
*/
abstract contract Poolable is Ownable {
    struct Pool {
        address collection; // nft collection
        uint256 lockDuration; // locked timespan
        uint256 minDuration; // min deposit timespan
        uint256 endRewardDate; // date to end the rewards
        uint256 rewardAmount; // amount rewarded when lockDuration is reached
    }

    // pools mapping
    uint256 public poolsLength;
    mapping(uint256 => Pool) private _pools;

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
        require(
            isPoolOpened(poolIndex),
            "Poolable: Pool is closed"
        );
        _;
    }

    /**
     * @dev Modifier that checks that the now() - `depositDate` is above or equal to the min lock duration for pool at index `poolIndex`
     */
    modifier whenUnlocked(uint256 poolIndex, uint256 depositDate) {
        require(isUnlocked(poolIndex, depositDate), "Poolable: Not unlocked");
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

    function updatePool(uint256 poolIndex, Pool calldata pool) external onlyOwner {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        Pool storage editedPool = _pools[poolIndex];

        editedPool.lockDuration = pool.lockDuration;
        editedPool.minDuration = pool.minDuration;
        editedPool.endRewardDate = pool.endRewardDate;
        editedPool.rewardAmount = pool.rewardAmount;

        emit PoolUpdated(poolIndex, editedPool);
    }

    function closePool(uint256 poolIndex) external onlyOwner whenPoolOpened(poolIndex) {
        Pool storage editedPool = _pools[poolIndex];
        editedPool.endRewardDate = block.timestamp;

        emit PoolUpdated(poolIndex, editedPool);
    }

    function isUnlocked(uint256 poolIndex, uint256 depositDate) internal view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(depositDate < block.timestamp, "Poolable: Invalid deposit date");
        return block.timestamp - depositDate >= _pools[poolIndex].lockDuration;
    }

    function isUnlockable(uint256 poolIndex, uint256 depositDate) internal view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(depositDate < block.timestamp, "Poolable: Invalid deposit date");
        return block.timestamp - depositDate >= _pools[poolIndex].minDuration;
    }

    function isPoolOpened(uint256 poolIndex) public view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex].endRewardDate == 0 || _pools[poolIndex].endRewardDate > block.timestamp;
    }

    function collectionForPool(uint256 poolIndex) public view returns (address) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex].collection;
    }
}