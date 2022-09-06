// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";

import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {SupportsNonCompliantERC20} from "./SupportsNonCompliantERC20.sol";

library VaultLifecycleEarn {
    using SupportsNonCompliantERC20 for IERC20;

    /**
     * @param decimals is the decimals of the asset
     * @param totalBalance is the vaults total balance of the asset
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param lastQueuedWithdrawAmount is the total amount queued for withdrawals
     * @param performanceFee is the perf fee percent to charge on premiums
     * @param managementFee is the management fee percent to charge on the AUM
     * @param currentQueuedWithdrawShares is amount of queued withdrawals from the current round
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 currentQueuedWithdrawShares;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from RibbonVault
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return performanceFeeInAsset is the performance fee charged by vault
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function rollover(
        Vault.VaultState storage vaultState,
        RolloverParams calldata params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        uint256 pendingAmount = vaultState.totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;

        // Deduct older queued withdraws so we don't charge fees on them
        uint256 balanceForVaultFees =
            currentBalance - params.lastQueuedWithdrawAmount;

        {
            (performanceFeeInAsset, , totalVaultFee) = VaultLifecycleEarn
                .getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                params.performanceFee,
                params.managementFee
            );
        }

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance - totalVaultFee;

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply - lastQueuedWithdrawShares,
                currentBalance - params.lastQueuedWithdrawAmount,
                pendingAmount,
                params.decimals
            );

            queuedWithdrawAmount =
                params.lastQueuedWithdrawAmount +
                ShareMath.sharesToAsset(
                    params.currentQueuedWithdrawShares,
                    newPricePerShare,
                    params.decimals
                );

            // After closing the short, if the options expire in-the-money
            // vault pricePerShare would go down because vault's asset balance decreased.
            // This ensures that the newly-minted shares do not take on the loss.
            mintShares = ShareMath.assetToShares(
                pendingAmount,
                newPricePerShare,
                params.decimals
            );
        }

        return (
            currentBalance - queuedWithdrawAmount, // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            mintShares,
            performanceFeeInAsset,
            totalVaultFee
        );
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        pure
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending =
            currentBalance > pendingAmount ? currentBalance - pendingAmount : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee and management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // option expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? ((lockedBalanceSansPending - lastLockedAmount) *
                    performanceFeePercent) / (100 * Vault.FEE_MULTIPLIER)
                : 0;
            _managementFeeInAsset = managementFeePercent > 0
                ? (lockedBalanceSansPending * managementFeePercent) /
                    (100 * Vault.FEE_MULTIPLIER)
                : 0;

            _vaultFee = _performanceFeeInAsset + _managementFeeInAsset;
        }

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param feeRecipient is the address to recieve vault performance and management fees
     * @param optionSeller is the address of the entity that we will be buying options from (EX: Orbit)
     * @param performanceFee is the perfomance fee pct.
     * @param tokenName is the name of the token
     * @param tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     * @param _allocationState is the struct with vault loan/option allocation data
     */
    function verifyInitializerParams(
        address keeper,
        address feeRecipient,
        address optionSeller,
        uint256 performanceFee,
        uint256 managementFee,
        string calldata tokenName,
        string calldata tokenSymbol,
        Vault.VaultParams calldata _vaultParams,
        Vault.AllocationState calldata _allocationState,
        uint256 totalPCT
    ) external pure {
        require(keeper != address(0), "R7");
        require(feeRecipient != address(0), "R8");
        require(optionSeller != address(0), "R9");

        require(performanceFee < 100 * Vault.FEE_MULTIPLIER, "R12");
        require(managementFee < 100 * Vault.FEE_MULTIPLIER, "R11");
        require(bytes(tokenName).length > 0, "R41");
        require(bytes(tokenSymbol).length > 0, "R42");

        require(_vaultParams.asset != address(0), "R43");
        require(_vaultParams.minimumSupply > 0, "R44");
        require(_vaultParams.cap > 0, "R13");
        require(_vaultParams.cap > _vaultParams.minimumSupply, "R45");

        require(_allocationState.nextLoanTermLength == 0, "R46");
        require(_allocationState.nextOptionPurchaseFreq == 0, "R47");
        require(_allocationState.currentLoanTermLength >= 1 days, "R48");
        require(
            _allocationState.currentOptionPurchaseFreq > 0 &&
                _allocationState.currentOptionPurchaseFreq <=
                _allocationState.currentLoanTermLength,
            "R49"
        );
        require(
            uint256(_allocationState.loanAllocationPCT) +
                _allocationState.optionAllocationPCT <=
                totalPCT,
            "R50"
        );
        require(_allocationState.loanAllocation == 0, "R1");
        require(_allocationState.optionAllocation == 0, "R2");
    }
}