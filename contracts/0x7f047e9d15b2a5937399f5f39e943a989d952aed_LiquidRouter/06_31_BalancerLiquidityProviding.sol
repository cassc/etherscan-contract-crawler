// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {IBalancerVault} from "src/interfaces/IBalancerVault.sol";
import {TokenUtils, Constants} from "src/common/TokenUtils.sol";

/// @title BalancerLiquidityProviding
/// @notice Enables to add/remove liquidity to/from the Balancer Vault.
abstract contract BalancerLiquidityProviding {
    /// @notice Balancer Vault contract address.
    address internal constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice Adds liquidity to the Balancer Vault.
    /// @param poolId Pool ID.
    /// @param tokens Tokens addresses.
    /// @param underlyingAmounts Amounts of tokens to add.
    /// @param userData User data.
    /// @param recipient Recipient address.
    function addLiquidity(
        bytes32 poolId,
        address[] calldata tokens,
        uint256[] memory underlyingAmounts,
        bytes calldata userData,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        for (uint8 i; i < tokens.length;) {
            underlyingAmounts[i] = TokenUtils._amountIn(underlyingAmounts[i], tokens[i]);
            if (underlyingAmounts[i] != 0) TokenUtils._approve(tokens[i], BALANCER_VAULT);
            unchecked {
                ++i;
            }
        }

        IBalancerVault.JoinPoolRequest memory pr =
            IBalancerVault.JoinPoolRequest(tokens, underlyingAmounts, userData, false);
        IBalancerVault(BALANCER_VAULT).joinPool(poolId, address(this), recipient, pr);
    }

    /// @notice Removes liquidity from the Balancer Vault.
    /// @param poolId Pool ID.
    /// @param tokens Tokens addresses.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP token to remove.
    /// @param minAmountsOut Minimum amounts of tokens to receive.
    /// @param userData User data.
    /// @param recipient Recipient address.
    function removeLiquidty(
        bytes32 poolId,
        address[] calldata tokens,
        address lpToken,
        uint256 underlyingAmount,
        uint256[] calldata minAmountsOut,
        bytes calldata userData,
        address recipient
    ) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        IBalancerVault.ExitPoolRequest memory pr =
            IBalancerVault.ExitPoolRequest(tokens, minAmountsOut, userData, false);
        IBalancerVault(BALANCER_VAULT).exitPool(poolId, address(this), recipient, pr);
    }
}