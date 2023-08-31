// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { V2Migrator } from "./base/V2Migrator.sol";
import { CorePool } from "./base/CorePool.sol";
import { ErrorHandler } from "./libraries/ErrorHandler.sol";
import { ICorePoolV1 } from "./interfaces/ICorePoolV1.sol";

/**
 * @title The Sushi LP Pool.
 *
 * @dev Extends all functionality from V2Migrator contract, there isn't a lot of
 *      additions compared to ILV pool. Sushi LP pool basically needs to be able
 *      to be called by ILV pool in batch calls where we claim rewards from multiple
 *      pools.
 */
contract SushiLPPool is Initializable, V2Migrator {
    using ErrorHandler for bytes4;

    /// @dev Calls __V2Migrator_init().
    function initialize(
        address ilv_,
        address silv_,
        address _poolToken,
        address _factory,
        uint64 _initTime,
        uint32 _weight,
        address _corePoolV1,
        uint256 v1StakeMaxPeriod_
    ) external initializer {
        __V2Migrator_init(ilv_, silv_, _poolToken, _corePoolV1, _factory, _initTime, _weight, v1StakeMaxPeriod_);
    }

    /// @inheritdoc CorePool
    function getTotalReserves() external view virtual override returns (uint256 totalReserves) {
        totalReserves = poolTokenReserve + ICorePoolV1(corePoolV1).usersLockingWeight();
    }

    /**
     * @notice This function can be called only by ILV core pool.
     *
     * @dev Uses ILV pool as a router by receiving the _staker address and executing
     *      the internal `_claimYieldRewards()`.
     * @dev Its usage allows claiming multiple pool contracts in one transaction.
     *
     * @param _staker user address
     * @param _useSILV whether it should claim pendingYield as ILV or sILV
     */
    function claimYieldRewardsFromRouter(address _staker, bool _useSILV) external virtual {
        // checks if contract is paused
        _requireNotPaused();
        // checks if caller is the ILV pool
        _requirePoolIsValid();

        // calls internal _claimYieldRewards function (in CorePool.sol)
        _claimYieldRewards(_staker, _useSILV);
    }

    /**
     * @notice This function can be called only by ILV core pool.
     *
     * @dev Uses ILV pool as a router by receiving the _staker address and executing
     *      the internal `_claimVaultRewards()`.
     * @dev Its usage allows claiming multiple pool contracts in one transaction.
     *
     * @param _staker user address
     */
    function claimVaultRewardsFromRouter(address _staker) external virtual {
        // checks if contract is paused
        _requireNotPaused();
        // checks if caller is the ILV pool
        _requirePoolIsValid();

        // calls internal _claimVaultRewards function (in CorePool.sol)
        _claimVaultRewards(_staker);
    }

    /**
     * @dev Checks if caller is ILV pool.
     * @dev We are using an internal function instead of a modifier in order to
     *      reduce the contract's bytecode size.
     */
    function _requirePoolIsValid() internal view virtual {
        // we're using selector to simplify input and state validation
        // internal function simulated selector is `bytes4(keccak256("_requirePoolIsValid()"))`
        bytes4 fnSelector = 0x250f303f;

        // checks if pool is the ILV pool
        bool poolIsValid = address(_factory.pools(_ilv)) == msg.sender;
        fnSelector.verifyState(poolIsValid, 0);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}