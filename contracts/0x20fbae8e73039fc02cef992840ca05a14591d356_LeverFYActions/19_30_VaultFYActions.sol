// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "../../interfaces/IVault.sol";
import {WAD, toInt256, wmul, wdiv, sub} from "../../core/utils/Math.sol";

import {Vault20Actions} from "./Vault20Actions.sol";

interface IFYPool {
    function sellBasePreview(uint128 baseIn) external view returns (uint128);

    function sellBase(address to, uint128 min) external returns (uint128);

    function sellFYTokenPreview(uint128 fyTokenIn) external view returns (uint128);

    function sellFYToken(address to, uint128 min) external returns (uint128);
}

interface IFYToken {
    function redeem(address to, uint256 amount) external returns (uint256 redeemed);
}

/// @title VaultFYActions
/// @notice A set of vault actions for modifying positions collateralized by Yield Protocol Fixed Yield Tokens
contract VaultFYActions is Vault20Actions {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error VaultFYActions__buyCollateralAndModifyDebt_invalidUnderlierAmount();
    error VaultFYActions__sellCollateralAndModifyDebt_invalidFYTokenAmount();
    error VaultFYActions__redeemCollateralAndModifyDebt_invalidFYTokenAmount();
    error VaultFYActions__toUint128_overflow();

    /// ======== Types ======== ///

    // Swap data
    struct SwapParams {
        // Min amount of asset out [tokenScale for buying, underlierScale for selling]
        uint256 minAssetOut;
        // Address of the Yield Space v2 pool
        address yieldSpacePool;
        // Address of the underlier (underlierToken) when buying, Address of the fyToken (token) when selling
        address assetIn;
        // Address of the fyToken (token) when buying, Address of underlier (underlierToken) when selling
        address assetOut;
    }

    constructor(
        address codex,
        address moneta,
        address fiat,
        address publican
    ) Vault20Actions(codex, moneta, fiat, publican) {}

    /// ======== Position Management ======== ///

    /// @notice Buys fyTokens from underliers before it modifies a Position's collateral
    /// and debt balances and mints/burns FIAT using the underlier token.
    /// The underlier is swapped to fyTokens and used as collateral.
    /// fyTokens can only be bought up to the fyTokens maturity, once matured this method will revert.
    /// @dev The user needs to previously approve the UserProxy for spending underlier tokens,
    /// collateral tokens, or FIAT tokens. If `position` is not the UserProxy, the `position` owner
    /// needs grant a delegate to UserProxy via Codex.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param underlierAmount Amount of underlier to swap for fyToken to put up for collateral [underlierScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param swapParams Parameters of the underlier to fyToken swap
    function buyCollateralAndModifyDebt(
        address vault,
        address position,
        address collateralizer,
        address creditor,
        uint256 underlierAmount,
        int256 deltaNormalDebt,
        SwapParams calldata swapParams
    ) public {
        if (underlierAmount == 0 || underlierAmount >= type(uint128).max)
            revert VaultFYActions__buyCollateralAndModifyDebt_invalidUnderlierAmount();
        // buy fyToken according to `swapParams` data and transfer tokens to be used as collateral into VaultFY
        uint256 fyTokenAmount = _buyFYToken(underlierAmount, collateralizer, swapParams);
        int256 deltaCollateral = toInt256(wdiv(fyTokenAmount, IVault(vault).tokenScale()));

        // enter fyToken and collateralize position
        modifyCollateralAndDebt(
            vault,
            swapParams.assetOut,
            0,
            position,
            address(this),
            creditor,
            deltaCollateral,
            deltaNormalDebt
        );
    }

    /// @notice Sells fyTokens for underliers after it modifies a Position's collateral and debt balances
    /// and mints/burns FIAT using the underlier token.
    /// fyTokens can only be sold up to the fyTokens maturity, once matured this method will revert.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param fyTokenAmount Amount of fyToken to remove as collateral and to swap for underlier [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param swapParams Parameters of the underlier to fyToken swap
    function sellCollateralAndModifyDebt(
        address vault,
        address position,
        address collateralizer,
        address creditor,
        uint256 fyTokenAmount,
        int256 deltaNormalDebt,
        SwapParams calldata swapParams
    ) public {
        if (fyTokenAmount == 0 || fyTokenAmount >= type(uint128).max)
            revert VaultFYActions__sellCollateralAndModifyDebt_invalidFYTokenAmount();
        int256 deltaCollateral = -toInt256(wdiv(fyTokenAmount, IVault(vault).tokenScale()));

        // withdraw fyToken from the position
        modifyCollateralAndDebt(
            vault,
            swapParams.assetIn,
            0,
            position,
            address(this),
            creditor,
            deltaCollateral,
            deltaNormalDebt
        );

        // sell fyToken according to `swapParams`
        _sellFYToken(fyTokenAmount, collateralizer, swapParams);
    }

    /// @notice Redeems fyTokens for underliers after it modifies a Position's collateral
    /// and debt balances and mints/burns FIAT using the underlier token.
    /// fyTokens can only be redeemed once they have matured, before maturty this method will revert.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the collateral token (fyToken)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param fyTokenAmount Amount of fyToken to remove as collateral and to swap or redeem for underlier [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function redeemCollateralAndModifyDebt(
        address vault,
        address token,
        address position,
        address collateralizer,
        address creditor,
        uint256 fyTokenAmount,
        int256 deltaNormalDebt
    ) public {
        if (fyTokenAmount == 0 || fyTokenAmount >= type(uint128).max)
            revert VaultFYActions__redeemCollateralAndModifyDebt_invalidFYTokenAmount();

        int256 deltaCollateral = -toInt256(wdiv(fyTokenAmount, IVault(vault).tokenScale()));

        // withdraw fyToken from the position
        modifyCollateralAndDebt(vault, token, 0, position, address(this), creditor, deltaCollateral, deltaNormalDebt);

        // redeem fyToken for underlier
        IFYToken(token).redeem(collateralizer, fyTokenAmount);
    }

    function _buyFYToken(
        uint256 underlierAmount,
        address from,
        SwapParams calldata swapParams
    ) internal returns (uint256) {
        // if `from` is set to an external address then transfer directly to the Yield LP
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            IERC20(swapParams.assetIn).safeTransferFrom(from, swapParams.yieldSpacePool, underlierAmount);
        } else {
            IERC20(swapParams.assetIn).safeTransfer(swapParams.yieldSpacePool, underlierAmount);
        }

        // Sells underlier for fyToken. fyToken are transferred to the proxy to be entered into a vault
        return uint256(IFYPool(swapParams.yieldSpacePool).sellBase(address(this), _toUint128(swapParams.minAssetOut)));
    }

    function _sellFYToken(
        uint256 fyTokenAmount,
        address to,
        SwapParams calldata swapParams
    ) internal returns (uint256) {
        // Transfer from this contract to fypool
        IERC20(swapParams.assetIn).safeTransfer(swapParams.yieldSpacePool, fyTokenAmount);
        return uint256(IFYPool(swapParams.yieldSpacePool).sellFYToken(to, _toUint128(swapParams.minAssetOut)));
    }

    /// ======== View Methods ======== ///

    /// @notice Returns an amount of fyToken for a given an amount of the underlier token (e.g. USDC)
    /// @param underlierAmount Amount of underlier to be used to by fyToken [underlierToken]
    /// @param yieldSpacePool Address of the corresponding YieldSpace pool
    /// @return Amount of fyToken [tokenScale]
    function underlierToFYToken(uint256 underlierAmount, address yieldSpacePool) external view returns (uint256) {
        return uint256(IFYPool(yieldSpacePool).sellBasePreview(_toUint128(underlierAmount)));
    }

    /// @notice Returns an amount of underlier for a given an amount of the fyToken
    /// @param fyTokenAmount Amount of fyToken to be traded for underlier [tokenScale]
    /// @param yieldSpacePool Address of the corresponding YieldSpace pool
    /// @return Amount of underlier expected on trade [underlierScale]
    function fyTokenToUnderlier(uint256 fyTokenAmount, address yieldSpacePool) external view returns (uint256) {
        return uint256(IFYPool(yieldSpacePool).sellFYTokenPreview(_toUint128(fyTokenAmount)));
    }

    /// ======== Utils ======== ///

    /// @dev Casts from uint256 to uint128 (required by Yield Protocol)
    function _toUint128(uint256 x) private pure returns (uint128) {
        if (x >= type(uint128).max) revert VaultFYActions__toUint128_overflow();
        return uint128(x);
    }
}