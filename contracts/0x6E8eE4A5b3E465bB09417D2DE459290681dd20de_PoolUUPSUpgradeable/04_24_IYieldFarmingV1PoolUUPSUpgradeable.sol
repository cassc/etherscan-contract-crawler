// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IYieldFarmingV1Pool.sol";

interface IYieldFarmingV1PoolUUPSUpgradeable is IYieldFarmingV1Pool {
    function initializeUUPS(PoolConfig memory cfg, address roleAdmin, address upgrader) external;
}