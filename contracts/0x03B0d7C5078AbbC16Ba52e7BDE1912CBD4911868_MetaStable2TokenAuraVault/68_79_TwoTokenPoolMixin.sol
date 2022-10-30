// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {IERC20} from "../../../../interfaces/IERC20.sol";
import {Deployments} from "../../../global/Deployments.sol";
import {TwoTokenPoolContext, AuraVaultDeploymentParams} from "../BalancerVaultTypes.sol";
import {BalancerConstants} from "../internal/BalancerConstants.sol";
import {BalancerUtils} from "../internal/pool/BalancerUtils.sol";
import {PoolMixin} from "./PoolMixin.sol";
import {NotionalProxy} from "../../../../interfaces/notional/NotionalProxy.sol";
import {IBalancerPool} from "../../../../interfaces/balancer/IBalancerPool.sol";

abstract contract TwoTokenPoolMixin is PoolMixin {
    error InvalidPrimaryToken(address token);
    error InvalidSecondaryToken(address token);

    IERC20 internal immutable PRIMARY_TOKEN;
    IERC20 internal immutable SECONDARY_TOKEN;
    uint8 internal immutable PRIMARY_INDEX;
    uint8 internal immutable SECONDARY_INDEX;
    uint8 internal immutable PRIMARY_DECIMALS;
    uint8 internal immutable SECONDARY_DECIMALS;

    constructor(
        NotionalProxy notional_, 
        AuraVaultDeploymentParams memory params
    ) PoolMixin(notional_, params) {
        PRIMARY_TOKEN = IERC20(_getNotionalUnderlyingToken(params.baseParams.primaryBorrowCurrencyId));
        address primaryAddress = BalancerUtils.getTokenAddress(address(PRIMARY_TOKEN));

        // prettier-ignore
        (
            address[] memory tokens,
            /* uint256[] memory balances */,
            /* uint256 lastChangeBlock */
        ) = Deployments.BALANCER_VAULT.getPoolTokens(params.baseParams.balancerPoolId);

        // Balancer tokens are sorted by address, so we need to figure out
        // the correct index for the primary token
        PRIMARY_INDEX = tokens[0] == primaryAddress ? 0 : 1;
        unchecked {
            SECONDARY_INDEX = 1 - PRIMARY_INDEX;
        }

        SECONDARY_TOKEN = IERC20(tokens[SECONDARY_INDEX]);

        // Make sure the deployment parameters are correct
        if (tokens[PRIMARY_INDEX] != primaryAddress) {
            revert InvalidPrimaryToken(tokens[PRIMARY_INDEX]);
        }

        if (tokens[SECONDARY_INDEX] !=
            BalancerUtils.getTokenAddress(address(SECONDARY_TOKEN))
        ) revert InvalidSecondaryToken(tokens[SECONDARY_INDEX]);

        // If the underlying is ETH, primaryBorrowToken will be rewritten as WETH
        uint256 primaryDecimals = IERC20(primaryAddress).decimals();
        // Do not allow decimal places greater than 18
        require(primaryDecimals <= 18);
        PRIMARY_DECIMALS = uint8(primaryDecimals);

        uint256 secondaryDecimals = address(SECONDARY_TOKEN) ==
            Deployments.ETH_ADDRESS
            ? 18
            : SECONDARY_TOKEN.decimals();
        require(secondaryDecimals <= 18);
        SECONDARY_DECIMALS = uint8(secondaryDecimals);
    }

    function _twoTokenPoolContext() internal view returns (TwoTokenPoolContext memory) {
        (
            /* address[] memory tokens */,
            uint256[] memory balances,
            /* uint256 lastChangeBlock */
        ) = Deployments.BALANCER_VAULT.getPoolTokens(BALANCER_POOL_ID);

        uint256[] memory scalingFactors = IBalancerPool(address(BALANCER_POOL_TOKEN)).getScalingFactors();

        return TwoTokenPoolContext({
            primaryToken: address(PRIMARY_TOKEN),
            secondaryToken: address(SECONDARY_TOKEN),
            primaryIndex: PRIMARY_INDEX,
            secondaryIndex: SECONDARY_INDEX,
            primaryDecimals: PRIMARY_DECIMALS,
            secondaryDecimals: SECONDARY_DECIMALS,
            primaryBalance: balances[PRIMARY_INDEX],
            secondaryBalance: balances[SECONDARY_INDEX],
            primaryScaleFactor: scalingFactors[PRIMARY_INDEX],
            secondaryScaleFactor: scalingFactors[SECONDARY_INDEX],
            basePool: _poolContext()
        });
    }

    uint256[40] private __gap; // Storage gap for future potential upgrades
}