pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { GiantMevAndFeesPool } from "../../liquid-staking/GiantMevAndFeesPool.sol";
import { MockLSDNFactory } from "../../testing/liquid-staking/MockLSDNFactory.sol";
import { IAccountManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IAccountManager.sol";

contract MockGiantMevAndFeesPool is GiantMevAndFeesPool {
    function getAccountManager() internal view override returns (IAccountManager accountManager) {
        return IAccountManager(MockLSDNFactory(address(liquidStakingDerivativeFactory)).accountMan());
    }
}