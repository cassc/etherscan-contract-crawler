// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "../../interfaces/ICodex.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IMoneta} from "../../interfaces/IMoneta.sol";
import {IFIAT} from "../../interfaces/IFIAT.sol";
import {WAD, toInt256, wmul, wdiv, sub} from "../../core/utils/Math.sol";

import {Vault20Actions} from "./Vault20Actions.sol";

interface IPeriphery {
    function swapUnderlyingForPTs(
        address adapter,
        uint256 maturity,
        uint256 uBal,
        uint256 minAccepted
    ) external returns (uint256 ptBal);

    function swapPTsForUnderlying(
        address adapter,
        uint256 maturity,
        uint256 ptBal,
        uint256 minAccepted
    ) external returns (uint256 uBal);

    function divider() external view returns (address divider);
}

interface IDivider {
    function redeem(
        address adapter,
        uint256 maturity,
        uint256 uBal
    ) external returns (uint256 tBal);
}

interface IAdapter {
    function unwrapTarget(uint256 amount) external returns (uint256);
}

interface ISenseSpace {
    function decimals() external view returns (uint256);

    struct SwapRequest {
        IBalancerVault.SwapKind kind;
        ERC20 tokenIn;
        ERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    function onSwap(
        SwapRequest memory swapRequest,
        uint256 currentBalanceTokenIn,
        uint256 currentBalanceTokenOut
    ) external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function pti() external view returns (uint256);
}

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            ERC20[] memory tokens,
            uint256[] memory balances,
            uint256 maxBlockNumber
        );
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Vault Sense Actions for principal token
/// @notice A set of vault actions for modifying positions collateralized by Sense Finance pTokens
contract VaultSPTActions is Vault20Actions {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error VaultSPTActions__buyCollateralAndModifyDebt_zeroUnderlierAmount();
    error VaultSPTActions__sellCollateralAndModifyDebt_zeroPTokenAmount();
    error VaultSPTActions__redeemCollateralAndModifyDebt_zeroPTokenAmount();

    /// ======== Storage ======== ///

    /// @notice Address of the Sense Finance Periphery
    IPeriphery public immutable periphery;
    /// @notice Address of the Sense Finance Divider
    IDivider public immutable divider;

    // Swap data
    struct SwapParams {
        // Sense Finance Adapter corresponding to the pToken
        address adapter;
        // Min amount of  [tokenScale for buying and selling]
        uint256 minAccepted;
        // Maturity of the pToken
        uint256 maturity;
        // Address of the asset to be swapped for `assetOut`, `underlierToken` for buying, `collateral` for selling
        address assetIn;
        // Address of the asset to receive in ex. for `assetOut`, `collateral` for buying, `underlierToken` for selling
        address assetOut;
        // Amount of `assetIn` to approve for the Sense Finance Periphery for swapping `assetIn` for `assetOut`
        uint256 approve;
    }

    struct RedeemParams {
        // Sense Finance Adapter corresponding to the pToken
        address adapter;
        // Maturity of the pToken
        uint256 maturity;
        // Address of the pToken's yield source
        address target;
        // Address of the pToken's underlier
        address underlierToken;
        // Amount of `target` token to approve for the Sense Finance Adapter for unwrapping them for `underlierToken`
        uint256 approveTarget;
    }

    constructor(
        address codex_,
        address moneta_,
        address fiat_,
        address publican_,
        address periphery_,
        address divider_
    ) Vault20Actions(codex_, moneta_, fiat_, publican_) {
        periphery = IPeriphery(periphery_);
        divider = IDivider(divider_);
    }

    /// ======== Position Management ======== ///

    /// @notice Buys pTokens from underliers before it modifies a Position's collateral
    /// and debt balances and mints/burns FIAT using the underlier token.
    /// The underlier is swapped to pTokens token used as collateral.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param underlierAmount Amount of underlier to swap for pTokens to put up for collateral [underlierScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param swapParams Parameters of the underlier to pToken swap
    function buyCollateralAndModifyDebt(
        address vault,
        address position,
        address collateralizer,
        address creditor,
        uint256 underlierAmount,
        int256 deltaNormalDebt,
        SwapParams calldata swapParams
    ) public {
        if (underlierAmount == 0) revert VaultSPTActions__buyCollateralAndModifyDebt_zeroUnderlierAmount();

        // buy pToken from underlier
        uint256 pTokenAmount = _buyPToken(underlierAmount, collateralizer, swapParams);
        int256 deltaCollateral = toInt256(wdiv(pTokenAmount, IVault(vault).tokenScale()));

        // enter pToken and collateralize position
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

    /// @notice Sells pTokens for underliers after it modifies a Position's collateral and debt balances
    /// and mints/burns FIAT using the underlier token. This method allows for selling pTokens even after maturity.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param pTokenAmount Amount of pToken to remove as collateral and to swap for underlier [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param swapParams Parameters of the underlier to pToken swap
    function sellCollateralAndModifyDebt(
        address vault,
        address position,
        address collateralizer,
        address creditor,
        uint256 pTokenAmount,
        int256 deltaNormalDebt,
        SwapParams calldata swapParams
    ) public {
        if (pTokenAmount == 0) revert VaultSPTActions__sellCollateralAndModifyDebt_zeroPTokenAmount();

        int256 deltaCollateral = -toInt256(wdiv(pTokenAmount, IVault(vault).tokenScale()));

        // withdraw pToken from the position
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

        // sell pToken according to `swapParams`
        uint256 underlier = _sellPToken(pTokenAmount, swapParams);

        // Send underlier to collateralizer
        IERC20(swapParams.assetOut).safeTransfer(collateralizer, underlier);
    }

    /// @notice Redeems pTokens for underliers after it modifies a Position's collateral
    /// and debt balances and mints/burns FIAT using the underlier token. Fails if pToken hasn't matured yet.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the collateral token (pToken)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param pTokenAmount Amount of pToken to remove as collateral and to swap or redeem for underlier [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function redeemCollateralAndModifyDebt(
        address vault,
        address token,
        address position,
        address collateralizer,
        address creditor,
        uint256 pTokenAmount,
        int256 deltaNormalDebt,
        RedeemParams calldata redeemParams
    ) public {
        if (pTokenAmount == 0) revert VaultSPTActions__redeemCollateralAndModifyDebt_zeroPTokenAmount();

        int256 deltaCollateral = -toInt256(wdiv(pTokenAmount, IVault(vault).tokenScale()));

        // withdraw pToken from the position
        modifyCollateralAndDebt(vault, token, 0, position, address(this), creditor, deltaCollateral, deltaNormalDebt);

        // redeem pTokens for `target` token
        uint256 targetAmount = divider.redeem(redeemParams.adapter, redeemParams.maturity, pTokenAmount);

        // approve the Sense Finance Adapter to transfer `target` tokens on behalf of the proxy
        if (redeemParams.approveTarget != 0) {
            IERC20(redeemParams.target).approve(redeemParams.adapter, targetAmount);
        }
        // unwrap `target` token for underlier
        uint256 underlierAmount = IAdapter(redeemParams.adapter).unwrapTarget(targetAmount);

        // send underlier to collateralizer
        IERC20(redeemParams.underlierToken).safeTransfer(collateralizer, underlierAmount);
    }

    function _buyPToken(
        uint256 underlierAmount,
        address from,
        SwapParams calldata swapParams
    ) internal returns (uint256) {
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            IERC20(swapParams.assetIn).safeTransferFrom(from, address(this), underlierAmount);
        }

        // approve Sense Finance Periphery to transfer underliers on behalf of proxy
        if (swapParams.approve != 0) {
            IERC20(swapParams.assetIn).approve(address(periphery), swapParams.approve);
        }

        return
            periphery.swapUnderlyingForPTs(
                swapParams.adapter,
                swapParams.maturity,
                underlierAmount,
                swapParams.minAccepted
            );
    }

    function _sellPToken(uint256 pTokenAmount, SwapParams calldata swapParams) internal returns (uint256) {
        // approve Sense Finance Periphery to transfer pTokens on behalf of the proxy
        if (swapParams.approve != 0) {
            IERC20(swapParams.assetIn).approve(address(periphery), swapParams.approve);
        }

        return
            periphery.swapPTsForUnderlying(
                swapParams.adapter,
                swapParams.maturity,
                pTokenAmount,
                swapParams.minAccepted
            );
    }

    /// ======== View Methods ======== ///

    /// @notice Returns an amount of pToken for a given an amount of the pTokens underlier token (e.g. USDC)
    /// @param senseSpace Address of the Sense Finance (pToken / target) Balancer V2 Pool
    /// @param balancerVault Address of the Balancer V2 vault
    /// @param underlierAmount Amount of underliers to swap for pTokens [underlierScale]
    /// @return Amount of pToken [tokenScale]
    function underlierToPToken(address senseSpace, address balancerVault, uint256 underlierAmount) external view returns (uint256) {
        ISenseSpace space = ISenseSpace(senseSpace);
        bytes32 poolId = space.getPoolId();
        (ERC20[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        uint256 pTokenIndex = space.pti();
        uint256 targetIndex = sub(1, pTokenIndex);
        ERC20 target = tokens[targetIndex];
        uint256 targetAmount = IERC4626(address(target)).previewDeposit(underlierAmount);
        return
            space.onSwap(
                ISenseSpace.SwapRequest(
                    IBalancerVault.SwapKind.GIVEN_IN,
                    target,
                    tokens[pTokenIndex],
                    targetAmount,
                    poolId,
                    0,
                    address(0),
                    address(0),
                    ""
                ),
                balances[targetIndex],
                balances[pTokenIndex]
            );
    }

    /// @notice Returns an amount of the pTokens underlier token for a given an amount of pToken (e.g. USDC pToken)
    /// @param senseSpace Address of the Sense Finance (pToken / target) Balancer V2 Pool
    /// @param balancerVault Address of the Balancer V2 vault
    /// @param pTokenAmount Amount of pToken to swap for underliers [tokenScale]
    /// @return Amount of underlier [underlierScale]
    function pTokenToUnderlier(address senseSpace, address balancerVault, uint256 pTokenAmount) external view returns (uint256) {
        ISenseSpace space = ISenseSpace(senseSpace);
        bytes32 poolId = space.getPoolId();
        (ERC20[] memory tokens, uint256[] memory balances, ) = IBalancerVault(balancerVault).getPoolTokens(poolId);
        uint256 pTokenIndex = space.pti();
        uint256 targetIndex = sub(1, pTokenIndex);
        ERC20 target = tokens[targetIndex];
        uint256 targetAmount = space.onSwap(
            ISenseSpace.SwapRequest(
                IBalancerVault.SwapKind.GIVEN_IN,
                tokens[pTokenIndex],
                target,
                pTokenAmount,
                poolId,
                0,
                address(0),
                address(0),
                ""
            ),
            balances[pTokenIndex],
            balances[targetIndex]
        );
        return IERC4626(address(target)).previewRedeem(targetAmount);
    }
}