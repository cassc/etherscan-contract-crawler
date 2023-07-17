// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Calculations for when buyer initiates default
 * @author Alkimiya Team
 */
library PayoutMath {
    uint256 internal constant SCALING_FACTOR = 1e8;

    //Contract Constants
    uint128 internal constant FIXED_POINT_SCALE_VALUE = 10**14;
    uint128 internal constant FIXED_POINT_BASE = 10**6;
    uint32 internal constant HAIRCUT_BASE_PCT = 80;

    /**
     * @notice Returns haircut in fixed-point (base = 100000000 = 1).
     * @dev Granting 6 decimals precision. 1 - (0.8) * (day/contract)^3
     */
    function getHaircut(uint256 _numDepositsCompleted, uint256 _contractNumberOfDeposits) internal pure returns (uint256) {
        uint256 contractNumberOfDepositsCubed = uint256(_contractNumberOfDeposits)**3;
        uint256 multiplier = ((_numDepositsCompleted**3) * FIXED_POINT_SCALE_VALUE) / (contractNumberOfDepositsCubed);
        uint256 result = (HAIRCUT_BASE_PCT * multiplier) / (100 * FIXED_POINT_BASE);
        return (FIXED_POINT_BASE * 100) - result;
    }

    /**
     * @notice Calculates reward given to buyer when contract defaults.
     * @dev result = tokenBalance * (totalReward / hashrate)
     */
    function getRewardTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalRewardDelivered,
        uint256 _totalSilicaMinted
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalRewardDelivered) / _totalSilicaMinted;
    }

    /**
     * @notice  Calculates payment returned to buyer when contract defaults.
     * @dev result =  haircut * totalpayment tokenBalance / hashrateSold
     */
    function getPaymentTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalUpfrontPayment,
        uint256 _totalSilicaMinted,
        uint256 _haircut
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalUpfrontPayment * _haircut) / (_totalSilicaMinted * SCALING_FACTOR);
    }

    function getRewardPayoutToSellerOnDefault(uint256 _totalUpfrontPayment, uint256 _haircutPct) internal pure returns (uint256) {
        require(_haircutPct <= 100000000, "Scaled haircut PCT cannot be greater than 100000000");
        uint256 haircutPctRemainder = uint256(100000000) - _haircutPct;
        return (haircutPctRemainder * _totalUpfrontPayment) / 100000000;
    }

    function calculateReservedPrice(
        uint256 unitPrice,
        uint256 resourceAmount,
        uint256 numDeposits,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (unitPrice * resourceAmount * numDeposits) / (10**decimals);
    }

    function getBuyerRewardPayout(
        uint256 rewardDelivered,
        uint256 buyerBalance,
        uint256 resourceAmount
    ) internal pure returns (uint256) {
        return (rewardDelivered * buyerBalance) / resourceAmount;
    }
}