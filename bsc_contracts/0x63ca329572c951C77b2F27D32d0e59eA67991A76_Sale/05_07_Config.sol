// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Constant {
    uint256 internal constant ONE_DAY = 86400;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 internal constant FIXED_POINT = 1e18;
    uint256 internal constant MAX_TOKEN_TOTAL_SUPPLY = 1e25; // 10 milion tokens

    /// Rates for different phases of the sale.
    uint256 public constant PRIVATE_SALE_RATE = 1000000000000000000;  /// 1 token = 1 USDT

    /// Withdrawable rate
    uint256 public constant WITHDRAWABLE_RATE = 500000000000000000;  /// 0.5

    uint256 public constant SALE_MAX_AMOUNT         = 1000 * FIXED_POINT; /// max user can buy

    uint256 public constant SALE_MINT_TOKEN_AMOUNT = 170000 * FIXED_POINT; // 0.34% supply = 170.000 tokens

    uint256 public constant ECOSYSTEM_MINT_TOKEN_AMOUNT = 7330000 * FIXED_POINT; // 14.66% supply = 7.330.000 tokens

    uint256 public constant TEAM_MINT_TOKEN_AMOUNT = 7500000 * FIXED_POINT; // 15% supply = 7.500.000 tokens

    uint256 public constant TREASURY_MINT_TOKEN_AMOUNT = 15000000 * FIXED_POINT; // 30% supply = 15.000.000 tokens

    uint256 public constant LIQUIDITY_MINT_TOKEN_AMOUNT = 20000000 * FIXED_POINT; // 40% supply = 20.000.000 tokens
}