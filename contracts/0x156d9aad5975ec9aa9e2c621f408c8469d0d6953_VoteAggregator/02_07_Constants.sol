// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

contract Constants {
    uint8 internal constant N_COINS = 3;
    uint8 internal constant DEFAULT_DECIMALS = 18; // GToken and Controller use this decimals
    uint256 internal constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DEFAULT_DECIMALS;
    uint8 internal constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 internal constant CHAINLINK_PRICE_DECIMAL_FACTOR = uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 internal constant PERCENTAGE_DECIMALS = 4;
    uint256 internal constant PERCENTAGE_DECIMAL_FACTOR = uint256(10)**PERCENTAGE_DECIMALS;
    uint256 internal constant CURVE_RATIO_DECIMALS = 6;
    uint256 internal constant CURVE_RATIO_DECIMALS_FACTOR = uint256(10)**CURVE_RATIO_DECIMALS;
    uint256 internal constant ONE_YEAR_SECONDS = 31556952; // average year (including leap years) in seconds
}