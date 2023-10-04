// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

abstract contract CheezburgerStructs {
    /// @dev Settings for customizing the token
    /// @param name The name of the token
    /// @param symbol The symbol for the token
    /// @param website The website associated with the token
    /// @param social A social media link associated with the token
    /// @param supply The max supply of the token
    struct TokenCustomization {
        string name;
        string symbol;
        string website;
        string social;
        uint256 supply;
    }

    /// @dev Settings for dynamic fees that change over time
    /// @param duration The duration over which the rate changes
    /// @param percentStart The starting percentage rate
    /// @param percentEnd The ending percentage rate
    struct DynamicSettings {
        uint256 duration;
        uint16 percentStart;
        uint16 percentEnd;
    }

    /// @dev Settings for liquidity pool fees distributed to addresses
    /// @param feeThresholdPercent The percentage threshold that triggers liquidity swaps
    /// @param feeAddresses The addresses receiving distributed fee amounts
    /// @param feePercentages The percentage fee amounts for each address
    struct LiquiditySettings {
        uint8 feeThresholdPercent;
        address[] feeAddresses;
        uint8[] feePercentages;
    }

    /// @dev Settings for referrals. Referrals get commissions from fees whenever people uses the factory to deploy their token.
    /// @param feeReceiver The addresses receiving commissions
    /// @param feePercentage The percentage fee
    struct ReferralSettings {
        address feeReceiver;
        uint8 feePercentage;
    }
}