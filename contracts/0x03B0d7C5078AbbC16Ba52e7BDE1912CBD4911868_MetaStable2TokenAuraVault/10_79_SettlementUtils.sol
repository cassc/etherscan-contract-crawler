// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    RedeemParams, 
    TradeParams,
    StrategyContext,
    PoolContext,
    StrategyVaultSettings,
    StrategyVaultState
} from "../../BalancerVaultTypes.sol";
import {VaultState} from "../../../../global/Types.sol";
import {Errors} from "../../../../global/Errors.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {Constants} from "../../../../global/Constants.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {StrategyUtils} from "../strategy/StrategyUtils.sol";
import {BalancerVaultStorage} from "../BalancerVaultStorage.sol";

library SettlementUtils {
    using TypeConvert for uint256;
    using TypeConvert for int256;
    using StrategyUtils for StrategyContext;
    using BalancerVaultStorage for StrategyVaultSettings;

    /// @notice Validates that the slippage passed in by the caller
    /// does not exceed the designated threshold.
    /// @param slippageLimitPercent configured limit on the slippage from the oracle price allowed
    /// @param data trade parameters passed into settlement
    /// @return params abi decoded redemption parameters
    function _decodeParamsAndValidate(
        uint32 slippageLimitPercent,
        bytes memory data
    ) internal view returns (RedeemParams memory params) {
        params = abi.decode(data, (RedeemParams));
        TradeParams memory callbackData = abi.decode(
            params.secondaryTradeParams, (TradeParams)
        );

        if (callbackData.oracleSlippagePercentOrLimit > slippageLimitPercent) {
            revert Errors.SlippageTooHigh(callbackData.oracleSlippagePercentOrLimit, slippageLimitPercent);
        }
    }

    /// @notice Validates that the settlement is past a specified cool down period.
    /// @param lastSettlementTimestamp the last time the vault was settled
    /// @param coolDownInMinutes configured length of time required between settlements to ensure that
    /// slippage thresholds are respected (gives the market time to arbitrage back into position)
    function _validateCoolDown(uint32 lastSettlementTimestamp, uint32 coolDownInMinutes) internal view {
        // Convert coolDown to seconds
        if (lastSettlementTimestamp + (coolDownInMinutes * 60) > block.timestamp)
            revert Errors.InSettlementCoolDown(lastSettlementTimestamp, coolDownInMinutes);
    }

    /// @notice Calculates the amount of BPT availTable for emergency settlement
    function _getEmergencySettlementBPTAmount(
        uint256 bptTotalSupply,
        uint16 maxBalancerPoolShare,
        uint256 totalBPTHeld,
        uint256 bptHeldInMaturity
    ) private pure returns (uint256 bptToSettle) {
        // desiredPoolShare = maxPoolShare * bufferPercentage
        uint256 desiredPoolShare = (maxBalancerPoolShare *
            BalancerConstants.BALANCER_POOL_SHARE_BUFFER) /
            BalancerConstants.VAULT_PERCENT_BASIS;
        uint256 desiredBPTAmount = (bptTotalSupply * desiredPoolShare) /
            BalancerConstants.VAULT_PERCENT_BASIS;
        
        bptToSettle = totalBPTHeld - desiredBPTAmount;

        // Check to make sure we are not settling more than the amount of BPT
        // available in the current maturity
        // If more settlement is needed, call settleVaultEmergency
        // again with a different maturity
        if (bptToSettle > bptHeldInMaturity) {
            bptToSettle = bptHeldInMaturity;
        }
    }

    function _totalSupplyInMaturity(uint256 maturity) private view returns (uint256) {
        VaultState memory vaultState = Deployments.NOTIONAL.getVaultState(address(this), maturity);
        return vaultState.totalStrategyTokens;
    }

    function _getEmergencySettlementParams(
        StrategyContext memory strategyContext,
        uint256 maturity,
        uint256 totalBPTSupply
    )  internal view returns(uint256 bptToSettle) {
        StrategyVaultSettings memory settings = strategyContext.vaultSettings;
        StrategyVaultState memory state = strategyContext.vaultState;

        // Not in settlement window, check if BPT held is greater than maxBalancerPoolShare * total BPT supply
        uint256 emergencyBPTWithdrawThreshold = settings._bptThreshold(totalBPTSupply);

        if (strategyContext.vaultState.totalBPTHeld <= emergencyBPTWithdrawThreshold)
            revert Errors.InvalidEmergencySettlement();

        uint256 bptHeldInMaturity = _getBPTHeldInMaturity(
            state,
            _totalSupplyInMaturity(maturity),
            strategyContext.vaultState.totalBPTHeld
        );

        bptToSettle = _getEmergencySettlementBPTAmount({
            bptTotalSupply: totalBPTSupply,
            maxBalancerPoolShare: settings.maxBalancerPoolShare,
            totalBPTHeld: strategyContext.vaultState.totalBPTHeld,
            bptHeldInMaturity: bptHeldInMaturity
        });
    }

    function _executeSettlement(
        StrategyContext memory context,
        uint256 maturity,
        int256 expectedUnderlyingRedeemed,
        uint256 redeemStrategyTokenAmount,
        RedeemParams memory params
    ) internal {
        ( /* int256 assetCashRequiredToSettle */, int256 underlyingCashRequiredToSettle) 
            = Deployments.NOTIONAL.getCashRequiredToSettle(address(this), maturity);

        // A negative surplus here means the account is insolvent
        // (either expectedUnderlyingRedeemed is negative or
        // expectedUnderlyingRedeemed is less than underlyingCashRequiredToSettle).
        // If that's the case, we should just redeem and repay as much as possible (surplus
        // check is ignored because maxUnderlyingSurplus can never be negative).
        // If underlyingCashRequiredToSettle is negative, that means we already have surplus cash
        // on the Notional side, it will just make the surplus larger and potentially
        // cause it to go over maxUnderlyingSurplus.
        int256 surplus = expectedUnderlyingRedeemed -
            underlyingCashRequiredToSettle;

        // Make sure we not redeeming too much to underlying
        // This allows BPT to be accrued as the profit token.
        if (surplus > context.vaultSettings.maxUnderlyingSurplus.toInt()) {
            revert Errors.RedeemingTooMuch(
                expectedUnderlyingRedeemed,
                underlyingCashRequiredToSettle
            );
        }

        ( /* int256 assetCashSurplus */, int256 underlyingCashSurplus) 
            = Deployments.NOTIONAL.redeemStrategyTokensToCash(
                maturity, redeemStrategyTokenAmount, abi.encode(params)
            );

        if (underlyingCashSurplus <= 0 && maturity <= block.timestamp) {
            Deployments.NOTIONAL.settleVault(address(this), maturity);
        }
    }

    function _getBPTHeldInMaturity(
        StrategyVaultState memory strategyVaultState, 
        uint256 totalSupplyInMaturity,
        uint256 totalBPTHeld
    ) private pure returns (uint256 bptHeldInMaturity) {
        if (strategyVaultState.totalStrategyTokenGlobal == 0) return 0;
        bptHeldInMaturity =
            (totalBPTHeld * totalSupplyInMaturity) /
            strategyVaultState.totalStrategyTokenGlobal;
    }

}