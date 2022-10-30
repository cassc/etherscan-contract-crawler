// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {BaseStrategyVault} from "../BaseStrategyVault.sol";
import {DeploymentParams} from "./BalancerVaultTypes.sol";
import {NotionalProxy} from "../../../interfaces/notional/NotionalProxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract BalancerStrategyBase is BaseStrategyVault, UUPSUpgradeable {

    /** Immutables */
    uint32 internal immutable SETTLEMENT_PERIOD_IN_SECONDS;

    constructor(NotionalProxy notional_, DeploymentParams memory params) 
        BaseStrategyVault(notional_, params.tradingModule)
    {
        SETTLEMENT_PERIOD_IN_SECONDS = params.settlementPeriodInSeconds;
    }

    function _revertInSettlementWindow(uint256 maturity) internal view {
        if (maturity - SETTLEMENT_PERIOD_IN_SECONDS <= block.timestamp) {
            revert();
        }
    }

    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal override onlyNotionalOwner {}
    
    // Storage gap for future potential upgrades
    uint256[100] private __gap;
}