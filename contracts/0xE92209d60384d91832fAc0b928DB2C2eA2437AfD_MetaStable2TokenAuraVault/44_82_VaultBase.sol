// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {BaseStrategyVault} from "../BaseStrategyVault.sol";
import {NotionalProxy} from "../../../interfaces/notional/NotionalProxy.sol";
import {ITradingModule} from "../../../interfaces/trading/ITradingModule.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

abstract contract VaultBase is BaseStrategyVault, UUPSUpgradeable {

    /** Immutables */
    uint32 internal immutable SETTLEMENT_PERIOD_IN_SECONDS;

    constructor(NotionalProxy notional_, ITradingModule tradingModule_, uint32 settlementPeriodInSeconds_) 
        BaseStrategyVault(notional_, tradingModule_)
    {
        SETTLEMENT_PERIOD_IN_SECONDS = settlementPeriodInSeconds_;
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