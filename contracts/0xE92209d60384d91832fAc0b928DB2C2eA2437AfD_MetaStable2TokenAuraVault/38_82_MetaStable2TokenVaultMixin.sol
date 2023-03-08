// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {AuraVaultDeploymentParams, MetaStable2TokenAuraStrategyContext} from "../BalancerVaultTypes.sol";
import {IMetaStablePool} from "../../../../interfaces/balancer/IBalancerPool.sol";
import {StableOracleContext} from "../BalancerVaultTypes.sol";
import {Balancer2TokenPoolMixin} from "./Balancer2TokenPoolMixin.sol";
import {NotionalProxy} from "../../../../interfaces/notional/NotionalProxy.sol";
import {StableMath} from "../internal/math/StableMath.sol";

abstract contract MetaStable2TokenVaultMixin is Balancer2TokenPoolMixin {
    constructor(NotionalProxy notional_, AuraVaultDeploymentParams memory params)
        Balancer2TokenPoolMixin(notional_, params) { }

    function _stableOracleContext() internal view returns (StableOracleContext memory) {
        (
            uint256 value,
            /* bool isUpdating */,
            uint256 precision
        ) = IMetaStablePool(address(BALANCER_POOL_TOKEN)).getAmplificationParameter();
        require(precision == StableMath._AMP_PRECISION);
        
        return StableOracleContext({
            ampParam: value
        });
    }

    function _strategyContext() internal view returns (MetaStable2TokenAuraStrategyContext memory) {
        return MetaStable2TokenAuraStrategyContext({
            poolContext: _twoTokenPoolContext(),
            oracleContext: _stableOracleContext(),
            stakingContext: _auraStakingContext(),
            baseStrategy: _baseStrategyContext()
        });
    }

    uint256[40] private __gap; // Storage gap for future potential upgrades
}