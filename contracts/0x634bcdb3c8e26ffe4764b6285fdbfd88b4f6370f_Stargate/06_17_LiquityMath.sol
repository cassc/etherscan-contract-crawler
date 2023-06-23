// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./BaseMath.sol";

/// @title Business calculation logic related to the Liquity protocol
/// @dev To be inherited only
contract LiquityMath is BaseMath {

    // Maximum protocol fee as defined in the Liquity contracts
    // https://github.com/liquity/dev/blob/cb583ddf5e7de6010e196cfe706bd0ca816ea40e/packages/contracts/contracts/TroveManager.sol#L48
    uint256 internal constant LIQUITY_PROTOCOL_MAX_BORROWING_FEE = DECIMAL_PRECISION / 100 * 5; // 5%

    // Amount of LUSD to be locked in Liquity's gas pool on opening troves
    // https://github.com/liquity/dev/blob/cb583ddf5e7de6010e196cfe706bd0ca816ea40e/packages/contracts/contracts/TroveManager.sol#L334
    uint256 internal constant LIQUITY_LUSD_GAS_COMPENSATION = 200e18;

	/// @notice Calculates the needed amount of LUSD parameter for Liquity protocol when borrowing LUSD
    /// @param _LUSDRequestedAmount Amount the user wants to withdraw
    /// @param _expectedLiquityProtocolRate Current / expected borrowing rate of the Liquity protocol
    /// @param _adoptionContributionRate Adoption Contribution Rate in uint16 form (xxyy defines xx.yy %). LPR is applied when ACR < LPR. Thus LPR is always used When AR is set to 0.
    /* solhint-disable-next-line var-name-mixedcase */
    function calcNeededLiquityLUSDAmount(uint256 _LUSDRequestedAmount, uint256 _expectedLiquityProtocolRate, uint16 _adoptionContributionRate) internal pure returns (
        uint256 neededLiquityLUSDAmount
    ) {

        // Normalise ACR 1e4 -> 1e18
        uint256 acr = DECIMAL_PRECISION / ACR_DECIMAL_PRECISION * _adoptionContributionRate;

        // Apply Liquity protocol rate when ACR is lower
        acr = acr < _expectedLiquityProtocolRate ? _expectedLiquityProtocolRate : acr;

        // Includes requested debt and adoption contribution which covers also liquity protocol fee
        uint256 expectedDebtToRepay = _LUSDRequestedAmount * acr / DECIMAL_PRECISION + _LUSDRequestedAmount;

        // = x / ( 1 + fee rate<0.005 - 0.05> )
        neededLiquityLUSDAmount = DECIMAL_PRECISION * expectedDebtToRepay / ( DECIMAL_PRECISION + _expectedLiquityProtocolRate ); 

        require(neededLiquityLUSDAmount >= _LUSDRequestedAmount, "Cannot mint less than requested.");
    }

    /// @notice Calculates adjusted Adoption Contribution Rate decreased by RCCAR down to min 0.
    /// @param _rccar Recognised Community Contributor Acknowledgement Rate in uint16 form (xxyy defines xx.yy % points).
    /// @param _adoptionContributionRate Adoption Contribution Rate in uint16 form (xxyy defines xx.yy %).
    function applyRccarOnAcr(uint16 _rccar, uint16 _adoptionContributionRate) internal pure returns (
        uint16 adjustedAcr
    ) {
        return (_adoptionContributionRate > _rccar ? _adoptionContributionRate - _rccar : 0);
    }
}