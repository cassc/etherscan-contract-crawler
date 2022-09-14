// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./ILevelManager.sol";
import "../AdminableUpgradeable.sol";

abstract contract WithPools is AdminableUpgradeable, ILevelManager {
    uint256 constant DEFAULT_MULTIPLIER = 1_000_000_000;

    address[] public pools;
    mapping(address => bool) public poolEnabled;
    // 1x = 100, 0.5x = 50
    mapping(address => uint256) public poolMultiplier;

    event PoolEnabled(address indexed pool, bool status);
    event PoolMultiplierSet(address indexed pool, uint256 multiplier);

    function addPool(
        address pool,
        uint256 multiplier
    ) external onlyOwnerOrAdmin {
        require(!poolExists(pool), "LevelManager: Pool is already added");
        pools.push(pool);
        togglePool(pool, true);

        if (multiplier == 0) {
            multiplier = DEFAULT_MULTIPLIER;
        }
        setPoolMultiplier(pool, multiplier);
    }

    function togglePool(address pool, bool status) public onlyOwnerOrAdmin {
        poolEnabled[pool] = status;
        emit PoolEnabled(pool, status);
    }

    function setPoolMultiplier(address pool, uint256 multiplier)
        public
        onlyOwnerOrAdmin
    {
        require(poolExists(pool), "LevelManager: Pool does not exist");
        require(multiplier > 0, "LevelManager: Multiplier must be > 0");
        poolMultiplier[pool] = multiplier;
        emit PoolMultiplierSet(pool, multiplier);
    }

    function poolExists(address pool) internal view returns (bool) {
        for (uint256 i = 0; i < pools.length; i++) {
            if (address(pools[i]) == pool) {
                return true;
            }
        }
        return false;
    }
}