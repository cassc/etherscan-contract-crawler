// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IERC20 } from "@blockswaplab/stakehouse-solidity-api/contracts/IERC20.sol";
import { ISavETHManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ISavETHManager.sol";
import { IAccountManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IAccountManager.sol";

import { LiquidStakingManager } from "../../liquid-staking/LiquidStakingManager.sol";
import { LPTokenFactory } from "../../liquid-staking/LPTokenFactory.sol";
import { LPToken } from "../../liquid-staking/LPToken.sol";
import { StakingFundsVault } from "../../liquid-staking/StakingFundsVault.sol";
import { MockSavETHRegistry } from "../stakehouse/MockSavETHRegistry.sol";
import { MockAccountManager } from "../stakehouse/MockAccountManager.sol";
import { IFactoryDependencyInjector } from "../interfaces/IFactoryDependencyInjector.sol";

contract MockStakingFundsVault is StakingFundsVault {

    MockSavETHRegistry public saveETHRegistry;
    MockAccountManager public accountMan;
    IERC20 public dETHToken;

    function injectDependencies(address _lsdnFactory) external {
        IFactoryDependencyInjector dependencyInjector = IFactoryDependencyInjector(
            _lsdnFactory
        );

        dETHToken = IERC20(dependencyInjector.dETH());
        saveETHRegistry = MockSavETHRegistry(dependencyInjector.saveETHRegistry());
        accountMan = MockAccountManager(dependencyInjector.accountMan());

        saveETHRegistry.setDETHToken(dETHToken);
    }

    function init(address _liquidStakingManagerAddress, LPTokenFactory _tokenFactory) external override {
        _init(LiquidStakingManager(payable(_liquidStakingManagerAddress)), _tokenFactory);
    }

    /// ----------------------
    /// Override Solidity API
    /// ----------------------

    function getAccountManager() internal view override returns (IAccountManager accountManager) {
        return IAccountManager(address(accountMan));
    }

}