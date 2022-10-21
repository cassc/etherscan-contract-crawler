// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import { TrancheData, TrancheDataHelpers, BondHelpers } from "./_utils/BondHelpers.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ITranche } from "./_interfaces/buttonwood/ITranche.sol";
import { IBondController } from "./_interfaces/buttonwood/IBondController.sol";
import { IPerpetualTranche } from "./_interfaces/IPerpetualTranche.sol";

/**
 *  @title RouterV1
 *
 *  @notice Contract to dry-run and batch multiple operations.
 *
 */
contract RouterV1 {
    // math
    using SafeCastUpgradeable for uint256;

    // data handling
    using BondHelpers for IBondController;
    using TrancheDataHelpers for TrancheData;

    // ERC20 operations
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for ITranche;
    using SafeERC20Upgradeable for IPerpetualTranche;

    modifier afterPerpStateUpdate(IPerpetualTranche perp) {
        perp.updateState();
        _;
    }

    /// @notice Calculates the amount of tranche tokens minted after depositing into the deposit bond.
    /// @dev Used by off-chain services to preview a tranche operation.
    /// @param perp Address of the perp contract.
    /// @param collateralAmount The amount of collateral the user wants to tranche.
    /// @return bond The address of the current deposit bond.
    /// @return trancheAmts The tranche token amounts minted.
    function previewTranche(IPerpetualTranche perp, uint256 collateralAmount)
        external
        afterPerpStateUpdate(perp)
        returns (
            IBondController,
            ITranche[] memory,
            uint256[] memory
        )
    {
        IBondController bond = perp.getDepositBond();

        TrancheData memory td;
        uint256[] memory trancheAmts;
        (td, trancheAmts, ) = bond.previewDeposit(collateralAmount);

        return (bond, td.tranches, trancheAmts);
    }

    /// @notice Calculates the amount of perp tokens minted and fees for the operation.
    /// @dev Used by off-chain services to preview a deposit operation.
    /// @param perp Address of the perp contract.
    /// @param trancheIn The address of the tranche token to be deposited.
    /// @param trancheInAmt The amount of tranche tokens deposited.
    /// @return mintAmt The amount of perp tokens minted.
    /// @return feeToken The address of the fee token.
    /// @return mintFee The fee charged for minting.
    function previewDeposit(
        IPerpetualTranche perp,
        ITranche trancheIn,
        uint256 trancheInAmt
    )
        external
        afterPerpStateUpdate(perp)
        returns (
            uint256,
            IERC20Upgradeable,
            int256
        )
    {
        uint256 mintAmt = perp.computeMintAmt(trancheIn, trancheInAmt);
        IERC20Upgradeable feeToken = perp.feeToken();
        (int256 reserveFee, uint256 protocolFee) = perp.feeStrategy().computeMintFees(mintAmt);
        int256 mintFee = reserveFee + protocolFee.toInt256();
        return (mintAmt, feeToken, mintFee);
    }

    /// @notice Tranches the collateral using the current deposit bond and then deposits individual tranches
    ///         to mint perp tokens. It transfers the perp tokens back to the
    ///         transaction sender along with any unused tranches and fees.
    /// @param perp Address of the perp contract.
    /// @param bond Address of the deposit bond.
    /// @param collateralAmount The amount of collateral the user wants to tranche.
    /// @param feePaid The fee paid to the perp contract to mint perp when the fee token is not the perp token itself, otherwise 0.
    /// @dev Fee to be paid should be pre-computed off-chain using the preview function.
    function trancheAndDeposit(
        IPerpetualTranche perp,
        IBondController bond,
        uint256 collateralAmount,
        uint256 feePaid
    ) external afterPerpStateUpdate(perp) {
        TrancheData memory td = bond.getTrancheData();
        IERC20Upgradeable collateralToken = IERC20Upgradeable(bond.collateralToken());
        IERC20Upgradeable feeToken = perp.feeToken();

        // transfers collateral & fees to router
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        if (feePaid > 0) {
            feeToken.safeTransferFrom(msg.sender, address(this), feePaid);
        }

        // approves collateral to be tranched
        _checkAndApproveMax(collateralToken, address(bond), collateralAmount);

        // tranches collateral
        bond.deposit(collateralAmount);

        // approves fee to be spent to mint perp tokens
        _checkAndApproveMax(feeToken, address(perp), feePaid);

        for (uint8 i = 0; i < td.trancheCount; i++) {
            uint256 trancheAmt = td.tranches[i].balanceOf(address(this));
            uint256 mintAmt = perp.computeMintAmt(td.tranches[i], trancheAmt);
            if (mintAmt > 0) {
                // approves tranches to be spent
                _checkAndApproveMax(td.tranches[i], address(perp), trancheAmt);

                // mints perp tokens using tranches
                perp.deposit(td.tranches[i], trancheAmt);
            } else {
                // transfers unused tranches back
                td.tranches[i].safeTransfer(msg.sender, trancheAmt);
            }
        }

        // transfers any remaining collateral tokens back
        uint256 collateralBalance = collateralToken.balanceOf(address(this));
        if (collateralBalance > 0) {
            collateralToken.safeTransfer(msg.sender, collateralBalance);
        }

        // transfers remaining fee back if overpaid or reward
        uint256 feeBalance = feeToken.balanceOf(address(this));
        if (feeBalance > 0) {
            feeToken.safeTransfer(msg.sender, feeBalance);
        }

        // transfers perp tokens back
        perp.safeTransfer(msg.sender, perp.balanceOf(address(this)));
    }

    /// @notice Calculates the reserve tokens that can be redeemed from the queue
    ///         for burning up to the requested amount of perp tokens.
    /// @dev Used by off-chain services to preview a redeem operation.
    /// @param perp Address of the perp contract.
    /// @param perpAmtBurnt The amount of perp tokens requested to be burnt.
    /// @return reserveTokens The list of reserve tokens redeemed.
    /// @return redemptionAmts The list of reserve token amounts redeemed.
    /// @return feeToken The address of the fee token.
    /// @return burnFee The fee charged for burning.
    function previewRedeem(IPerpetualTranche perp, uint256 perpAmtBurnt)
        external
        afterPerpStateUpdate(perp)
        returns (
            IERC20Upgradeable[] memory,
            uint256[] memory,
            IERC20Upgradeable,
            int256
        )
    {
        (IERC20Upgradeable[] memory reserveTokens, uint256[] memory redemptionAmts) = perp.computeRedemptionAmts(
            perpAmtBurnt
        );
        (int256 reserveFee, uint256 protocolFee) = perp.feeStrategy().computeBurnFees(perpAmtBurnt);
        int256 burnFee = reserveFee + protocolFee.toInt256();
        IERC20Upgradeable feeToken = perp.feeToken();
        return (reserveTokens, redemptionAmts, feeToken, burnFee);
    }

    /// @notice Calculates the amount tranche tokens that can be rolled out, remainders and fees,
    ///         with a given tranche token rolled in and amount.
    /// @dev Used by off-chain services to preview a rollover operation.
    /// @param perp Address of the perp contract.
    /// @param trancheIn The tranche token deposited.
    /// @param tokenOut The reserve token requested to be withdrawn.
    /// @param trancheInAmtRequested The amount of trancheIn tokens available to deposit.
    /// @param maxTokenOutAmtUsed The token balance to be used for rollover.
    /// @dev Set maxTokenOutAmtUsed to max(uint256) to use the entire balance.
    /// @return r The amounts rolled over and remaining.
    /// @return feeToken The address of the fee token.
    /// @return rolloverFee The fee paid by the caller.
    function previewRollover(
        IPerpetualTranche perp,
        ITranche trancheIn,
        IERC20Upgradeable tokenOut,
        uint256 trancheInAmtRequested,
        uint256 maxTokenOutAmtUsed
    )
        external
        afterPerpStateUpdate(perp)
        returns (
            IPerpetualTranche.RolloverPreview memory,
            IERC20Upgradeable,
            int256
        )
    {
        IPerpetualTranche.RolloverPreview memory r;
        r.remainingTrancheInAmt = trancheInAmtRequested;

        IERC20Upgradeable feeToken = perp.feeToken();
        int256 reserveFee = 0;
        uint256 protocolFee = 0;
        if (perp.isAcceptableRollover(trancheIn, tokenOut)) {
            r = perp.computeRolloverAmt(trancheIn, tokenOut, trancheInAmtRequested, maxTokenOutAmtUsed);
            (reserveFee, protocolFee) = perp.feeStrategy().computeRolloverFees(r.perpRolloverAmt);
        }
        int256 rolloverFee = reserveFee + protocolFee.toInt256();
        return (r, feeToken, rolloverFee);
    }

    struct RolloverBatch {
        ITranche trancheIn;
        IERC20Upgradeable tokenOut;
        uint256 trancheInAmt;
    }

    /// @notice Tranches collateral and performs a batch rollover.
    /// @param perp Address of the perp contract.
    /// @param bond Address of the deposit bond.
    /// @param collateralAmount The amount of collateral the user wants to tranche.
    /// @param rollovers List of batch rollover operations pre-computed off-chain.
    /// @param feePaid The fee paid by the user performing rollover (fee could be negative).
    function trancheAndRollover(
        IPerpetualTranche perp,
        IBondController bond,
        uint256 collateralAmount,
        RolloverBatch[] calldata rollovers,
        uint256 feePaid
    ) external afterPerpStateUpdate(perp) {
        TrancheData memory td = bond.getTrancheData();
        IERC20Upgradeable collateralToken = IERC20Upgradeable(bond.collateralToken());
        IERC20Upgradeable feeToken = perp.feeToken();

        // transfers collateral & fees to router
        collateralToken.safeTransferFrom(msg.sender, address(this), collateralAmount);
        if (feePaid > 0) {
            feeToken.safeTransferFrom(msg.sender, address(this), feePaid);
        }

        // approves collateral to be tranched
        _checkAndApproveMax(collateralToken, address(bond), collateralAmount);

        // tranches collateral
        bond.deposit(collateralAmount);

        // approves fee to be spent to rollover
        if (feePaid > 0) {
            _checkAndApproveMax(feeToken, address(perp), feePaid);
        }

        for (uint256 i = 0; i < rollovers.length; i++) {
            // approve trancheIn to be spent by perp
            _checkAndApproveMax(rollovers[i].trancheIn, address(perp), rollovers[i].trancheInAmt);

            // perform rollover
            perp.rollover(rollovers[i].trancheIn, rollovers[i].tokenOut, rollovers[i].trancheInAmt);
        }

        for (uint256 i = 0; i < rollovers.length; i++) {
            // transfer remaining tokenOut tokens back
            uint256 tokenOutBalance = rollovers[i].tokenOut.balanceOf(address(this));
            if (tokenOutBalance > 0) {
                rollovers[i].tokenOut.safeTransfer(msg.sender, tokenOutBalance);
            }
        }

        // transfers unused tranches back
        for (uint8 i = 0; i < td.trancheCount; i++) {
            uint256 trancheBalance = td.tranches[i].balanceOf(address(this));
            if (trancheBalance > 0) {
                td.tranches[i].safeTransfer(msg.sender, trancheBalance);
            }
        }

        // transfers any remaining collateral tokens back
        uint256 collateralBalance = collateralToken.balanceOf(address(this));
        if (collateralBalance > 0) {
            collateralToken.safeTransfer(msg.sender, collateralBalance);
        }

        // transfers remaining fee back if overpaid or reward
        uint256 feeBalance = feeToken.balanceOf(address(this));
        if (feeBalance > 0) {
            feeToken.safeTransfer(msg.sender, feeBalance);
        }
    }

    /// @dev Checks if the spender has sufficient allowance. If not, approves the maximum possible amount.
    function _checkAndApproveMax(
        IERC20Upgradeable token,
        address spender,
        uint256 amount
    ) private {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amount) {
            token.safeApprove(spender, type(uint256).max);
        }
    }
}