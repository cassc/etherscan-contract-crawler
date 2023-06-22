/*
PoolInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "../interfaces/IPoolInfo.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IStakingModule.sol";
import "../interfaces/IRewardModule.sol";
import "../interfaces/IStakingModuleInfo.sol";
import "../interfaces/IRewardModuleInfo.sol";
import "../OwnerController.sol";

/**
 * @title Pool info library
 *
 * @notice this implements the Pool info library, which provides read-only
 * convenience functions to query additional information and metadata
 * about the core Pool contract.
 */

contract PoolInfo is IPoolInfo, OwnerController {
    mapping(address => address) public registry;

    /**
     * @inheritdoc IPoolInfo
     */
    function modules(
        address pool
    ) public view override returns (address, address, address, address) {
        IPool p = IPool(pool);
        IStakingModule s = IStakingModule(p.stakingModule());
        IRewardModule r = IRewardModule(p.rewardModule());
        return (address(s), address(r), s.factory(), r.factory());
    }

    /**
     * @notice register factory to info module
     * @param factory address of factory
     * @param info address of info module contract
     */
    function register(address factory, address info) external onlyController {
        registry[factory] = info;
    }

    /**
     * @inheritdoc IPoolInfo
     */
    function rewards(
        address pool,
        address addr,
        bytes calldata stakingdata,
        bytes calldata rewarddata
    ) public view override returns (uint256[] memory rewards_) {
        address stakingModule;
        address rewardModule;
        IStakingModuleInfo stakingModuleInfo;
        IRewardModuleInfo rewardModuleInfo;
        {
            address stakingModuleType;
            address rewardModuleType;
            (
                stakingModule,
                rewardModule,
                stakingModuleType,
                rewardModuleType
            ) = modules(pool);

            stakingModuleInfo = IStakingModuleInfo(registry[stakingModuleType]);
            rewardModuleInfo = IRewardModuleInfo(registry[rewardModuleType]);
        }

        rewards_ = new uint256[](IPool(pool).rewardTokens().length);

        (bytes32[] memory accounts, uint256[] memory shares) = stakingModuleInfo
            .positions(stakingModule, addr, stakingdata);

        for (uint256 i; i < accounts.length; ++i) {
            uint256[] memory r = rewardModuleInfo.rewards(
                rewardModule,
                accounts[i],
                shares[i],
                rewarddata
            );
            for (uint256 j; j < r.length; ++j) rewards_[j] += r[j];
        }
    }
}