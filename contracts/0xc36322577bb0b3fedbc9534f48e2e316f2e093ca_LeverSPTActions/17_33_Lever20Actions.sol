// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {WAD, toInt256, mul, div, wmul, wdiv} from "fiat/utils/Math.sol";

import {LeverActions} from "./LeverActions.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Lever20Actions
/// @notice A set of vault actions for modifying positions collateralized by ERC20 tokens
contract Lever20Actions is LeverActions {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error Lever20Actions__enterVault_zeroVaultAddress();
    error Lever20Actions__enterVault_zeroTokenAddress();
    error Lever20Actions__exitVault_zeroVaultAddress();
    error Lever20Actions__exitVault_zeroTokenAddress();
    error Lever20Actions__exitVault_zeroToAddress();

    constructor(
        address codex,
        address fiat,
        address flash,
        address moneta,
        address publican,
        bytes32 fiatPoolId,
        address fiatBalancerVault
    ) LeverActions(codex, fiat, flash, moneta, publican, fiatPoolId, fiatBalancerVault) {}

    /// @notice Deposits amount of `token` with `tokenId` from `from` into the `vault`
    /// @dev Implements virtual method defined in Lever20Actions for ERC20 tokens
    /// @param vault Address of the Vault to enter
    /// @param token Address of the collateral token
    /// @param *tokenId ERC1155 TokenId (leave empty for ERC20 tokens)
    /// @param from Address from which to take the deposit from
    /// @param amount Amount of collateral tokens to deposit [tokenScale]
    function enterVault(
        address vault,
        address token,
        uint256, /* tokenId */
        address from,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert Lever20Actions__enterVault_zeroVaultAddress();
        if (token == address(0)) revert Lever20Actions__enterVault_zeroTokenAddress();

        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            IERC20(token).safeTransferFrom(from, address(this), amount);
        }

        IERC20(token).approve(vault, amount);
        IVault(vault).enter(0, address(this), amount);
    }

    /// @notice Withdraws amount of `token` with `tokenId` to `to` from the `vault`
    /// @dev Implements virtual method defined in Lever20Actions for ERC20 tokens
    /// @param vault Address of the Vault to exit
    /// @param token Address of the collateral token
    /// @param *tokenId ERC1155 TokenId (leave empty for ERC20 tokens)
    /// @param to Address which receives the withdrawn collateral tokens
    /// @param amount Amount of collateral tokens to exit [tokenScale]
    function exitVault(
        address vault,
        address token,
        uint256, /* tokenId */
        address to,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert Lever20Actions__exitVault_zeroVaultAddress();
        if (token == address(0)) revert Lever20Actions__exitVault_zeroTokenAddress();
        if (to == address(0)) revert Lever20Actions__exitVault_zeroToAddress();

        IVault(vault).exit(0, to, amount);
    }
}