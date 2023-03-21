pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { IERC20 } from "@blockswaplab/stakehouse-solidity-api/contracts/IERC20.sol";

import { GiantSavETHVaultPool } from "../../liquid-staking/GiantSavETHVaultPool.sol";
import { GiantLP } from "../../liquid-staking/GiantLP.sol";
import { LSDNFactory } from "../../liquid-staking/LSDNFactory.sol";
import { MockLSDNFactory } from "../../testing/liquid-staking/MockLSDNFactory.sol";

contract MockGiantSavETHVaultPool is GiantSavETHVaultPool {

    /// ----------------------
    /// Override Solidity API
    /// ----------------------

    function getDETH() internal view override returns (IERC20 dETH) {
        return IERC20(MockLSDNFactory(address(liquidStakingDerivativeFactory)).dETH());
    }
}