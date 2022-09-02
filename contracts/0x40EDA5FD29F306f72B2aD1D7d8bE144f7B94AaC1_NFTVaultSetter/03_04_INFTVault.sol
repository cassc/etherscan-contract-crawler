// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface INFTVault {

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    struct VaultSettings {
        Rate debtInterestApr;
        Rate creditLimitRate;
        Rate liquidationLimitRate;
        Rate cigStakedCreditLimitRate;
        Rate cigStakedLiquidationLimitRate;
        Rate valueIncreaseLockRate;
        Rate organizationFeeRate;
        Rate insurancePurchaseRate;
        Rate insuranceLiquidationPenaltyRate;
        uint256 insuranceRepurchaseTimeLimit;
        uint256 borrowAmountCap;
    }

    function settings() external view returns (VaultSettings memory);

    function accrue() external;

    function setSettings(VaultSettings calldata _settings) external;

}