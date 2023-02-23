// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IRewardsEscrowV1.sol";

interface IRewardsEscrowV1UUPSUpgradeable is IRewardsEscrowV1 {
    function initializeUUPS(address roleAdmin, address upgrader) external;
}