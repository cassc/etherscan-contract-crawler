// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../interfaces/ILevelManager.sol';
import '../AdminableUpgradeable.sol';

abstract contract WithPools is AdminableUpgradeable, ILevelManager {
    uint256 constant DEFAULT_MULTIPLIER = 1_000_000_000;

    Pool[] public pools;

    event PoolEnabled(address indexed pool, bool status);
    event PoolMultiplierSet(address indexed pool);

    function setPool(
        address addr,
        bool isVIP,
        bool isAAG,
        uint256 minAAGLevelMultiplier,
        uint256 multiplierLotteryBoost,
        uint256 multiplierGuaranteedBoost,
        uint256 multiplierAAGBoost
    ) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i].addr == addr) {
                Pool storage pool = pools[i];
                pool.enabled = true;
                pool.isAAG = isAAG;
                pool.isVip = isVIP;
                pool.minAAGLevelMultiplier = minAAGLevelMultiplier;
                pool.multiplierLotteryBoost = multiplierLotteryBoost;
                pool.multiplierGuaranteedBoost = multiplierGuaranteedBoost;
                pool.multiplierAAGBoost = multiplierAAGBoost;
                return;
            }
        }
        pools.push(
            Pool(
                addr,
                true,
                isVIP,
                isAAG,
                minAAGLevelMultiplier,
                multiplierLotteryBoost,
                multiplierGuaranteedBoost,
                multiplierAAGBoost
            )
        );
    }

    function togglePool(address pool, bool status) public onlyOwnerOrAdmin {
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i].addr == pool) {
                pools[i].enabled = status;
                emit PoolEnabled(pool, status);
                break;
            }
        }
    }
}