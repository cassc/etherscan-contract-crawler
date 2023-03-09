// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../interfaces/IStakingFactory.sol";
import "../lib/BeaconUpgradeable.sol";
import "../lib/BeaconProxyOptimized.sol";

contract StakingFactory is IStakingFactory, BeaconUpgradeable {
    // token => staking pool
    mapping(address => address) public stakingPools;
    uint256 public lockPeriod;

    function initialize(address implementation_, uint256 lockPeriod_) public initializer {
        __Ownable2Step_init();
        __Beacon_init(implementation_);
        lockPeriod = lockPeriod_;
    }

    function createStakingPool(address token) external {
        address pool = stakingPools[token];
        if (pool != address(0)) revert StakingPoolAlreadyExists(token, pool);

        bytes32 salt = keccak256(abi.encodePacked(token));
        pool = address(new BeaconProxyOptimized{salt: salt}());
        stakingPools[token] = pool;

        IPool(pool).initialize(token);

        emit StakingPoolCreated(token, pool);
    }

    function updateLockPeriod(uint256 newLockPeriod) external onlyOwner {
        emit LockPeriodUpdated(lockPeriod, newLockPeriod);
        lockPeriod = newLockPeriod;
    }

    function getPoolForRewardDistribution(address token) external view returns (address) {
        address pool = stakingPools[token];
        if (pool == address(0)) return address(0);
        return IPool(pool).totalSupply() != 0 ? pool : address(0);
    }

    uint256[50] private __gap;
}