// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Deposit, FCNVaultMetadata, OptionBarrierType, OptionBarrier, VaultStatus, Withdrawal } from "./Structs.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { ICegaState } from "./interfaces/ICegaState.sol";

library Calculations {
    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant SECONDS_TO_DAYS = 86400;
    uint256 public constant BPS_DECIMALS = 10 ** 4;
    uint256 public constant LARGE_CONSTANT = 10 ** 18;
    uint256 public constant ORACLE_STALE_DELAY = 1 days;

    /**
     * @notice Calculates the current yield accumulated to the current day for a given vault
     */
    function calculateCurrentYield(FCNVaultMetadata storage self) public {
        require(self.vaultStatus == VaultStatus.Traded, "500:WS");
        uint256 currentTime = block.timestamp;

        if (currentTime > self.tradeExpiry) {
            self.vaultStatus = VaultStatus.TradeExpired;
            return;
        }

        uint256 numberOfDaysPassed = (currentTime - self.tradeDate) / SECONDS_TO_DAYS;

        self.totalCouponPayoff = calculateCouponPayment(self.underlyingAmount, self.aprBps, numberOfDaysPassed);
    }

    /**
     * @notice Permissionless method that reads price from oracle contracts and checks if barrier is triggered
     * @param cegaStateAddress is the address of the CegaState contract that stores the oracle addresses
     */
    function checkBarriers(FCNVaultMetadata storage self, address cegaStateAddress) public {
        if (self.isKnockedIn == true) {
            return;
        }

        require(self.vaultStatus == VaultStatus.Traded, "500:WS");

        for (uint256 i = 0; i < self.optionBarriersCount; i++) {
            OptionBarrier storage optionBarrier = self.optionBarriers[i];

            // Knock In: Check if current price is less than barrier
            if (optionBarrier.barrierType == OptionBarrierType.KnockIn) {
                address oracle = getOracleAddress(optionBarrier, cegaStateAddress);
                (, int256 answer, uint256 startedAt, , ) = IOracle(oracle).latestRoundData();
                require(block.timestamp - ORACLE_STALE_DELAY <= startedAt, "400:T");
                if (uint256(answer) <= optionBarrier.barrierAbsoluteValue) {
                    self.isKnockedIn = true;
                }
            }
        }
    }

    /**
     * @notice Calculates the final payoff for a given vault
     * @param self is the FCNVaultMetadata
     * @param cegaStateAddress is address of cegaState
     */
    function calculateVaultFinalPayoff(
        FCNVaultMetadata storage self,
        address cegaStateAddress
    ) public returns (uint256) {
        uint256 totalPrincipal;
        uint256 totalCouponPayment;
        uint256 principalToReturnBps = BPS_DECIMALS;

        require(
            (self.vaultStatus == VaultStatus.TradeExpired || self.vaultStatus == VaultStatus.PayoffCalculated),
            "500:WS"
        );

        // Calculate coupon payment
        totalCouponPayment = calculateCouponPayment(self.underlyingAmount, self.aprBps, self.tenorInDays);

        // Calculate principal
        if (self.isKnockedIn) {
            principalToReturnBps = calculateKnockInRatio(self, cegaStateAddress);
        }

        totalPrincipal = (self.underlyingAmount * principalToReturnBps) / BPS_DECIMALS;
        uint256 vaultFinalPayoff = totalPrincipal + totalCouponPayment;
        self.totalCouponPayoff = totalCouponPayment;
        self.vaultFinalPayoff = vaultFinalPayoff;
        self.vaultStatus = VaultStatus.PayoffCalculated;
        return vaultFinalPayoff;
    }

    /**
     * @notice Calculates the percentage of principal to return to users if a knock in occurs.
     * Iterates through all knock-in barriers and checks the ratio of (spot/strike) for each asset
     * Returns the minimum of the knock-in ratios.
     * @param self is the FCNVaultMetadata
     * @param cegaStateAddress is address of cegaState
     */
    function calculateKnockInRatio(
        FCNVaultMetadata storage self,
        address cegaStateAddress
    ) public view returns (uint256) {
        OptionBarrier[] memory optionBarriers = self.optionBarriers;
        uint256 optionBarriersCount = self.optionBarriersCount;

        uint256 minRatioBps = LARGE_CONSTANT;
        for (uint256 i = 0; i < optionBarriersCount; i++) {
            OptionBarrier memory optionBarrier = optionBarriers[i];
            address oracle = getOracleAddress(optionBarrier, cegaStateAddress);
            (, int256 answer, uint256 startedAt, , ) = IOracle(oracle).latestRoundData();
            require(block.timestamp - ORACLE_STALE_DELAY <= startedAt, "400:T");

            // Only calculate the ratio if it is a knock in barrier
            if (optionBarrier.barrierType == OptionBarrierType.KnockIn) {
                uint256 ratioBps = (uint256(answer) * LARGE_CONSTANT) / optionBarrier.strikeAbsoluteValue;
                minRatioBps = Math.min(ratioBps, minRatioBps);
            }
        }
        return ((minRatioBps * BPS_DECIMALS)) / LARGE_CONSTANT;
    }

    /**
     * @notice Calculates the fees that should be collected from a given vault
     * @param managementFeeBps is the management fee in bps
     * @param yieldFeeBps is the yield fee in bps
     */
    function calculateFees(
        FCNVaultMetadata storage self,
        uint256 managementFeeBps,
        uint256 yieldFeeBps
    ) public view returns (uint256, uint256, uint256) {
        uint256 totalFee = 0;
        uint256 managementFee = 0;
        uint256 yieldFee = 0;

        uint256 underlyingAmount = self.underlyingAmount;
        uint256 numberOfDaysPassed = (self.tradeExpiry - self.vaultStart) / SECONDS_TO_DAYS;

        managementFee =
            (underlyingAmount * numberOfDaysPassed * managementFeeBps * LARGE_CONSTANT) /
            DAYS_IN_YEAR /
            BPS_DECIMALS /
            LARGE_CONSTANT;

        if (self.vaultFinalPayoff > underlyingAmount) {
            uint256 profit = self.vaultFinalPayoff - underlyingAmount;
            yieldFee = (profit * yieldFeeBps) / BPS_DECIMALS;
        }

        totalFee = managementFee + yieldFee;
        return (totalFee, managementFee, yieldFee);
    }

    /**
     * @notice Calculates the coupon payment accumulated for a given number of daysPassed
     * @param underlyingAmount is the amount of assets
     * @param aprBps is the apr in bps
     * @param daysPassed is the number of days that coupon payments have been accured for
     */
    function calculateCouponPayment(
        uint256 underlyingAmount,
        uint256 aprBps,
        uint256 daysPassed
    ) private pure returns (uint256) {
        return (underlyingAmount * daysPassed * aprBps * LARGE_CONSTANT) / DAYS_IN_YEAR / BPS_DECIMALS / LARGE_CONSTANT;
    }

    /**
     * @notice Gets the oracle address for a given optionBarrier
     * @param optionBarrier is the option barrier
     * @param cegaStateAddress is the address of the Cega state contract
     */
    function getOracleAddress(
        OptionBarrier memory optionBarrier,
        address cegaStateAddress
    ) private view returns (address) {
        ICegaState cegaState = ICegaState(cegaStateAddress);
        address oracle = cegaState.oracleAddresses(optionBarrier.oracleName);
        require(oracle != address(0), "400:Unregistered");
        return oracle;
    }
}