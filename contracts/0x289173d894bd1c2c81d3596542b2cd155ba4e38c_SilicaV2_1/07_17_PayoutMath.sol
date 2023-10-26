/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
 * */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title  Payout Math Library
 * @author Alkimiya Team
 * @notice Calculations for when buyer initiates default
 */
library PayoutMath {

    /*///////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant SCALING_FACTOR = 1e8;
    uint128 internal constant FIXED_POINT_SCALE_VALUE = 10**14;
    uint128 internal constant FIXED_POINT_BASE = 10**6;
    uint32 internal constant HAIRCUT_BASE_PCT = 80;

    /*///////////////////////////////////////////////////////////////
                                Functionality
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns haircut in fixed-point (base = 100000000 = 1).
     * @dev Granting 6 decimals precision. 1 - (0.8) * (day/contract)^3
     * @param _numDepositsCompleted The number of days on which deposits have been successfully completed
     * @param _contractNumberOfDeposits The number of days on which deposits are to be completed in total in the contract
     * @return uint256: Haircut
     */
    function _getHaircut(uint256 _numDepositsCompleted, uint256 _contractNumberOfDeposits) internal pure returns (uint256) {
        uint256 contractNumberOfDepositsCubed = uint256(_contractNumberOfDeposits)**3;
        uint256 multiplier = ((_numDepositsCompleted**3) * FIXED_POINT_SCALE_VALUE) / (contractNumberOfDepositsCubed);
        uint256 result = (HAIRCUT_BASE_PCT * multiplier) / (100 * FIXED_POINT_BASE);
        return (FIXED_POINT_BASE * 100) - result;
    }

    /**
     * @notice Calculates reward given to buyer when contract defaults.
     * @dev result = tokenBalance * (totalReward / hashrate)
     * @param _buyerTokenBalance The Silica balance of the buyer
     * @param _totalRewardDelivered The balance of reward tokens delivered by the seller
     * @param _totalSilicaMinted The total amount of Silica that have been minted
     * @return uint256: The number of reward tokens to be transferred to the buyer on event of contract default
     */
    function _getRewardTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalRewardDelivered,
        uint256 _totalSilicaMinted
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalRewardDelivered) / _totalSilicaMinted;
    }

    /**
     * @notice Calculates payment returned to buyer when contract defaults.
     * @dev result =  haircut * totalpayment tokenBalance / hashrateSold
     * @param _buyerTokenBalance The Silica balance of the buyer
     * @param _totalUpfrontPayment The amount of payment tokens made at contract start
     * @param _totalSilicaMinted The total amount of Silica that have been minted
     * @param _haircut  The haircut, see _getHaircut()
     * @return uint256: The amount of payment tokens to be sent to buyer in the event of a contract default
     */
    function _getPaymentTokenPayoutToBuyerOnDefault(
        uint256 _buyerTokenBalance,
        uint256 _totalUpfrontPayment,
        uint256 _totalSilicaMinted,
        uint256 _haircut
    ) internal pure returns (uint256) {
        return (_buyerTokenBalance * _totalUpfrontPayment * _haircut) / (_totalSilicaMinted * SCALING_FACTOR);
    }

    /// @notice Calculates reward given to seller when contract defaults.
    /// @param _totalUpfrontPayment The amount of payment tokens made at contract start
    /// @param _haircutPct The scaled haircut percent
    /// @return uint256: Reward token amount to be sent to seller in event of contraact default
    function _getRewardPayoutToSellerOnDefault(uint256 _totalUpfrontPayment, uint256 _haircutPct) internal pure returns (uint256) {
        require(_haircutPct <= 100000000, "Scaled haircut PCT cannot be greater than 100000000");
        uint256 haircutPctRemainder = uint256(100000000) - _haircutPct;
        return (haircutPctRemainder * _totalUpfrontPayment) / 100000000;
    }

    /// @notice Calculaed the Reserved Price for a contract
    /// @param  unitPrice The price per unit
    /// @param  resourceAmount The amount of underlying resource
    /// @param  numDeposits The number of deposits required in the contract
    /// @param  decimals The number of decimals of the Silica
    function _calculateReservedPrice(
        uint256 unitPrice,
        uint256 resourceAmount,
        uint256 numDeposits,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (unitPrice * resourceAmount * numDeposits) / (10**decimals);
    }

    /// @notice Calculated the amount of reward tokens to be sent to the buyer
    /// @param  rewardDelivered The amount of reward tokens deposited
    /// @param  buyerBalance The Silica balance of the buyer address
    /// @param  resourceAmount The amount of underlying resource
    /// @return uint256: The amount of reward tokens to be paid to the buyer
    function _getBuyerRewardPayout(
        uint256 rewardDelivered,
        uint256 buyerBalance,
        uint256 resourceAmount
    ) internal pure returns (uint256) {
        return (rewardDelivered * buyerBalance) / resourceAmount;
    }
}