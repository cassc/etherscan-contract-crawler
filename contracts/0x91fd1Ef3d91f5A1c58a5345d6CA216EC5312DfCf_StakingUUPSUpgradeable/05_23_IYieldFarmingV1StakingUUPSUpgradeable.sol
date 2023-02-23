// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IYieldFarmingV1Staking.sol";

interface IYieldFarmingV1StakingUUPSUpgradeable is IYieldFarmingV1Staking {
    function initializeUUPS(StakingConfig memory cfg, address roleAdmin, address upgrader) external;
}