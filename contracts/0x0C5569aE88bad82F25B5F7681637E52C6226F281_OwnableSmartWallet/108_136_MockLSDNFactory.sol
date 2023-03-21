pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { IFactoryDependencyInjector } from "../interfaces/IFactoryDependencyInjector.sol";

import { MockAccountManager } from "../stakehouse/MockAccountManager.sol";
import { MockTransactionRouter } from "../stakehouse/MockTransactionRouter.sol";
import { MockSavETHRegistry } from "../stakehouse/MockSavETHRegistry.sol";
import { MockStakeHouseUniverse } from "../stakehouse/MockStakeHouseUniverse.sol";
import { MockSlotRegistry } from "../stakehouse/MockSlotRegistry.sol";
import { MockLiquidStakingManager } from "./MockLiquidStakingManager.sol";

import { MockERC20 } from "../MockERC20.sol";

import { SyndicateFactoryMock } from "../syndicate/SyndicateFactoryMock.sol";

import { LSDNFactory } from "../../../contracts/liquid-staking/LSDNFactory.sol";
import { LiquidStakingManager } from "../../../contracts/liquid-staking/LiquidStakingManager.sol";

// In the mock LSDN factory world, the mock factory is always the admin of LSDN network for ease and to allow mock stakehouse dependency injection
contract MockLSDNFactory is IFactoryDependencyInjector, LSDNFactory {

    /// @dev Mock Stakehouse dependencies that will be injected into the LSDN networks
    address public override accountMan;
    address public override txRouter;
    address public override uni;
    address public override slot;
    address public override saveETHRegistry;
    address public override dETH;

    constructor(InitParams memory _params) {
        _init(_params);

        // Create mock Stakehouse contract dependencies that can later be injected
        accountMan = address(new MockAccountManager());
        txRouter = address(new MockTransactionRouter());
        uni = address(new MockStakeHouseUniverse());
        slot = address(new MockSlotRegistry());
        saveETHRegistry = address(new MockSavETHRegistry());

        // notify TX router about the mock SLOT registry
        MockTransactionRouter(txRouter).setMockSlotRegistry(MockSlotRegistry(slot));
        MockTransactionRouter(txRouter).setMockUniverse(MockStakeHouseUniverse(uni));
        MockTransactionRouter(txRouter).setMockBrand(_params._brand);

        // msg.sender is deployer and they will get initial supply of dETH
        dETH = address(new MockERC20("dToken", "dETH", msg.sender));

        SyndicateFactoryMock syndicateFactoryMock = new SyndicateFactoryMock(
            accountMan,
            txRouter,
            uni,
            slot
        );
        syndicateFactory = address(syndicateFactoryMock);

        assert(syndicateFactoryMock.slot() == slot);
    }

    /// @dev Tests will call this instead of super method to ensure correct dependency injection of Stakehouse
    function deployNewMockLiquidStakingDerivativeNetwork(
        address,
        bool _deployOptionalHouseGatekeeper,
        string calldata _stakehouseTicker
    ) external returns (address) {
        // Make DAO this factory for dependency injection
        return deployNewLiquidStakingDerivativeNetwork(
            address(this),
            0,
            _deployOptionalHouseGatekeeper,
            _stakehouseTicker
        );
    }

    function deployNewMockLiquidStakingDerivativeNetworkWithCommission(
        address,
        uint256 _optionalCommission,
        bool _deployOptionalHouseGatekeeper,
        string calldata _stakehouseTicker
    ) external returns (address) {
        // Make DAO this factory for dependency injection
        return deployNewLiquidStakingDerivativeNetwork(
            address(this),
            _optionalCommission,
            _deployOptionalHouseGatekeeper,
            _stakehouseTicker
        );
    }
}