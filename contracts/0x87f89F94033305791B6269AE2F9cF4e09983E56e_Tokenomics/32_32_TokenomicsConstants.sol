// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@prb/math/src/UD60x18.sol";

/// @title TokenomicsConstants - Smart contract with tokenomics constants
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
abstract contract TokenomicsConstants {
    // Tokenomics version number
    string public constant VERSION = "1.0.0";
    // Tokenomics proxy address slot
    // keccak256("PROXY_TOKENOMICS") = "0xbd5523e7c3b6a94aa0e3b24d1120addc2f95c7029e097b466b2bedc8d4b4362f"
    bytes32 public constant PROXY_TOKENOMICS = 0xbd5523e7c3b6a94aa0e3b24d1120addc2f95c7029e097b466b2bedc8d4b4362f;
    // One year in seconds
    uint256 public constant ONE_YEAR = 1 days * 365;
    // Minimum epoch length
    uint256 public constant MIN_EPOCH_LENGTH = 1 weeks;
    // Minimum fixed point tokenomics parameters
    uint256 public constant MIN_PARAM_VALUE = 1e14;

    /// @dev Gets an inflation cap for a specific year.
    /// @param numYears Number of years passed from the launch date.
    /// @return supplyCap Supply cap.
    /// supplyCap = 1e27 * (1.02)^(x-9) for x >= 10
    /// if_succeeds {:msg "correct supplyCap"} (numYears >= 10) ==> (supplyCap > 1e27);  
    /// There is a bug in scribble tools, a broken instrumented version is as follows:
    /// function getSupplyCapForYear(uint256 numYears) public returns (uint256 supplyCap)
    /// And the test is waiting for a view / pure function, which would be correct
    function getSupplyCapForYear(uint256 numYears) public pure returns (uint256 supplyCap) {
        // For the first 10 years the supply caps are pre-defined
        if (numYears < 10) {
            uint96[10] memory supplyCaps = [
                529_659_000_00e16,
                569_913_084_00e16,
                641_152_219_50e16,
                708_500_141_72e16,
                771_039_876_00e16,
                828_233_282_97e16,
                879_860_040_11e16,
                925_948_139_65e16,
                966_706_331_40e16,
                1_000_000_000e18
            ];
            supplyCap = supplyCaps[numYears];
        } else {
            // Number of years after ten years have passed (including ongoing ones)
            numYears -= 9;
            // Max cap for the first 10 years
            supplyCap = 1_000_000_000e18;
            // After that the inflation is 2% per year as defined by the OLAS contract
            uint256 maxMintCapFraction = 2;

            // Get the supply cap until the current year
            for (uint256 i = 0; i < numYears; ++i) {
                supplyCap += (supplyCap * maxMintCapFraction) / 100;
            }
            // Return the difference between last two caps (inflation for the current year)
            return supplyCap;
        }
    }

    /// @dev Gets an inflation amount for a specific year.
    /// @param numYears Number of years passed from the launch date.
    /// @return inflationAmount Inflation limit amount.
    function getInflationForYear(uint256 numYears) public pure returns (uint256 inflationAmount) {
        // For the first 10 years the inflation caps are pre-defined as differences between next year cap and current year one
        if (numYears < 10) {
            // Initial OLAS allocation is 526_500_000_0e17
            uint88[10] memory inflationAmounts = [
                3_159_000_00e16,
                40_254_084_00e16,
                71_239_135_50e16,
                67_347_922_22e16,
                62_539_734_28e16,
                57_193_406_97e16,
                51_626_757_14e16,
                46_088_099_54e16,
                40_758_191_75e16,
                33_293_668_60e16
            ];
            inflationAmount = inflationAmounts[numYears];
        } else {
            // Number of years after ten years have passed (including ongoing ones)
            numYears -= 9;
            // Max cap for the first 10 years
            uint256 supplyCap = 1_000_000_000e18;
            // After that the inflation is 2% per year as defined by the OLAS contract
            uint256 maxMintCapFraction = 2;

            // Get the supply cap until the year before the current year
            for (uint256 i = 1; i < numYears; ++i) {
                supplyCap += (supplyCap * maxMintCapFraction) / 100;
            }

            // Inflation amount is the difference between last two caps (inflation for the current year)
            inflationAmount = (supplyCap * maxMintCapFraction) / 100;
        }
    }
}