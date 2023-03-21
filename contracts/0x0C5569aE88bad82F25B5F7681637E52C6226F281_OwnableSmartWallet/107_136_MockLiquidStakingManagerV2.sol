// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { LiquidStakingManager } from "../../liquid-staking/LiquidStakingManager.sol";
import { LPTokenFactory } from "../../liquid-staking/LPTokenFactory.sol";
import { LSDNFactory } from "../../liquid-staking/LSDNFactory.sol";
import { MockSavETHVault } from "./MockSavETHVault.sol";
import { MockStakingFundsVault } from "./MockStakingFundsVault.sol";
import { SyndicateFactory } from "../../syndicate/SyndicateFactory.sol";
import { Syndicate } from "../../syndicate/Syndicate.sol";
import { MockAccountManager } from "../stakehouse/MockAccountManager.sol";
import { MockTransactionRouter } from "../stakehouse/MockTransactionRouter.sol";
import { MockStakeHouseUniverse } from "../stakehouse/MockStakeHouseUniverse.sol";
import { MockSlotRegistry } from "../stakehouse/MockSlotRegistry.sol";
import { IAccountManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IAccountManager.sol";
import { ITransactionRouter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ITransactionRouter.sol";
import { IStakeHouseUniverse } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IStakeHouseUniverse.sol";
import { ISlotSettlementRegistry } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ISlotSettlementRegistry.sol";

import { IFactoryDependencyInjector } from "../interfaces/IFactoryDependencyInjector.sol";

contract MockLiquidStakingManagerV2 is LiquidStakingManager {

    /// @dev Mock stakehouse dependencies injected from the super factory
    address public accountMan;
    address public txRouter;
    address public uni;
    address public slot;

    function sing() external view returns (bool) {
        return true;
    }
}