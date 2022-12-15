// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "../../interfaces/ICodex.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IMoneta} from "../../interfaces/IMoneta.sol";
import {IFIAT} from "../../interfaces/IFIAT.sol";
import {IFlash, ICreditFlashBorrower, IERC3156FlashBorrower} from "../../interfaces/IFlash.sol";
import {IPublican} from "../../interfaces/IPublican.sol";
import {WAD, toInt256, add, wmul, wdiv, sub} from "../../core/utils/Math.sol";
import {Lever20Actions} from "./Lever20Actions.sol";
import {IFYPool, IFYToken} from "../vault/VaultFYActions.sol";

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title LeverFYActions
/// @notice A set of vault actions for modifying positions collateralized by Yield fyTokens
contract LeverFYActions is Lever20Actions, ICreditFlashBorrower, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error LeverFYActions__onFlashLoan_unknownSender();
    error LeverFYActions__onFlashLoan_unknownToken();
    error LeverFYActions__onFlashLoan_nonZeroFee();
    error LeverFYActions__onFlashLoan_unsupportedAction();
    error LeverFYActions__onCreditFlashLoan_unknownSender();
    error LeverFYActions__onCreditFlashLoan_nonZeroFee();
    error LeverFYActions__onCreditFlashLoan_unsupportedAction();
    error LeverFYActions__solveTradeInvariant_tokenMismatch();
    error VaultFYActions__toUint128_overflow();

    /// ======== Types ======== ///

    struct CollateralSwapParams {
        // Min amount of asset out [tokenScale for buying, underlierScale for selling]
        uint256 minAssetOut;
        // Address of the Yield Space v2 pool
        address yieldSpacePool;
        // Address of the underlier (underlierToken) when buying, Address of the fyToken (token) when selling
        address assetIn;
        // Address of the fyToken (token) when buying, Address of underlier (underlierToken) when selling
        address assetOut;
    }

    struct BuyCollateralAndIncreaseLeverFlashLoanData {
        // Address of the collateral vault
        address vault;
        // Address of the collateral token
        address token;
        // Address of the owner of the position
        address position;
        // Amount of underliers the user provides (directly impacts the health factor) [underlierScale]
        uint256 upfrontUnderliers;
        // Swap config for the FIAT to underlier swap
        SellFIATSwapParams fiatSwapParams;
        // Swap config for the underlier to collateral token swap
        CollateralSwapParams collateralSwapParams;
    }

    struct SellCollateralAndDecreaseLeverFlashLoanData {
        // Address of the collateral vault
        address vault;
        // Address of the collateral token
        address token;
        // Address of the owner of the position
        address position;
        // Address of the account who receives the withdrawn / swapped underliers
        address collateralizer;
        // Amount of fyTokens to withdraw and swap for underliers [tokenScale]
        uint256 subFYTokenAmount;
        // Amount of normalized debt to pay back [wad]
        uint256 subNormalDebt;
        // Swap config for the underlier to FIAT swap
        BuyFIATSwapParams fiatSwapParams;
        // Swap config for the fyToken to underlier swap
        CollateralSwapParams collateralSwapParams;
    }

    struct RedeemCollateralAndDecreaseLeverFlashLoanData {
        // Address of the collateral vault
        address vault;
        // Address of the collateral token
        address token;
        // Address of the owner of the position
        address position;
        // Address of the account who receives the withdrawn / swapped underliers
        address collateralizer;
        // Amount of fyTokens to withdraw and swap for underliers [tokenScale]
        uint256 subFYTokenAmount;
        // Amount of normalized debt to pay back [wad]
        uint256 subNormalDebt;
        // Swap config for the underlier to FIAT swap
        BuyFIATSwapParams fiatSwapParams;
    }

    constructor(
        address codex,
        address fiat,
        address flash,
        address moneta,
        address publican,
        bytes32 fiatPoolId,
        address fiatBalancerVault
    ) Lever20Actions(codex, fiat, flash, moneta, publican, fiatPoolId, fiatBalancerVault) {}

    /// ======== Position Management ======== ///

    /// @notice Increases the leverage factor of a position by flash minting `addDebt` amount of FIAT
    /// and selling it on top of the `underlierAmount` the `collateralizer` provided for more fyTokens.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account who puts up the upfront amount of underliers
    /// @param upfrontUnderliers Amount of underliers the `collateralizer` puts up upfront [underlierScale]
    /// @param addDebt Amount of debt to generate in total [wad]
    /// @param fiatSwapParams Parameters of the flash lent FIAT to underlier swap
    /// @param collateralSwapParams Parameters of the underlier to fyToken swap
    function buyCollateralAndIncreaseLever(
        address vault,
        address position,
        address collateralizer,
        uint256 upfrontUnderliers,
        uint256 addDebt,
        SellFIATSwapParams calldata fiatSwapParams,
        CollateralSwapParams calldata collateralSwapParams
    ) public {
        if (upfrontUnderliers != 0) {
            // if `collateralizer` is set to an external address then transfer the amount directly to Action contract
            // requires `collateralizer` to have set an allowance for the proxy
            if (collateralizer == address(this) || collateralizer == address(0)) {
                IERC20(collateralSwapParams.assetIn).safeTransfer(address(self), upfrontUnderliers);
            } else {
                IERC20(collateralSwapParams.assetIn).safeTransferFrom(collateralizer, address(self), upfrontUnderliers);
            }
        }

        codex.grantDelegate(self);

        bytes memory data = abi.encode(
            FlashLoanData(
                1,
                abi.encode(
                    BuyCollateralAndIncreaseLeverFlashLoanData(
                        vault,
                        collateralSwapParams.assetOut,
                        position,
                        upfrontUnderliers,
                        fiatSwapParams,
                        collateralSwapParams
                    )
                )
            )
        );

        flash.flashLoan(IERC3156FlashBorrower(address(self)), address(fiat), addDebt, data);

        codex.revokeDelegate(self);
    }

    /// @notice `buyCollateralAndIncreaseLever` flash loan callback
    /// @dev Executed in the context of LeverFYActions instead of the Proxy
    function onFlashLoan(
        address, /* initiator */
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != address(flash)) revert LeverFYActions__onFlashLoan_unknownSender();
        if (token != address(fiat)) revert LeverFYActions__onFlashLoan_unknownToken();
        if (fee != 0) revert LeverFYActions__onFlashLoan_nonZeroFee();

        FlashLoanData memory params = abi.decode(data, (FlashLoanData));
        if (params.action != 1) revert LeverFYActions__onFlashLoan_unsupportedAction();
        _onBuyCollateralAndIncreaseLever(amount, params.data);

        // payback
        fiat.approve(address(flash), amount);

        return CALLBACK_SUCCESS;
    }

    function _onBuyCollateralAndIncreaseLever(uint256 borrowed, bytes memory data) internal {
        BuyCollateralAndIncreaseLeverFlashLoanData memory params = abi.decode(
            data,
            (BuyCollateralAndIncreaseLeverFlashLoanData)
        );

        // sell fiat for underlier
        uint256 underlierAmount = _sellFIATExactIn(params.fiatSwapParams, borrowed);

        // sum underlier from sender and underliers from fiat swap
        underlierAmount = add(underlierAmount, params.upfrontUnderliers);

        // sell underlier for collateral token
        uint256 fyTokenSwapped = _buyFYToken(underlierAmount, params.collateralSwapParams);
        uint256 addCollateral = wdiv(fyTokenSwapped, IVault(params.vault).tokenScale());

        // update position and mint fiat
        addCollateralAndDebt(
            params.vault,
            params.token,
            0,
            params.position,
            address(this),
            address(this),
            addCollateral,
            borrowed
        );
    }

    /// @notice Decreases the leverage factor of a position by flash lending `subNormalDebt * rate` amount of FIAT
    /// to decrease the outstanding debt (incl. interest), selling the withdrawn collateral (fyToken) of the position
    /// for underliers and selling a portion of the underliers for FIAT to repay the flash lent amount.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account receives the excess collateral (fyToken)
    /// @param subFYTokenAmount Amount of fyToken to withdraw from the position [tokenScale]
    /// @param subNormalDebt Amount of normalized debt of the position to reduce [wad]
    /// @param fiatSwapParams Parameters of the underlier to FIAT swap
    /// @param collateralSwapParams Parameters of the fyToken to underlier swap
    function sellCollateralAndDecreaseLever(
        address vault,
        address position,
        address collateralizer,
        uint256 subFYTokenAmount,
        uint256 subNormalDebt,
        BuyFIATSwapParams calldata fiatSwapParams,
        CollateralSwapParams calldata collateralSwapParams
    ) public {
        codex.grantDelegate(self);

        bytes memory data = abi.encode(
            FlashLoanData(
                2,
                abi.encode(
                    SellCollateralAndDecreaseLeverFlashLoanData(
                        vault,
                        collateralSwapParams.assetIn,
                        position,
                        collateralizer,
                        subFYTokenAmount,
                        subNormalDebt,
                        fiatSwapParams,
                        collateralSwapParams
                    )
                )
            )
        );

        // update the interest rate accumulator in Codex for the vault
        if (subNormalDebt != 0) publican.collect(vault);
        // add due interest from normal debt
        (, uint256 rate, , ) = codex.vaults(vault);
        flash.creditFlashLoan(ICreditFlashBorrower(address(self)), wmul(rate, subNormalDebt), data);

        codex.revokeDelegate(self);
    }

    /// @notice Decreases the leverage factor of a position by flash lending `subNormalDebt * rate` amount of FIAT
    /// to decrease the outstanding debt (incl. interest), redeeming the withdrawn collateral (fyToken) of the position
    /// for underliers and selling a portion of the underliers for FIAT to repay the flash lent amount.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account receives the excess collateral (redeemed underliers)
    /// @param subFYTokenAmount Amount of fyToken to withdraw from the position [tokenScale]
    /// @param subNormalDebt Amount of normalized debt of the position to reduce [wad]
    /// @param fiatSwapParams Parameters of the underlier to FIAT swap
    function redeemCollateralAndDecreaseLever(
        address vault,
        address token,
        address position,
        address collateralizer,
        uint256 subFYTokenAmount,
        uint256 subNormalDebt,
        BuyFIATSwapParams calldata fiatSwapParams
    ) public {
        codex.grantDelegate(self);

        bytes memory data = abi.encode(
            FlashLoanData(
                3,
                abi.encode(
                    RedeemCollateralAndDecreaseLeverFlashLoanData(
                        vault,
                        token,
                        position,
                        collateralizer,
                        subFYTokenAmount,
                        subNormalDebt,
                        fiatSwapParams
                    )
                )
            )
        );

        // update the interest rate accumulator in Codex for the vault
        if (subNormalDebt != 0) publican.collect(vault);
        // add due interest from normal debt
        (, uint256 rate, , ) = codex.vaults(vault);
        flash.creditFlashLoan(ICreditFlashBorrower(address(self)), wmul(rate, subNormalDebt), data);

        codex.revokeDelegate(self);
    }

    /// @notice `sellCollateralAndDecreaseLever` and `redeemCollateralAndDecreaseLever` flash loan callback
    /// @dev Executed in the context of LeverFYActions instead of the Proxy
    function onCreditFlashLoan(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != address(flash)) revert LeverFYActions__onCreditFlashLoan_unknownSender();
        if (fee != 0) revert LeverFYActions__onCreditFlashLoan_nonZeroFee();

        FlashLoanData memory params = abi.decode(data, (FlashLoanData));
        if (params.action == 2) _onSellCollateralAndDecreaseLever(initiator, amount, params.data);
        else if (params.action == 3) _onRedeemCollateralAndDecreaseLever(initiator, amount, params.data);
        else revert LeverFYActions__onCreditFlashLoan_unsupportedAction();

        // payback
        fiat.approve(address(moneta), amount);
        moneta.enter(address(this), amount);
        codex.transferCredit(address(this), address(flash), amount);

        return CALLBACK_SUCCESS_CREDIT;
    }

    function _onSellCollateralAndDecreaseLever(
        address initiator,
        uint256 borrowed,
        bytes memory data
    ) internal {
        SellCollateralAndDecreaseLeverFlashLoanData memory params = abi.decode(
            data,
            (SellCollateralAndDecreaseLeverFlashLoanData)
        );

        // pay back debt of position
        subCollateralAndDebt(
            params.vault,
            params.token,
            0,
            params.position,
            address(this),
            wdiv(params.subFYTokenAmount, IVault(params.vault).tokenScale()),
            params.subNormalDebt
        );

        // sell collateral for underlier
        uint256 underlierAmount = _sellFYToken(params.subFYTokenAmount, params.collateralSwapParams);

        // sell part of underlier for FIAT
        uint256 underlierSwapped = _buyFIATExactOut(params.fiatSwapParams, borrowed);

        // send underlier to collateralizer
        IERC20(address(params.fiatSwapParams.assets[0])).safeTransfer(
            (params.collateralizer == address(0)) ? initiator : params.collateralizer,
            sub(underlierAmount, underlierSwapped)
        );
    }

    function _onRedeemCollateralAndDecreaseLever(
        address initiator,
        uint256 borrowed,
        bytes memory data
    ) internal {
        RedeemCollateralAndDecreaseLeverFlashLoanData memory params = abi.decode(
            data,
            (RedeemCollateralAndDecreaseLeverFlashLoanData)
        );

        // pay back debt of position
        subCollateralAndDebt(
            params.vault,
            params.token,
            0,
            params.position,
            address(this),
            wdiv(params.subFYTokenAmount, IVault(params.vault).tokenScale()),
            params.subNormalDebt
        );

        // redeem fyToken for underlier
        uint256 underlierAmount = IFYToken(params.token).redeem(address(this), params.subFYTokenAmount);

        // sell part of underlier for FIAT
        uint256 underlierSwapped = _buyFIATExactOut(params.fiatSwapParams, borrowed);

        // send underlier to collateralizer
        IERC20(address(params.fiatSwapParams.assets[0])).safeTransfer(
            (params.collateralizer == address(0)) ? initiator : params.collateralizer,
            sub(underlierAmount, underlierSwapped)
        );
    }

    function _buyFYToken(
        uint256 underlierAmount,
        CollateralSwapParams memory swapParams
    ) internal returns (uint256) {
        // Sells underlier for fyToken
        IERC20(swapParams.assetIn).safeTransfer(swapParams.yieldSpacePool, underlierAmount);
        return uint256(IFYPool(swapParams.yieldSpacePool).sellBase(address(this), _toUint128(swapParams.minAssetOut)));
    }

       function _sellFYToken(
        uint256 fyTokenAmount,
        CollateralSwapParams memory swapParams
    ) internal returns (uint256) {
        // Sele fyToken for underlier
        IERC20(swapParams.assetIn).safeTransfer(swapParams.yieldSpacePool, fyTokenAmount);
        return uint256(IFYPool(swapParams.yieldSpacePool).sellFYToken(address(this), _toUint128(swapParams.minAssetOut)));
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