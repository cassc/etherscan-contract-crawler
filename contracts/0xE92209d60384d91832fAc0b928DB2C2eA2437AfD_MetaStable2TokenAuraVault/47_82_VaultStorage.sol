// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {StrategyVaultSettings, StrategyVaultState} from "./VaultTypes.sol";
import {VaultEvents} from "./VaultEvents.sol";
import {VaultConstants} from "./VaultConstants.sol";

library VaultStorage {
    uint256 private constant STRATEGY_VAULT_SETTINGS_SLOT = 1000001;
    uint256 private constant STRATEGY_VAULT_STATE_SLOT    = 1000002;

    function _settings() private pure returns (mapping(uint256 => StrategyVaultSettings) storage store) {
        assembly { store.slot := STRATEGY_VAULT_SETTINGS_SLOT }
    }

    function _state() private pure returns (mapping(uint256 => StrategyVaultState) storage store) {
        assembly { store.slot := STRATEGY_VAULT_STATE_SLOT }
    }

    function getStrategyVaultSettings() internal view returns (StrategyVaultSettings memory) {
        // Hardcode to the zero slot
        return _settings()[0];
    }

    function setStrategyVaultSettings(StrategyVaultSettings memory settings) internal {
        require(settings.settlementCoolDownInMinutes <= VaultConstants.MAX_SETTLEMENT_COOLDOWN_IN_MINUTES);
        require(settings.maxPoolShare <= VaultConstants.VAULT_PERCENT_BASIS);
        require(settings.settlementSlippageLimitPercent <= VaultConstants.SLIPPAGE_LIMIT_PRECISION);
        require(settings.postMaturitySettlementSlippageLimitPercent <= VaultConstants.SLIPPAGE_LIMIT_PRECISION);
        require(settings.emergencySettlementSlippageLimitPercent <= VaultConstants.SLIPPAGE_LIMIT_PRECISION);
        require(settings.oraclePriceDeviationLimitPercent <= VaultConstants.VAULT_PERCENT_BASIS);
        require(settings.poolSlippageLimitPercent <= VaultConstants.VAULT_PERCENT_BASIS);

        mapping(uint256 => StrategyVaultSettings) storage store = _settings();
        // Hardcode to the zero slot
        store[0] = settings;

        emit VaultEvents.StrategyVaultSettingsUpdated(settings);
    }

    function getStrategyVaultState() internal view returns (StrategyVaultState memory) {
        // Hardcode to the zero slot
        return _state()[0];
    }

    function setStrategyVaultState(StrategyVaultState memory state) internal {
        mapping(uint256 => StrategyVaultState) storage store = _state();
        // Hardcode to the zero slot
        store[0] = state;
    }

    function _poolClaimThreshold(StrategyVaultSettings memory strategyVaultSettings, uint256 totalPoolSupply) 
        internal pure returns (uint256) {
        return (totalPoolSupply * strategyVaultSettings.maxPoolShare) / VaultConstants.VAULT_PERCENT_BASIS;
    }
}