pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { LSDNFactory } from "../liquid-staking/LSDNFactory.sol";

interface IGiantMevAndFeesPool {
    function init(LSDNFactory _factory, address _lpDeployer, address _upgradeManager) external;
}