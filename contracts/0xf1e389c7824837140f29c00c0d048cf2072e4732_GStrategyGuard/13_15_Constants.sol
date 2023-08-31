// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

contract Constants {
    uint8 public constant N_COINS = 3;
    uint256 public constant DEFAULT_DECIMALS = 10_000;
    uint256 public constant DECIMALS = 18;
    uint256 public constant DEFAULT_DECIMALS_FACTOR = uint256(10)**DECIMALS;
    uint8 public constant CHAINLINK_PRICE_DECIMALS = 8;
    uint256 public constant CHAINLINK_PRICE_DECIMAL_FACTOR =
        uint256(10)**CHAINLINK_PRICE_DECIMALS;
    uint8 public constant PERCENTAGE_DECIMALS = 4;
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR =
        uint256(10)**PERCENTAGE_DECIMALS;
    uint256 public constant CURVE_RATIO_DECIMALS = 6;
    uint256 public constant CURVE_RATIO_DECIMALS_FACTOR =
        uint256(10)**CURVE_RATIO_DECIMALS;

    uint8 public constant JUNIOR = 0;
    uint8 public constant SENIOR = 1;
    uint256 public constant BASE = 1e18;
    uint256 public constant INIT_BASE_JUNIOR = 5e15;
    uint256 public constant INIT_BASE_SENIOR = 10e18;
}