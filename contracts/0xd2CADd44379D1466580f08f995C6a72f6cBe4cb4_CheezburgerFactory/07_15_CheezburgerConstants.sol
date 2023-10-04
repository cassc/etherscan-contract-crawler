// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

library CheezburgerConstants {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // The maximum amount of tokens that can be held on the pair is limited to the max uint112 value
    // uint112 ranges from 0 to 340,282,366,920,938,463,463,374,607,431,768,211,455
    uint256 private constant MAX_TOTAL_SUPPLY = type(uint112).max;
    // Dividing by 10**18 shifts the decimal place 18 spots to represent the value with 18 decimals
    // This allows the total supply to be represented as a common token amount in the external interface
    uint256 private constant MAX_TOKEN_SUPPLY = MAX_TOTAL_SUPPLY / (10 ** 18);
    // Calculate safety margin as 1% below max
    // SAFE_TOKEN_SUPPLY will be the enforced limit, providing a buffer
    // below the mathematical max to account for potential overflows
    uint256 internal constant SAFE_TOKEN_SUPPLY =
        MAX_TOKEN_SUPPLY - (MAX_TOKEN_SUPPLY / 100);
    uint8 internal constant MAX_LP_FEE = 4;
    uint256 internal constant FEE_DURATION_MIN = 1 hours;
    uint256 internal constant FEE_DURATION_CAP = 1 days;
    uint256 internal constant WALLET_DURATION_MIN = 1 days;
    uint256 internal constant WALLET_DURATION_CAP = 4 weeks;
    uint256 internal constant WALLET_MIN_PERCENT_END = 200;
    uint256 internal constant WALLET_MAX_PERCENT_END = 4900;
    uint256 internal constant MIN_NAME_LENGTH = 1;
    uint256 internal constant MAX_NAME_LENGTH = 128;
    uint256 internal constant MIN_SYMBOL_LENGTH = 1;
    uint256 internal constant MAX_SYMBOL_LENGTH = 128;
    uint256 internal constant MAX_URL_LENGTH = 256;
    uint256 internal constant FEE_START_MIN = 100;
    uint256 internal constant FEE_START_MAX = 4000;
    uint256 internal constant FEE_END_MAX = 500;
    uint8 internal constant THRESHOLD_MIN = 1;
    uint8 internal constant THRESHOLD_MAX = 5;
    uint256 internal constant FEE_ADDRESSES_MAX = 5;
    uint256 internal constant FEE_ADDRESSES_MIN = 1;
}