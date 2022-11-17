// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC4626} from "openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICodex} from "fiat/interfaces/ICodex.sol";
import {IVault} from "fiat/interfaces/IVault.sol";
import {IMoneta} from "fiat/interfaces/IMoneta.sol";
import {IFIAT} from "fiat/interfaces/IFIAT.sol";
import {IFlash, ICreditFlashBorrower, IERC3156FlashBorrower} from "fiat/interfaces/IFlash.sol";
import {IPublican} from "fiat/interfaces/IPublican.sol";
import {WAD, toInt256, add, wmul, wdiv, sub} from "fiat/utils/Math.sol";

import {Lever20Actions} from "./Lever20Actions.sol";
import {IPeriphery, IDivider, IAdapter} from "../vault/VaultSPTActions.sol";

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

/// @title LeverSPTActions
/// @notice A set of vault actions for modifying positions collateralized by Sense Finance pTokens
contract LeverSPTActions is Lever20Actions, ICreditFlashBorrower, IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    /// @notice Address of the Sense Finance Periphery
    IPeriphery public immutable periphery;
    /// @notice Address of the Sense Finance Divider
    IDivider public immutable divider;

    /// ======== Custom Errors ======== ///

    error LeverSPTActions__onFlashLoan_unknownSender();
    error LeverSPTActions__onFlashLoan_unknownToken();
    error LeverSPTActions__onFlashLoan_nonZeroFee();
    error LeverSPTActions__onFlashLoan_unsupportedAction();
    error LeverSPTActions__onCreditFlashLoan_unknownSender();
    error LeverSPTActions__onCreditFlashLoan_nonZeroFee();
    error LeverSPTActions__onCreditFlashLoan_unsupportedAction();

    /// ======== Types ======== ///

    struct CollateralSwapParams {
        // Sense Finance Adapter corresponding to the pToken
        address adapter;
        // Min amount of  [tokenScale for buying and selling]
        uint256 minAccepted;
        // Maturity of the pToken
        uint256 maturity;
        // Address of the asset to be swapped for `assetOut`, `underlierToken` for buying, `collateral` for selling
        address assetIn;
        // Address of the asset to receive in ex. for `assetIn`, `collateral` for buying, `underlierToken` for selling
        address assetOut;
        // Amount of `assetIn` to approve for the Sense Finance Periphery for swapping `assetIn` for `assetOut`
        uint256 approve;
    }

    struct PTokenRedeemParams {
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
        // Amount of pTokens to withdraw and swap for underliers [tokenScale]
        uint256 subPTokenAmount;
        // Swap config for the underlier to FIAT swap
        BuyFIATSwapParams fiatSwapParams;
        // Swap config for the pToken to underlier swap
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
        // Amount of pTokens to withdraw and swap for underliers [tokenScale]
        uint256 subPTokenAmount;
        // Swap config for the underlier to FIAT swap
        BuyFIATSwapParams fiatSwapParams;
        // Config for the redemption of pToken for underlier
        PTokenRedeemParams redeemParams;
    }

    constructor(
        address codex,
        address fiat,
        address flash,
        address moneta,
        address publican,
        bytes32 fiatPoolId,
        address fiatBalancerVault,
        address periphery_,
        address divider_
    ) Lever20Actions(codex, fiat, flash, moneta, publican, fiatPoolId, fiatBalancerVault) {
        periphery = IPeriphery(periphery_);
        divider = IDivider(divider_);
    }

    /// ======== Position Management ======== ///

    /// @notice Increases the leverage factor of a position by flash minting `addDebt` amount of FIAT
    /// and selling it on top of the `underlierAmount` the `collateralizer` provided for more pTokens.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account who puts up the upfront amount of underliers
    /// @param upfrontUnderliers Amount of underliers the `collateralizer` puts up upfront [underlierScale]
    /// @param addDebt Amount of debt to generate in total [wad]
    /// @param fiatSwapParams Parameters of the flash lent FIAT to underlier swap
    /// @param collateralSwapParams Parameters of the underlier to pToken swap
    function buyCollateralAndIncreaseLever(
        address vault,
        address position,
        address collateralizer,
        uint256 upfrontUnderliers,
        uint256 addDebt,
        SellFIATSwapParams calldata fiatSwapParams,
        CollateralSwapParams calldata collateralSwapParams
    ) public {
        // if `collateralizer` is set to an external address then transfer the amount directly to Action contract
        // requires `collateralizer` to have set an allowance for the proxy
        if (collateralizer == address(this) || collateralizer == address(0)) {
            IERC20(collateralSwapParams.assetIn).safeTransfer(address(self), upfrontUnderliers);
        } else {
            IERC20(collateralSwapParams.assetIn).safeTransferFrom(collateralizer, address(self), upfrontUnderliers);
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
    /// @dev Executed in the context of LeverSPTActions instead of the Proxy
    function onFlashLoan(
        address, /* initiator */
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != address(flash)) revert LeverSPTActions__onFlashLoan_unknownSender();
        if (token != address(fiat)) revert LeverSPTActions__onFlashLoan_unknownToken();
        if (fee != 0) revert LeverSPTActions__onFlashLoan_nonZeroFee();

        FlashLoanData memory params = abi.decode(data, (FlashLoanData));
        if (params.action != 1) revert LeverSPTActions__onFlashLoan_unsupportedAction();
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
        uint256 pTokenSwapped = _buyPToken(underlierAmount, params.collateralSwapParams);
        uint256 addCollateral = wdiv(pTokenSwapped, IVault(params.vault).tokenScale());

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
    /// to decrease the outstanding debt (incl. interest), selling the withdrawn collateral (pToken) of the position
    /// for underliers and selling a portion of the underliers for FIAT to repay the flash lent amount.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account receives the excess collateral (pToken)
    /// @param subPTokenAmount Amount of pToken to withdraw from the position [tokenScale]
    /// @param subNormalDebt Amount of normalized debt of the position to reduce [wad]
    /// @param fiatSwapParams Parameters of the underlier to FIAT swap
    /// @param collateralSwapParams Parameters of the pToken to underlier swap
    function sellCollateralAndDecreaseLever(
        address vault,
        address position,
        address collateralizer,
        uint256 subPTokenAmount,
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
                        subPTokenAmount,
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
    /// to decrease the outstanding debt (incl. interest), redeeming the withdrawn collateral (pToken) of the position
    /// for underliers and selling a portion of the underliers for FIAT to repay the flash lent amount.
    /// @param vault Address of the Vault
    /// @param position Address of the position's owner
    /// @param collateralizer Address of the account receives the excess collateral (redeemed underliers)
    /// @param subPTokenAmount Amount of pToken to withdraw from the position [tokenScale]
    /// @param subNormalDebt Amount of normalized debt of the position to reduce [wad]
    /// @param fiatSwapParams Parameters of the underlier to FIAT swap
    /// @param redeemParams Parameters for redeeming pToken
    function redeemCollateralAndDecreaseLever(
        address vault,
        address token,
        address position,
        address collateralizer,
        uint256 subPTokenAmount,
        uint256 subNormalDebt,
        BuyFIATSwapParams calldata fiatSwapParams,
        PTokenRedeemParams calldata redeemParams
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
                        subPTokenAmount,
                        fiatSwapParams,
                        redeemParams
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
    /// @dev Executed in the context of LeverSPTActions instead of the Proxy
    function onCreditFlashLoan(
        address initiator,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        if (msg.sender != address(flash)) revert LeverSPTActions__onCreditFlashLoan_unknownSender();
        if (fee != 0) revert LeverSPTActions__onCreditFlashLoan_nonZeroFee();

        FlashLoanData memory params = abi.decode(data, (FlashLoanData));
        if (params.action == 2) _onSellCollateralAndDecreaseLever(initiator, amount, params.data);
        else if (params.action == 3) _onRedeemCollateralAndDecreaseLever(initiator, amount, params.data);
        else revert LeverSPTActions__onCreditFlashLoan_unsupportedAction();

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
            wdiv(params.subPTokenAmount, IVault(params.vault).tokenScale()),
            borrowed
        );

        // sell collateral for underlier
        uint256 underlierAmount = _sellPToken(params.subPTokenAmount, params.collateralSwapParams);

        // sell part of underlier for FIAT
        uint256 underlierSwapped = _buyFIATExactOut(params.fiatSwapParams, borrowed);

        // send underlier to collateralizer
        IERC20(params.collateralSwapParams.assetOut).safeTransfer(
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
            wdiv(params.subPTokenAmount, IVault(params.vault).tokenScale()),
            borrowed
        );

        // redeem pTokens for `target` token
        uint256 targetAmount = divider.redeem(
            params.redeemParams.adapter,
            params.redeemParams.maturity,
            params.subPTokenAmount
        );

        // approve the Sense Finance Adapter to transfer `target` tokens
        if (params.redeemParams.approveTarget != 0) {
            IERC20(params.redeemParams.target).approve(params.redeemParams.adapter, targetAmount);
        }
        // unwrap `target` token for underlier
        uint256 underlierAmount = IAdapter(params.redeemParams.adapter).unwrapTarget(targetAmount);

        // sell part of underlier for FIAT
        uint256 underlierSwapped = _buyFIATExactOut(params.fiatSwapParams, borrowed);

        // send underlier to collateralizer
        IERC20(params.fiatSwapParams.assetIn).safeTransfer(
            (params.collateralizer == address(0)) ? initiator : params.collateralizer,
            sub(underlierAmount, underlierSwapped)
        );
    }

    /// @dev Executed in the context of LeverEPTActions instead of the Proxy
    function _buyPToken(uint256 underlierAmount, CollateralSwapParams memory swapParams) internal returns (uint256) {
        if (IERC20(swapParams.assetIn).allowance(address(this), address(periphery)) < underlierAmount) {
            IERC20(swapParams.assetIn).approve(address(periphery), type(uint256).max);
        }

        return
            periphery.swapUnderlyingForPTs(
                swapParams.adapter,
                swapParams.maturity,
                underlierAmount,
                swapParams.minAccepted
            );
    }

    /// @dev Executed in the context of LeverEPTActions instead of the Proxy
    function _sellPToken(uint256 pTokenAmount, CollateralSwapParams memory swapParams) internal returns (uint256) {
        if (IERC20(swapParams.assetIn).allowance(address(this), address(periphery)) < pTokenAmount) {
            IERC20(swapParams.assetIn).approve(address(periphery), type(uint256).max);
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