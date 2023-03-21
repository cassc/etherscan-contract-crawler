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

contract MockLiquidStakingManager is LiquidStakingManager {

    /// @dev Mock stakehouse dependencies injected from the super factory
    address public accountMan;
    address public txRouter;
    address public uni;
    address public slot;

    function init(
        address _dao,
        address _syndicateFactory,
        address _smartWalletFactory,
        address _lpTokenFactory,
        address _brand,
        address _savETHVaultDeployer,
        address _stakingFundsVaultDeployer,
        address _optionalGatekeeperDeployer,
        uint256 _optionalCommission,
        bool _deployOptionalGatekeeper,
        string calldata _stakehouseTicker
    ) external override initializer {
        IFactoryDependencyInjector superFactory = IFactoryDependencyInjector(_dao);
        accountMan = superFactory.accountMan();
        txRouter = superFactory.txRouter();
        uni = superFactory.uni();
        slot = superFactory.slot();

        setFactory(address(superFactory));

        _init(
            _dao,
            _syndicateFactory,
            _smartWalletFactory,
            _lpTokenFactory,
            _brand,
            _savETHVaultDeployer,
            _stakingFundsVaultDeployer,
            _optionalGatekeeperDeployer,
            _optionalCommission,
            _deployOptionalGatekeeper,
            _stakehouseTicker
        );
    }

    mapping(bytes => bool) isPartOfNetwork;
    function setIsPartOfNetwork(bytes calldata _key, bool _isPart) external {
        isPartOfNetwork[_key] = _isPart;
    }

    function isBLSPublicKeyPartOfLSDNetwork(bytes calldata _blsPublicKeyOfKnot) public override view returns (bool) {
        return isPartOfNetwork[_blsPublicKeyOfKnot] || super.isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot);
    }

    /// @dev override this to use MockSavETHVault which uses a mock solidity API from the test dependency injector
    function _initSavETHVault(address, address _lpTokenFactory) internal override {
        savETHVault = new MockSavETHVault();
        MockSavETHVault(address(savETHVault)).injectDependencies(address(factory));
        savETHVault.init(address(this), LPTokenFactory(_lpTokenFactory));
    }

    /// @dev override this to use MockStakingFundsVault which uses a mock solidity API from the test dependency injector
    function _initStakingFundsVault(address, address _lpTokenFactory) internal override {
        stakingFundsVault = new MockStakingFundsVault();
        MockStakingFundsVault(payable(address(stakingFundsVault))).injectDependencies(address(factory));
        stakingFundsVault.init(address(this), LPTokenFactory(_lpTokenFactory));
    }

    function setFactory(address _factory) public {
        require(_factory != address(0), "Zero factory supplied");
        factory = LSDNFactory(_factory);
    }

    /// ----------------------
    /// Override Solidity API
    /// ----------------------

    function getSlotRegistry() internal view override returns (ISlotSettlementRegistry) {
        return ISlotSettlementRegistry(slot);
    }

    function getAccountManager() internal view override returns (IAccountManager) {
        return IAccountManager(accountMan);
    }

    function getTransactionRouter() internal view override returns (ITransactionRouter) {
        return ITransactionRouter(txRouter);
    }

    function getStakeHouseUniverse() internal view override returns (IStakeHouseUniverse) {
        return IStakeHouseUniverse(uni);
    }
}